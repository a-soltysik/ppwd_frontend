package com.example.board_plugin.connection;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import com.example.board_plugin.NotificationHelper;
import com.example.board_plugin.ResourceHelper;
import com.example.board_plugin.setup.SensorSetupManager;
import com.mbientlab.metawear.android.BtleService;
import com.mbientlab.metawear.module.Settings;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

public class BluetoothConnectionManager implements ServiceConnection {
    private static final String TAG = "BluetoothManager";
    private static final int MAX_CONNECTION_RETRIES = 3;
    private static final long CONNECTION_RETRY_DELAY_MS = 1500;

    private final Context context;
    private final Handler mainHandler;
    private final AtomicBoolean isConnecting = new AtomicBoolean(false);
    private final SensorSetupManager setupManager;

    private BtleService.LocalBinder serviceBinder;
    private String macAddress = "";
    private boolean isConnected = false;
    private int connectionRetries = 0;
    private boolean isServiceBound = false;
    private ConnectionCallback connectionCallback;

    private boolean isShutdownRequested = false;


    public BluetoothConnectionManager(Context context, SensorSetupManager setupManager) {
        this.context = context.getApplicationContext();
        this.setupManager = setupManager;
        this.mainHandler = new Handler(Looper.getMainLooper());
    }

    public void setConnectionCallback(ConnectionCallback callback) {
        this.connectionCallback = callback;
    }

    public boolean isConnected() {
        return isConnected;
    }

    public boolean isConnecting() {
        return isConnecting.get();
    }

    public void connectToDevice(String macAddress) {
        Log.i(TAG, "Connect to device called for: " + macAddress);
        isShutdownRequested = false;

        if (isConnecting.get()) {
            Log.e(TAG, "Already attempting to connect to a device");
            if (connectionCallback != null) {
                connectionCallback.onDisconnection("Already attempting to connect to a device");
            }
            return;
        }

        if (isConnected || isServiceBound) {
            Log.i(TAG, "Disconnecting from previous connection before reconnecting");
            disconnectFromBoard();

            mainHandler.postDelayed(() -> {
                startNewConnection(macAddress);
            }, 500);
        } else {
            startNewConnection(macAddress);
        }
    }

    private void startNewConnection(String macAddress) {
        this.macAddress = macAddress;
        connectionRetries = 0;
        setupManager.clear();
        isConnecting.set(true);

        Log.i(TAG, "Starting new connection to: " + macAddress);
        connectToService();
    }

    public void connectToService() {
        try {
            Log.i(TAG, "Binding to BtleService");
            isServiceBound = context.bindService(
                    new Intent(context, BtleService.class),
                    this,
                    Context.BIND_AUTO_CREATE
            );

            if (!isServiceBound) {
                handleError("Failed to connect to Bluetooth service");
            }
        } catch (Exception e) {
            handleError("Service connection error: " + e.getMessage());
        }
    }

    private void handleError(String message) {
        Log.e(TAG, message);
        isConnecting.set(false);
        if (connectionCallback != null) {
            connectionCallback.onDisconnection(message);
        }
    }

    private void reset() {
        isConnected = false;
        isConnecting.set(false);
        setupManager.clear();
    }

