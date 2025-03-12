package com.example.ppwd_frontend;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.content.ServiceConnection;
import android.content.ComponentName;
import android.content.pm.PackageManager;
import android.os.IBinder;
import android.content.Intent;
import android.content.Context;
import android.bluetooth.BluetoothManager;
import android.util.Log;
import android.Manifest;

import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.android.BtleService;
import com.mbientlab.metawear.data.Acceleration;
import com.mbientlab.metawear.data.AngularVelocity;
import com.mbientlab.metawear.data.MagneticField;
import com.mbientlab.metawear.module.Accelerometer;
import com.mbientlab.metawear.module.GyroBmi160;
import com.mbientlab.metawear.module.MagnetometerBmm150;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;


public class MainActivity extends FlutterActivity implements ServiceConnection {
    private static final String IMPERATIVE_CHANNEL = "flutter.native/sensor/imperative";
    private BtleService.LocalBinder serviceBinder;
    private MetaWearBoard board;
    private String macAddress = "";
    private final List<String> sensorDataBuffer = new CopyOnWriteArrayList<>();

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), IMPERATIVE_CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("connectToSensorService")) {
                                macAddress = call.argument("macAddress");
                                connectToService();
                                result.success("Attempted to connect to: " + macAddress);
                            } else if  (call.method.equals("getSensorData")) {
                                    List<String> dataCopy = new ArrayList<>(sensorDataBuffer);
                                    result.success(dataCopy);
                                    sensorDataBuffer.clear();
                            }else {
                                result.notImplemented();
                            }
                        }
                );

    }

    public void connectToService() {
        getApplicationContext().bindService(new Intent(this, BtleService.class), this, Context.BIND_AUTO_CREATE);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

        getApplicationContext().unbindService(this);
    }

    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
        serviceBinder = (BtleService.LocalBinder) service;
        connectToDevice();
    }

    private void connectToDevice() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.BLUETOOTH_CONNECT}, 1);
        }

        var btManager = (BluetoothManager) getSystemService(BLUETOOTH_SERVICE);
        var btDevice = btManager.getAdapter().getRemoteDevice(macAddress);
        board = serviceBinder.getMetaWearBoard(btDevice);
        board.connectAsync().continueWith(task -> {
            if (task.isFaulted()) {
                // @TODO Handle errors
            } else {
                setupSensors();
            }
            return null;
        });
    }

    private void setupSensors() {
        if (board == null) { return;}

        var accelerometer = board.getModule(Accelerometer.class);
        if (accelerometer != null) {
            accelerometer.acceleration().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(Acceleration.class);
                sensorDataBuffer.add(measurement.toString());
            })).continueWith(task -> {
                accelerometer.acceleration().start();
                accelerometer.start();
                return null;
            });
        }
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {

    }
}