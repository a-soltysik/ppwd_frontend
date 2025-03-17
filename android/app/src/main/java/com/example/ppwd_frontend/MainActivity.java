package com.example.ppwd_frontend;

import android.bluetooth.BluetoothManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.NonNull;

import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.android.BtleService;
import com.mbientlab.metawear.data.Acceleration;
import com.mbientlab.metawear.data.AngularVelocity;
import com.mbientlab.metawear.data.MagneticField;
import com.mbientlab.metawear.module.Accelerometer;
import com.mbientlab.metawear.module.AmbientLightLtr329;
import com.mbientlab.metawear.module.BarometerBosch;
import com.mbientlab.metawear.module.ColorTcs34725;
import com.mbientlab.metawear.module.Gyro;
import com.mbientlab.metawear.module.HumidityBme280;
import com.mbientlab.metawear.module.MagnetometerBmm150;
import com.mbientlab.metawear.module.ProximityTsl2671;
import com.mbientlab.metawear.module.Settings;

import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;


public class MainActivity extends FlutterActivity implements ServiceConnection {
    private static final String CHANNEL = "flutter.native/board";
    private static final String connectToBoardFunction = "connectToBoard";
    private static final String getModuleDataFunction = "getModulesData";
    private static final String getBatteryLevelFunction = "getBatteryLevel";
    private static final String handleBoardDisconnection = "handleBoardDisconnection";
    private final Map<String, List<List<Object>>> sensorDataBuffer = new ConcurrentHashMap<>();
    private BtleService.LocalBinder serviceBinder;
    private MetaWearBoard board;
    private String macAddress = "";
    private MethodChannel methodChannel;
    private byte batteryLevel = 0;

    private static String cleanedUpString(String rawData) {
        final String removeUnitsRegex = "([-+]?[0-9]*\\.?[0-9]+)\\S*(?=[,}])";
        return rawData.replaceAll(removeUnitsRegex, "$1").replaceAll("(\\w+):", "\"$1\":").trim();
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        methodChannel
                .setMethodCallHandler(
                        (call, result) -> {
                            switch (call.method) {
                                case connectToBoardFunction -> {
                                    macAddress = call.argument("macAddress");
                                    connectToService();
                                    result.success("Attempted to connect to: " + macAddress);
                                }
                                case getModuleDataFunction -> {
                                    result.success(sensorDataBuffer);
                                    sensorDataBuffer.clear();
                                }
                                case getBatteryLevelFunction -> {
                                    result.success(batteryLevel);
                                }
                                default -> result.notImplemented();
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
        var btManager = (BluetoothManager) getSystemService(BLUETOOTH_SERVICE);
        var btDevice = btManager.getAdapter().getRemoteDevice(macAddress);
        board = serviceBinder.getMetaWearBoard(btDevice);
        board.connectAsync().continueWith(task -> {
            if (task.isFaulted()) {
                handleBoardDisconnection();
            } else {
                setupSensors();
            }
            return null;
        });
    }

    private void setupSensors() {
        if (board == null) {
            return;
        }

        setupAccelerometer();
        setupAmbientLight();
        setupBarometer();
        setupColorTcs();
        setupGyro();
        setupHumidity();
        setupMagnetometer();
        setupProximity();
        setupSettings();
    }

    private void setupAccelerometer() {
        var accelerometer = board.getModule(Accelerometer.class);
        if (accelerometer != null) {
            accelerometer.acceleration().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(Acceleration.class).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        MeasurementType.ACCELERATION.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            })).continueWith(task -> {
                accelerometer.acceleration().start();
                accelerometer.start();
                return null;
            });
        }
    }

    private void setupAmbientLight() {
        var ambientLight = board.getModule(AmbientLightLtr329.class);
        if (ambientLight != null) {
            ambientLight.illuminance().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(float.class).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        MeasurementType.ILLUMINANCE.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            })).continueWith(task -> {
                ambientLight.illuminance().start();
                return null;
            });
        }
    }

    private void setupBarometer() {
        var barometerBosch = board.getModule(BarometerBosch.class);
        if (barometerBosch != null) {
            barometerBosch.altitude().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(float.class).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        MeasurementType.ALTITUDE.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            })).continueWith(task -> {
                barometerBosch.altitude();
                barometerBosch.start();
                return null;
            });

            barometerBosch.pressure().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(float.class).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        MeasurementType.PRESSURE.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            })).continueWith(task -> {
                barometerBosch.pressure();
                barometerBosch.start();
                return null;
            });
        }
    }

    private void setupColorTcs() {
        var colorTcs = board.getModule(ColorTcs34725.class);
        if (colorTcs != null) {
            colorTcs.adc().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(ColorTcs34725.ColorAdc.class).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        MeasurementType.COLOR_ADC.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            }));
        }
    }

    private void setupGyro() {
        var gyro = board.getModule(Gyro.class);
        if (gyro != null) {
            gyro.angularVelocity().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(AngularVelocity.class).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        MeasurementType.ANGULAR_VELOCITY.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            })).continueWith(task -> {
                gyro.angularVelocity().start();
                gyro.start();
                return null;
            });
        }
    }

    private void setupHumidity() {
        var humidity = board.getModule(HumidityBme280.class);
        if (humidity != null) {
            humidity.value().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(float.class).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        MeasurementType.HUMIDITY.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            }));
        }
    }

    private void setupMagnetometer() {
        var magnetometer = board.getModule(MagnetometerBmm150.class);
        if (magnetometer != null) {
            magnetometer.magneticField().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(MagneticField.class).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        MeasurementType.MAGNETIC_FIELD.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            })).continueWith(task -> {
                magnetometer.magneticField().start();
                magnetometer.start();
                return null;
            });
        }
    }

    private void setupProximity() {
        var proximity = board.getModule(ProximityTsl2671.class);
        if (proximity != null) {
            proximity.adc().addRouteAsync(source -> source.stream((data, env) -> {
                var measurement = data.value(int.class).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        MeasurementType.PROXIMITY_ADC.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            }));
        }
    }

    private void setupSettings() {
        var settings = board.getModule(Settings.class);
        if (settings != null) {
            settings.battery().addRouteAsync(source -> source.stream((data, env) ->
                    batteryLevel = data.value(Settings.BatteryState.class).charge
            ));
        }
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {
        Log.i("Service", "BT Disconnected");
        handleBoardDisconnection();
    }

    public void handleBoardDisconnection() {
        methodChannel.invokeMethod(handleBoardDisconnection, null);
    }

    private enum MeasurementType {
        ACCELERATION("acceleration"),
        ILLUMINANCE("illuminance"),
        ALTITUDE("altitude"),
        PRESSURE("pressure"),
        COLOR_ADC("colorAdc"),
        ANGULAR_VELOCITY("angularVelocity"),
        HUMIDITY("humidity"),
        MAGNETIC_FIELD("magneticField"),
        PROXIMITY_ADC("proximityAdc");

        private final String name;

        MeasurementType(final String name) {
            this.name = name;
        }

        @NonNull
        @Override
        public String toString() {
            return name;
        }
    }
}