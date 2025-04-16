package com.example.ppwd_frontend;

import androidx.annotation.NonNull;
import io.flutter.app.FlutterApplication;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MyApplication extends FlutterApplication {
    private static final String CHANNEL = "flutter.native/board";
    private static FlutterEngine flutterEngineInstance;
    private static MyApplication instance;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
        // Create a new FlutterEngine using this Application context.
        flutterEngineInstance = new FlutterEngine(this);
        // Register all generated plugins.
        GeneratedPluginRegistrant.registerWith(flutterEngineInstance);
        // Register your native method channel globally.
        registerNativeMethodChannel(flutterEngineInstance);
    }
    
    public static MyApplication getInstance() {
        return instance;
    }
    
    public static FlutterEngine getFlutterEngineInstance() {
        return flutterEngineInstance;
    }
    
    // Register your native method channel using your existing classes.
    public static void registerNativeMethodChannel(@NonNull FlutterEngine flutterEngine) {
        MethodChannel methodChannel = new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        
        // Create new instances of your existing classes.
        SensorSetupManager setupManager = new SensorSetupManager();
        // Use the Application context for global registration.
        BluetoothConnectionManager bluetoothManager = new BluetoothConnectionManager(getInstance(), setupManager);
        new MethodChannelHandler(methodChannel, bluetoothManager);
    }
}
