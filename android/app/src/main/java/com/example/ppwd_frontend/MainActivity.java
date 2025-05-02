package com.example.ppwd_frontend;

import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import com.example.board_plugin.MethodChannelHandler;
import com.example.board_plugin.connection.BluetoothConnectionManager;
import com.example.board_plugin.setup.SensorSetupManager;
import com.example.ppwd_frontend.bluetooth.BluetoothForegroundService;

import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;


public class MainActivity extends FlutterActivity implements BluetoothConnectionManager.ConnectionCallback {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "flutter.native/board";

    private BluetoothConnectionManager bluetoothManager;
    private MethodChannelHandler methodChannelHandler;
    private ForegroundServiceHandler foregroundServiceHandler;
    private NotificationHelper notificationHelper;
    private boolean isConnected = false;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        Log.i(TAG, "Configuring Flutter engine");

        notificationHelper = new NotificationHelper(this);

        SensorSetupManager setupManager = new SensorSetupManager();
        bluetoothManager = new BluetoothConnectionManager(this, setupManager);
        bluetoothManager.setConnectionCallback(this);

        MethodChannel methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        methodChannelHandler = new MethodChannelHandler(methodChannel, bluetoothManager);

        foregroundServiceHandler = new ForegroundServiceHandler(this, flutterEngine);
    }

    @Override
    public void onConnectionSuccess(String macAddress, int batteryLevel, List<String> activeSensors) {
        Log.i(TAG, "Connection success callback received");
        isConnected = true;
        runOnUiThread(() -> {
            methodChannelHandler.notifyConnectionSuccess(macAddress, batteryLevel, activeSensors);
        });
    }

    @Override
    public void onDisconnection(String reason) {
        Log.i(TAG, "Disconnection callback received: " + reason);
        isConnected = false;
        runOnUiThread(() -> {
            methodChannelHandler.notifyDisconnection(reason);
        });
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "MainActivity is being destroyed");

        if (!isChangingConfigurations()) {
            if (isConnected || (bluetoothManager != null && bluetoothManager.isConnected())) {
                notificationHelper.showAppKilledNotification();
            }

            Intent serviceIntent = new Intent(this, BluetoothForegroundService.class);
            stopService(serviceIntent);

            android.os.Process.killProcess(android.os.Process.myPid());
        }

        if (foregroundServiceHandler != null) {
            foregroundServiceHandler.cleanup();
        }
        super.onDestroy();
    }
}