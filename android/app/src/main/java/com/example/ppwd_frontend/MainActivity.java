package com.example.ppwd_frontend;

import android.util.Log;

import androidx.annotation.NonNull;

import com.example.board_plugin.BluetoothConnectionManager;
import com.example.board_plugin.MethodChannelHandler;
import com.example.board_plugin.SensorSetupManager;

import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;


public class MainActivity extends FlutterActivity implements BluetoothConnectionManager.ConnectionCallback {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "flutter.native/board";

    private BluetoothConnectionManager bluetoothManager;
    private MethodChannelHandler methodChannelHandler;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        Log.i(TAG, "Configuring Flutter engine");

        SensorSetupManager setupManager = new SensorSetupManager();
        bluetoothManager = new BluetoothConnectionManager(this, setupManager);
        bluetoothManager.setConnectionCallback(this);

        MethodChannel methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        methodChannelHandler = new MethodChannelHandler(methodChannel, bluetoothManager);
    }

    @Override
    public void onConnectionSuccess(String macAddress, int batteryLevel, List<String> activeSensors) {
        Log.i(TAG, "Connection success callback received");
        runOnUiThread(() -> {
            methodChannelHandler.notifyConnectionSuccess(macAddress, batteryLevel, activeSensors);
        });
    }

    @Override
    public void onDisconnection(String reason) {
        Log.i(TAG, "Disconnection callback received: " + reason);
        runOnUiThread(() -> {
            methodChannelHandler.notifyDisconnection(reason);
        });
    }
}