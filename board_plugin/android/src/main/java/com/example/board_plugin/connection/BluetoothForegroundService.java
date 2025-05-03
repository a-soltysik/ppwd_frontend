package com.example.board_plugin.connection;

import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;

import com.example.board_plugin.NotificationHelper;
import com.example.board_plugin.ResourceHelper;
import com.example.board_plugin.setup.SensorSetupManager;

import java.util.Timer;
import java.util.TimerTask;

public class BluetoothForegroundService extends Service {
    private static final String TAG = "BtForegroundService";

    private BluetoothConnectionManager bluetoothManager;
    private Timer connectionCheckTimer;
    private String connectedMacAddress;
    private int batteryLevel = 0;
    private int previousBatteryLevel = 0;
    private long lastBatteryNotificationTime = 0;
    private NotificationHelper notificationHelper;

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "Foreground service created");

        int appIconResId = ResourceHelper.getAppIconResourceId(this);

        notificationHelper = new NotificationHelper(this, appIconResId);
        var setupManager = new SensorSetupManager();
        bluetoothManager = new BluetoothConnectionManager(this, setupManager);
        bluetoothManager.setConnectionCallback(new BluetoothConnectionManager.ConnectionCallback() {
            @Override
            public void onConnectionSuccess(String macAddress, int batteryLevel, java.util.List<String> activeSensors) {
                Log.i(TAG, "Connected to device: " + macAddress + " with battery: " + batteryLevel);
                connectedMacAddress = macAddress;
                previousBatteryLevel = BluetoothForegroundService.this.batteryLevel;
                BluetoothForegroundService.this.batteryLevel = batteryLevel;

                updateNotification();

                if (batteryLevel != previousBatteryLevel) {
                    checkBatteryLevel();
                }
            }

            @Override
            public void onDisconnection(String reason) {
                Log.i(TAG, "Disconnected: " + reason);
                connectedMacAddress = null;

                notificationHelper.showBluetoothDisconnectionNotification(reason);

                stopForeground(true);
                stopSelf();
            }
        });
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.i(TAG, "Starting foreground service");

        if (intent != null && intent.hasExtra("macAddress")) {
            connectedMacAddress = intent.getStringExtra("macAddress");
            Log.i(TAG, "Service connecting to: " + connectedMacAddress);

            Intent disconnectIntent = new Intent("com.example.ppwd_frontend.DISCONNECT");
            PendingIntent disconnectPendingIntent = PendingIntent.getBroadcast(
                    this, 0, disconnectIntent, PendingIntent.FLAG_IMMUTABLE);

            startForeground(NotificationHelper.FOREGROUND_NOTIFICATION_ID,
                    notificationHelper.createForegroundNotification(
                            connectedMacAddress, batteryLevel, disconnectPendingIntent));

            if (connectedMacAddress != null && !connectedMacAddress.isEmpty()) {
                bluetoothManager.connectToDevice(connectedMacAddress);
            }
            startConnectionChecks();
        } else {
            Log.e(TAG, "No MAC address provided, stopping service");
            stopSelf();
        }

        return START_STICKY;
    }

    private void startConnectionChecks() {
        if (connectionCheckTimer != null) {
            connectionCheckTimer.cancel();
            connectionCheckTimer = null;
        }

        connectionCheckTimer = new Timer();
        scheduleNextConnectionCheck();
    }

    private void scheduleNextConnectionCheck() {
        boolean isDestroyed = false;
        if (!isDestroyed && connectionCheckTimer != null) {
            connectionCheckTimer.schedule(new TimerTask() {
                @Override
                public void run() {
                    try {
                        performConnectionCheck();
                    } finally {
                        scheduleNextConnectionCheck();
                    }
                }
            }, 60000);
        }
    }

    private void performConnectionCheck() {
        if (!bluetoothManager.isConnected()) {
            Log.i(TAG, "Connection lost, attempting to reconnect");
            if (connectedMacAddress != null) {
                bluetoothManager.connectToDevice(connectedMacAddress);
            }
        } else {
            previousBatteryLevel = batteryLevel;
            bluetoothManager.updateBatteryLevel();
            batteryLevel = bluetoothManager.getBatteryLevel();

            if (batteryLevel != previousBatteryLevel) {
                updateNotification();
                Log.i(TAG, "Battery level updated: " + previousBatteryLevel + "% -> " + batteryLevel + "%");

                checkBatteryLevel();
            }

            broadcastDataAvailable();
        }
    }

    private void broadcastDataAvailable() {
        var sensorData = bluetoothManager.getModuleData();

        var dataIntent = new Intent("com.example.ppwd_frontend.DATA_AVAILABLE");
        dataIntent.putExtra("macAddress", connectedMacAddress);
        dataIntent.putExtra("batteryLevel", batteryLevel);
        dataIntent.putExtra("hasNewData", !sensorData.isEmpty());

        Log.i(TAG, "Broadcasting data available with battery level: " + batteryLevel);
        sendBroadcast(dataIntent);
    }

    private void updateNotification() {
        Intent disconnectIntent = new Intent("com.example.ppwd_frontend.DISCONNECT");
        PendingIntent disconnectPendingIntent = PendingIntent.getBroadcast(
                this, 0, disconnectIntent, PendingIntent.FLAG_IMMUTABLE);

        notificationHelper.updateForegroundNotification(
                connectedMacAddress, batteryLevel, disconnectPendingIntent);
    }

    private void checkBatteryLevel() {
        Intent disconnectIntent = new Intent("com.example.ppwd_frontend.DISCONNECT");
        PendingIntent disconnectPendingIntent = PendingIntent.getBroadcast(
                this, 0, disconnectIntent, PendingIntent.FLAG_IMMUTABLE);

        lastBatteryNotificationTime = notificationHelper.checkAndNotifyLowBattery(
                batteryLevel, previousBatteryLevel, lastBatteryNotificationTime, disconnectPendingIntent);
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        super.onTaskRemoved(rootIntent);

        if (connectedMacAddress != null) {
            updateNotification();
        }
    }
}