package com.example.ppwd_frontend;

import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.example.board_plugin.MethodChannelHandler;
import com.example.board_plugin.NotificationHelper;
import com.example.board_plugin.connection.BluetoothConnectionManager;
import com.example.board_plugin.connection.BluetoothForegroundService;
import com.example.board_plugin.setup.SensorSetupManager;

import java.util.List;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MainActivity extends FlutterActivity implements BluetoothConnectionManager.ConnectionCallback, MethodCallHandler {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "flutter.native/board";
    private static final String SCANNER_CHANNEL = "com.example.ppwd_frontend/metawear_scanner";

    private BluetoothConnectionManager bluetoothManager;
    private MethodChannelHandler methodChannelHandler;
    private ForegroundServiceHandler foregroundServiceHandler;
    private NotificationHelper notificationHelper;
    private boolean isConnected = false;

    private MethodChannel scannerChannel;
    private Result pendingScanResult;
    
    private static final int REQUEST_CODE_SCANNER = 100;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        Log.i(TAG, "Configuring Flutter engine");

        notificationHelper = new NotificationHelper(this, R.mipmap.ic_launcher);

        SensorSetupManager setupManager = new SensorSetupManager();
        bluetoothManager = new BluetoothConnectionManager(this, setupManager);
        bluetoothManager.setConnectionCallback(this);

        MethodChannel methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        methodChannelHandler = new MethodChannelHandler(methodChannel, bluetoothManager);

        foregroundServiceHandler = new ForegroundServiceHandler(this, flutterEngine);

        scannerChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SCANNER_CHANNEL);
        scannerChannel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Log.i(TAG, "Method call received: " + call.method);
        
        if (call.method.equals("startScan")) {
            pendingScanResult = result;
            Intent intent = new Intent(this, MetaWearScannerActivity.class);
            startActivityForResult(intent, REQUEST_CODE_SCANNER);
        } else {
            result.notImplemented();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        Log.i(TAG, "Activity result: requestCode=" + requestCode + ", resultCode=" + resultCode);
        
        if (requestCode == REQUEST_CODE_SCANNER) {
            if (resultCode == RESULT_OK && data != null && pendingScanResult != null) {
                String name = data.getStringExtra(MetaWearScannerActivity.EXTRA_DEVICE_NAME);
                String macAddress = data.getStringExtra(MetaWearScannerActivity.EXTRA_MAC_ADDRESS);
                                
                Map<String, Object> result = new HashMap<>();
                result.put("name", name);
                result.put("macAddress", macAddress);
                pendingScanResult.success(result);
            } else if (pendingScanResult != null) {
                pendingScanResult.error("SCAN_CANCELLED", "Scan was cancelled", null);
            }
            pendingScanResult = null;
        }
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