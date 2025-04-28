package com.example.board_plugin;

import java.util.List;       

import android.content.Context;
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;

public final class BoardPlugin implements FlutterPlugin {
    private static final String CHANNEL = "flutter.native/board";

    private MethodChannel channel;
    private BluetoothConnectionManager bluetoothManager;
    private MethodChannelHandler handler;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        Context ctx = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);

        bluetoothManager = new BluetoothConnectionManager(ctx, new SensorSetupManager());

        bluetoothManager.setConnectionCallback(new BluetoothConnectionManager.ConnectionCallback() {
            @Override
            public void onConnectionSuccess(String mac, int batteryLevel, List<String> activeSensors) {
                handler.notifyConnectionSuccess(mac, batteryLevel, activeSensors);
            }
            @Override
            public void onDisconnection(String reason) {
                handler.notifyDisconnection(reason);
            }
        });

        handler = new MethodChannelHandler(channel, bluetoothManager);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (handler != null) {
            channel.setMethodCallHandler(null);
            handler = null;
        }
         if (bluetoothManager != null) {
            bluetoothManager.disconnectFromBoard();
        }
        bluetoothManager = null;
        channel = null;
    }
}
