package com.example.board_plugin;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import com.mbientlab.metawear.android.BtleService;
import com.mbientlab.metawear.module.Settings;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

public class BluetoothConnectionManager implements ServiceConnection {
    private static final String TAG = "BluetoothManager";
    private static final int MAX_CONNECTION_RETRIES = 2;
    private static final long CONNECTION_RETRY_DELAY_MS = 1500;

    private final Context context;
    private final Handler mainHandler;
    private final AtomicBoolean isConnecting = new AtomicBoolean(false);
    private final BluetoothErrorHelper bluetoothErrorHelper = new BluetoothErrorHelper();
    private final SensorSetupManager setupManager;

    private BtleService.LocalBinder serviceBinder;
    private String macAddress = "";
    private boolean isConnected = false;
    private int connectionRetries = 0;
    private boolean isServiceBound = false;
    private ConnectionCallback connectionCallback;

    public BluetoothConnectionManager(Context context, SensorSetupManager setupManager) {
        this.context = context;
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

        if (isConnecting.get()) {
            Log.e(TAG, "Already attempting to connect to a device");
            if (connectionCallback != null) {
                connectionCallback.onDisconnection("Already attempting to connect to a device");
            }
            return;
        }

        // Always ensure we're properly disconnected before connecting
        if (isConnected || isServiceBound) {
            Log.i(TAG, "Disconnecting from previous connection before reconnecting");
            disconnectFromBoard();

            // Small delay to ensure disconnection completes
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
                Log.e(TAG, "Failed to bind to service");
                isConnecting.set(false);
                if (connectionCallback != null) {
                    connectionCallback.onDisconnection("Failed to bind to Bluetooth service");
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error binding to BtleService", e);
            isConnecting.set(false);
            if (connectionCallback != null) {
                connectionCallback.onDisconnection("Failed to initialize Bluetooth service: " + e.getMessage());
            }
        }
    }

    public void disconnectFromBoard() {
        Log.i(TAG, "Disconnecting from board");

        if (setupManager.getBoard() != null) {
            try {
                if (setupManager.getBoard().isConnected()) {
                    Log.i(TAG, "Board is connected, tearing down routes");
                    setupManager.getBoard().tearDown();

                    // Disconnect synchronously to ensure completion
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

        isConnected = false;
        isConnecting.set(false);
        setupManager.clear();

        // Unbind the service after disconnection
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
        connectToBoardInternal();
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {
        Log.i(TAG, "BT Service Disconnected");
        isConnected = false;
        isServiceBound = false;
        isConnecting.set(false);
        setupManager.clear();
        if (connectionCallback != null) {
            connectionCallback.onDisconnection("Bluetooth service disconnected");
        }
    }

    private void connectToBoardInternal() {
        try {
            android.bluetooth.BluetoothManager btManager = (android.bluetooth.BluetoothManager)
                    context.getSystemService(Context.BLUETOOTH_SERVICE);

            if (btManager == null) {
                Log.e(TAG, "BluetoothManager is null");
                isConnecting.set(false);
                if (connectionCallback != null) {
                    connectionCallback.onDisconnection("Bluetooth manager unavailable");
                }
                return;
            }

            BluetoothAdapter adapter = btManager.getAdapter();
            if (adapter == null) {
                Log.e(TAG, "BluetoothAdapter is null");
                isConnecting.set(false);
                if (connectionCallback != null) {
                    connectionCallback.onDisconnection("Bluetooth adapter unavailable");
                }
                return;
            }

            if (!adapter.isEnabled()) {
                Log.e(TAG, "Bluetooth is not enabled");
                isConnecting.set(false);
                if (connectionCallback != null) {
                    connectionCallback.onDisconnection("Bluetooth is turned off");
                }
                return;
            }

            BluetoothDevice btDevice;
            try {
                btDevice = adapter.getRemoteDevice(macAddress);
                if (btDevice == null) {
                    throw new IllegalArgumentException("Could not find device with address: " + macAddress);
                }
            } catch (IllegalArgumentException e) {
                Log.e(TAG, "Invalid MAC address: " + macAddress, e);
                isConnecting.set(false);
                if (connectionCallback != null) {
                    connectionCallback.onDisconnection("Invalid MAC address format");
                }
                return;
            }

            // Set up a new board instance
            setupManager.setBoard(serviceBinder.getMetaWearBoard(btDevice));

            Log.i(TAG, "Attempting to connect to device: " + macAddress);
            setupManager.getBoard().connectAsync().continueWith(task -> {
                if (task.isFaulted()) {
                    Throwable error = task.getError();
                    Log.e(TAG, "Failed to connect", error);

                    if (bluetoothErrorHelper.shouldRetryConnection(error) &&
                            connectionRetries < MAX_CONNECTION_RETRIES) {
                        connectionRetries++;
                        Log.i(TAG, "Retrying connection, attempt " + connectionRetries);

                        // Wait and retry
                        mainHandler.postDelayed(() -> {
                            if (isConnecting.get()) {
                                connectToBoardInternal();
                            }
                        }, CONNECTION_RETRY_DELAY_MS);
                    } else {
                        isConnecting.set(false);
                        if (connectionCallback != null) {
                            connectionCallback.onDisconnection(
                                    bluetoothErrorHelper.getBluetoothErrorMessage(error)
                            );
                        }
                    }
                } else {
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
                return null;
            });
        } catch (Exception e) {
            Log.e(TAG, "Error connecting to device", e);
            isConnecting.set(false);
            if (connectionCallback != null) {
                connectionCallback.onDisconnection("Connection error: " + e.getMessage());
            }
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

    public interface ConnectionCallback {
        void onConnectionSuccess(String macAddress, int batteryLevel, List<String> activeSensors);

        void onDisconnection(String reason);
    }
}