package com.example.board_plugin;              // <- note the package

import android.content.Context;
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;

import com.example.board_plugin.MethodChannelHandler;
import com.example.board_plugin.BluetoothConnectionManager;
import com.example.board_plugin.SensorSetupManager;


public final class BoardPlugin implements FlutterPlugin {

    private MethodChannel channel;

    @Override public void onAttachedToEngine(@NonNull FlutterPluginBinding b) {
        Context ctx = b.getApplicationContext();
        channel = new MethodChannel(b.getBinaryMessenger(), "flutter.native/board");

        new MethodChannelHandler(
                channel,
                new BluetoothConnectionManager(ctx, new SensorSetupManager()));
    }

    @Override public void onDetachedFromEngine(@NonNull FlutterPluginBinding b) {
        if (channel != null) channel.setMethodCallHandler(null);
        channel = null;
    }
}
