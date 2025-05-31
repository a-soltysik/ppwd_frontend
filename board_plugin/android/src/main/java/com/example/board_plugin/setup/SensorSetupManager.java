package com.example.board_plugin.setup;

import android.util.Log;

import com.example.board_plugin.measurement.MeasurementHandler;
import com.example.board_plugin.measurement.MeasurementType;
import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.data.Acceleration;
import com.mbientlab.metawear.data.AngularVelocity;
import com.mbientlab.metawear.module.Accelerometer;
import com.mbientlab.metawear.module.Gyro;
import com.mbientlab.metawear.module.Settings;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

public class SensorSetupManager {

    private static final String TAG = "SensorSetupManager";
    private final List<String> activeSensors = new ArrayList<>();
    AtomicInteger pendingSensorSetups = new AtomicInteger(0);
    MetaWearBoard board;
    MeasurementHandler measurementHandler = new MeasurementHandler();
    private byte batteryLevel = -1;

    public void setupAccelerometer() {
        try {
            var accelerometer = board.getModule(Accelerometer.class);
            if (accelerometer != null) {
                accelerometer.acceleration().addRouteAsync(source -> source.stream((data, env) -> {
                    measurementHandler.performMeasurement(MeasurementType.ACCELERATION, Acceleration.class, data);
                })).continueWith(task -> {
                    pendingSensorSetups.decrementAndGet();
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up accelerometer route", task.getError());
                    } else {
                        accelerometer.acceleration().start();
                        accelerometer.start();
                        synchronized (activeSensors) {
                            activeSensors.add("Accelerometer");
                        }
                        Log.i(TAG, "Accelerometer sensor activated");
                    }
                    return null;
                });
            } else {
                pendingSensorSetups.decrementAndGet();
                Log.w(TAG, "Accelerometer module not available");
            }
        } catch (Exception e) {
            pendingSensorSetups.decrementAndGet();
            Log.e(TAG, "Error setting up accelerometer", e);
        }
    }

    public void setupGyro() {
        try {
            var gyro = board.getModule(Gyro.class);
            if (gyro != null) {
                gyro.angularVelocity().addRouteAsync(source -> source.stream((data, env) -> {
                    measurementHandler.performMeasurement(MeasurementType.ANGULAR_VELOCITY, AngularVelocity.class, data);
                })).continueWith(task -> {
                    pendingSensorSetups.decrementAndGet();
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up gyro route", task.getError());
                    } else {
                        gyro.angularVelocity().start();
                        gyro.start();
                        synchronized (activeSensors) {
                            activeSensors.add("Gyroscope");
                        }
                        Log.i(TAG, "Gyroscope sensor activated");
                    }
                    return null;
                });
            } else {
                pendingSensorSetups.decrementAndGet();
                Log.w(TAG, "Gyro module not available");
            }
        } catch (Exception e) {
            pendingSensorSetups.decrementAndGet();
            Log.e(TAG, "Error setting up gyro", e);
        }
    }

    public void setupSettings() {
        try {
            var settings = board.getModule(Settings.class);
            if (settings != null) {
                settings.battery().addRouteAsync(source ->
                        source.stream((data, env) -> {
                            batteryLevel = data.value(Settings.BatteryState.class).charge;
                        })
                ).continueWith(task -> {
                    pendingSensorSetups.decrementAndGet();
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up battery route", task.getError());
                    } else {
                        settings.battery().read();
                        synchronized (activeSensors) {
                            activeSensors.add("Battery");
                        }
                        Log.i(TAG, "Battery sensor activated");
                    }
                    return null;
                });
            } else {
                pendingSensorSetups.decrementAndGet();
                Log.w(TAG, "Settings module not available");
            }
        } catch (Exception e) {
            pendingSensorSetups.decrementAndGet();
            Log.e(TAG, "Error setting up settings", e);
        }
    }

    public byte getBatteryLevel() {
        return batteryLevel;
    }

    public void clear() {
        activeSensors.clear();
        batteryLevel = -1;
    }

    public void start() {
        activeSensors.clear();
        pendingSensorSetups = new AtomicInteger(9);
    }

    public List<String> getActiveSensors() {
        return activeSensors;
    }

    public MeasurementHandler getMeasurementHandler() {
        return measurementHandler;
    }

    public MetaWearBoard getBoard() {
        return board;
    }

    public void setBoard(MetaWearBoard board) {
        this.board = board;
    }
}
