package com.example.ppwd_frontend;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import com.example.board_plugin.NotificationHelper;
import com.example.board_plugin.ResourceHelper;
import com.example.board_plugin.connection.BluetoothForegroundService;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ForegroundServiceHandler implements MethodChannel.MethodCallHandler {
    private static final String TAG = "ForegroundServiceHandler";
    private static final String CHANNEL = "flutter.native/foreground_service";

    private final Context context;
    private final MethodChannel methodChannel;
    private final BroadcastReceiver dataReceiver;
    private final BroadcastReceiver disconnectReceiver;

    public ForegroundServiceHandler(Context context, FlutterEngine flutterEngine) {
        this.context = context;
        this.methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        this.methodChannel.setMethodCallHandler(this);

        this.dataReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if ("com.example.ppwd_frontend.DATA_AVAILABLE".equals(intent.getAction())) {
                    String macAddress = intent.getStringExtra("macAddress");
                    int batteryLevel = intent.getIntExtra("batteryLevel", 0);
                    boolean hasNewData = intent.getBooleanExtra("hasNewData", false);

                    Map<String, Object> dataMap = new HashMap<>();
                    dataMap.put("macAddress", macAddress);
                    dataMap.put("batteryLevel", batteryLevel);
                    dataMap.put("hasNewData", hasNewData);

                    Log.i(TAG, "Forwarding data available to Flutter: battery=" + batteryLevel + ", hasNewData=" + hasNewData);
                    methodChannel.invokeMethod("onDataAvailable", dataMap);
                }
            }
        };

        this.disconnectReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if ("com.example.ppwd_frontend.DISCONNECT".equals(intent.getAction())) {
                    int appIconId = ResourceHelper.getAppIconResourceId(context);
                    NotificationHelper notificationHelper = new NotificationHelper(context, appIconId);
                    notificationHelper.showBluetoothDisconnectionNotification("Service manually disconnected");

                    methodChannel.invokeMethod("onDisconnect", null);
                }
            }
        };

        registerReceivers();
    }

    private void registerReceivers() {
        IntentFilter dataFilter = new IntentFilter("com.example.ppwd_frontend.DATA_AVAILABLE");
        IntentFilter disconnectFilter = new IntentFilter("com.example.ppwd_frontend.DISCONNECT");

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(dataReceiver, dataFilter, Context.RECEIVER_NOT_EXPORTED);
            context.registerReceiver(disconnectReceiver, disconnectFilter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            context.registerReceiver(dataReceiver, dataFilter);
            context.registerReceiver(disconnectReceiver, disconnectFilter);
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "startService":
                String macAddress = call.argument("macAddress");
                if (macAddress == null || macAddress.isEmpty()) {
                    result.error("INVALID_MAC", "MAC address is empty", null);
                    return;
                }

                startForegroundService(macAddress);
                result.success(true);
                break;

            case "stopService":
                stopForegroundService();
                result.success(true);
                break;

            default:
                result.notImplemented();
        }
    }

    private void startForegroundService(String macAddress) {
        Log.i(TAG, "Starting foreground service with MAC: " + macAddress);
        Intent serviceIntent = new Intent(context, BluetoothForegroundService.class);
        serviceIntent.putExtra("macAddress", macAddress);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent);
        } else {
            context.startService(serviceIntent);
        }
    }

    private void stopForegroundService() {
        Log.i(TAG, "Stopping foreground service");
        context.stopService(new Intent(context, BluetoothForegroundService.class));
    }

    public void cleanup() {
        try {
            context.unregisterReceiver(dataReceiver);
            context.unregisterReceiver(disconnectReceiver);
        } catch (Exception e) {
            Log.e(TAG, "Error unregistering receivers", e);
        }
    }
}