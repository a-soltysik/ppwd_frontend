package com.example.ppwd_frontend;

import android.util.Log;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import io.flutter.plugin.common.MethodChannel;

public class MethodChannelHandler {
    private static final String TAG = "MethodChannelHandler";
    private static final String CHANNEL = "flutter.native/board";
    private static final String connectToBoardFunction = "connectToBoard";
    private static final String disconnectFromBoardFunction = "disconnectFromBoard";
    private static final String getModuleDataFunction = "getModulesData";
    private static final String getBatteryLevelFunction = "getBatteryLevel";
    private static final String handleBoardDisconnectionFunction = "handleBoardDisconnection";
    private static final String onConnectionSuccessFunction = "onConnectionSuccess";

    private final MethodChannel methodChannel;
    private final BluetoothConnectionManager bluetoothManager;

    private final Map<String, Consumer<MethodCallContext>> methodHandlers;

    public MethodChannelHandler(MethodChannel methodChannel, BluetoothConnectionManager bluetoothManager) {
        this.methodChannel = methodChannel;
        this.bluetoothManager = bluetoothManager;
        
        methodHandlers = Map.of(
                connectToBoardFunction, this::handleConnectToBoard,
                disconnectFromBoardFunction, this::handleDisconnectFromBoard,
                getModuleDataFunction, this::handleGetModuleData,
                getBatteryLevelFunction, this::handleGetBatteryLevel
        );

        setupMethodCallHandler();
    }

    private void setupMethodCallHandler() {
        methodChannel.setMethodCallHandler((call, result) -> {
            try {
                Log.d(TAG, "Method call received: " + call.method);
                methodHandlers.getOrDefault(call.method, this::handleUnknown)
                        .accept(new MethodCallContext(call, result));
            } catch (Exception e) {
                Log.e(TAG, "Error handling method call: " + call.method, e);
                result.error("EXCEPTION", e.getMessage(), e.getStackTrace());
            }
        });
    }

    public void handleConnectToBoard(MethodCallContext context) {
        String mac = context.call().argument("macAddress");
        if (mac == null || mac.isEmpty()) {
            context.result().error("INVALID_MAC", "MAC address is invalid or empty", null);
            return;
        }

        if (bluetoothManager.isConnecting()) {
            context.result().error("ALREADY_CONNECTING", "Already attempting to connect to a device", null);
            return;
        }

        Log.i(TAG, "Connecting to device: " + mac);
        bluetoothManager.connectToDevice(mac);
        context.result().success("Attempting to connect to: " + mac);
    }

    public void handleDisconnectFromBoard(MethodCallContext context) {
        Log.i(TAG, "Disconnecting from device");
        bluetoothManager.disconnectFromBoard();
        context.result().success("Disconnected from device");
    }

    public void handleGetModuleData(MethodCallContext context) {
        if (!bluetoothManager.isConnected()) {
            context.result().success(new HashMap<String, List<List<Object>>>());
            return;
        }

        Map<String, List<List<Object>>> data = bluetoothManager.getModuleData();
        context.result().success(data);
        bluetoothManager.clearMeasurements();
    }

    public void handleGetBatteryLevel(MethodCallContext context) {
        if (!bluetoothManager.isConnected()) {
            context.result().success(0);
            return;
        }

        bluetoothManager.updateBatteryLevel();
        context.result().success(bluetoothManager.getBatteryLevel());
    }

    public void handleUnknown(MethodCallContext context) {
        Log.w(TAG, "Unknown method called: " + context.call().method);
        context.result().notImplemented();
    }

    public void notifyConnectionSuccess(String macAddress, int batteryLevel, List<String> activeSensors) {
        if (methodChannel != null) {
            Map<String, Object> data = new HashMap<>();
            data.put("macAddress", macAddress);
            data.put("batteryLevel", batteryLevel);
            data.put("activeSensors", activeSensors);

            Log.i(TAG, "Notifying connection success for " + macAddress + " with " + activeSensors.size() + " sensors");
            methodChannel.invokeMethod(onConnectionSuccessFunction, data);
        }
    }

    public void notifyDisconnection(String reason) {
        if (methodChannel != null) {
            Log.i(TAG, "Notifying disconnection: " + reason);
            methodChannel.invokeMethod(handleBoardDisconnectionFunction, reason);
        }
    }
}