    public void disconnectFromBoard() {
        Log.i(TAG, "Disconnecting from board");
        isShutdownRequested = true;

        if (setupManager.getBoard() != null) {
            try {
                if (setupManager.getBoard().isConnected()) {
                    Log.i(TAG, "Board is connected, tearing down routes");
                    setupManager.getBoard().tearDown();

                    try {
                        Log.i(TAG, "Disconnecting board and waiting for completion");
                        setupManager.getBoard().disconnectAsync().waitForCompletion();
                    } catch (Exception e) {
                        Log.e(TAG, "Error waiting for disconnection to complete", e);
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "Error disconnecting from board", e);
            }
        }

        reset();

        if (isServiceBound) {
            try {
                Log.i(TAG, "Unbinding from service");
                context.unbindService(this);
                isServiceBound = false;
            } catch (Exception e) {
                Log.e(TAG, "Error unbinding service", e);
            }
        }
    }

    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
        Log.i(TAG, "Service connected");
        serviceBinder = (BtleService.LocalBinder) service;
        connectToBoard();
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {
        Log.i(TAG, "BT Service Disconnected");

        reset();
        isServiceBound = false;

        int appIconId = ResourceHelper.getAppIconResourceId(context);
        NotificationHelper notificationHelper = new NotificationHelper(context, appIconId);
        notificationHelper.showBluetoothDisconnectionNotification("Bluetooth service disconnected");

        if (!isShutdownRequested && connectionCallback != null) {
            connectionCallback.onDisconnection("Bluetooth service disconnected");

            mainHandler.postDelayed(() -> {
                if (!isShutdownRequested && !macAddress.isEmpty()) {
                    Log.i(TAG, "Service disconnected unexpectedly, attempting to reconnect");
                    connectToDevice(macAddress);
                }
            }, 5000);
        }
    }

    private BluetoothDevice getBluetoothDevice() {
        try {
            BluetoothManager btManager = (BluetoothManager)
                    context.getSystemService(Context.BLUETOOTH_SERVICE);

            if (btManager == null) {
                handleError("Bluetooth manager unavailable");
                return null;
            }

            BluetoothAdapter adapter = btManager.getAdapter();
            if (adapter == null) {
                handleError("Bluetooth adapter unavailable");
                return null;
            }

            if (!adapter.isEnabled()) {
                handleError("Bluetooth is turned off");
                return null;
            }

            try {
                return adapter.getRemoteDevice(macAddress);
            } catch (IllegalArgumentException e) {
                handleError("Invalid MAC address: " + macAddress);
                return null;
            }
        } catch (Exception e) {
            handleError("Error getting Bluetooth device: " + e.getMessage());
            return null;
        }
    }

    private void handleConnectionFailure(Throwable error) {
        Log.e(TAG, "Connection failed", error);

        if (connectionRetries < MAX_CONNECTION_RETRIES) {
            connectionRetries++;
            Log.d(TAG, "Retry " + connectionRetries + "/" + MAX_CONNECTION_RETRIES);

            mainHandler.postDelayed(() -> {
                if (isConnecting.get()) {
                    connectToBoard();
                }
            }, CONNECTION_RETRY_DELAY_MS);
        } else {
            handleError("Failed to connect after " + MAX_CONNECTION_RETRIES + " attempts");
        }
    }

    private void handleConnectionSuccess() {
        Log.i(TAG, "Successfully connected to device");
        connectionRetries = 0;
        isConnected = true;
        setupManager.start();

        setupSensors();
        readBatteryLevel();

        mainHandler.postDelayed(() -> {
            isConnecting.set(false);
            if (connectionCallback != null) {
                connectionCallback.onConnectionSuccess(
                        macAddress,
                        setupManager.getBatteryLevel(),
                        setupManager.getActiveSensors()
                );
            }
        }, 1000);
    }


    private void connectToBoard() {
        try {
            var device = getBluetoothDevice();
            if (device == null) {
                return;
            }

            setupManager.setBoard(serviceBinder.getMetaWearBoard(device));

            Log.d(TAG, "Connecting to device: " + macAddress);
            setupManager.getBoard().connectAsync().continueWith(task -> {
                if (task.isFaulted()) {
                    handleConnectionFailure(task.getError());
                } else {
                    handleConnectionSuccess();
                }
                return null;
            });
        } catch (Exception e) {
            handleError("Connection error: " + e.getMessage());
        }
    }

    private void readBatteryLevel() {
        try {
            Settings settings = setupManager.getBoard().getModule(Settings.class);
            if (settings != null) {
                settings.battery().read();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error reading battery level", e);
        }
    }

    private void setupSensors() {
        if (setupManager.getBoard() == null || !isConnected) {
            Log.w(TAG, "Cannot setup sensors: board is null or not connected");
            return;
        }

        try {
            setupManager.setupAccelerometer();
            setupManager.setupAmbientLight();
            setupManager.setupBarometer();
            setupManager.setupColorTcs();
            setupManager.setupGyro();
            setupManager.setupHumidity();
            setupManager.setupMagnetometer();
            setupManager.setupProximity();
            setupManager.setupSettings();
        } catch (Exception e) {
            Log.e(TAG, "Error setting up sensors", e);
        }
    }

    public Map<String, List<List<Object>>> getModuleData() {
        if (!isConnected || setupManager.getMeasurementHandler() == null) {
            return new HashMap<>();
        }
        return setupManager.getMeasurementHandler().getMeasurementsBuffer();
    }

    public void clearMeasurements() {
        if (setupManager.getMeasurementHandler() != null) {
            setupManager.getMeasurementHandler().clearMeasurements();
        }
    }

    public int getBatteryLevel() {
        return setupManager.getBatteryLevel();
    }

    public void updateBatteryLevel() {
        if (isConnected && setupManager.getBoard() != null && setupManager.getBoard().isConnected()) {
            Settings settings = setupManager.getBoard().getModule(Settings.class);
            if (settings != null) {
                settings.battery().read();
            }
        }
    }

    public void checkConnectionAndReconnect() {
        if (!isConnected && !isConnecting.get() && !isShutdownRequested && !macAddress.isEmpty()) {
            Log.i(TAG, "Connection check detected disconnection, attempting to reconnect");
            connectToDevice(macAddress);
        }
    }

    public interface ConnectionCallback {
        void onConnectionSuccess(String macAddress, int batteryLevel, List<String> activeSensors);

        void onDisconnection(String reason);
    }
}