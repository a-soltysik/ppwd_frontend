package com.example.ppwd_frontend;

import android.util.Log;

import com.mbientlab.metawear.MetaWearBoard;
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

    public void setupAmbientLight() {
        try {
            var ambientLight = board.getModule(AmbientLightLtr329.class);
            if (ambientLight != null) {
                ambientLight.illuminance().addRouteAsync(source -> source.stream((data, env) -> {
                    measurementHandler.performMeasurement(MeasurementType.ILLUMINANCE, float.class, data);
                })).continueWith(task -> {
                    pendingSensorSetups.decrementAndGet();
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up ambient light route", task.getError());
                    } else {
                        ambientLight.illuminance().start();
                        synchronized (activeSensors) {
                            activeSensors.add("Ambient Light");
                        }
                        Log.i(TAG, "Ambient Light sensor activated");
                    }
                    return null;
                });
            } else {
                pendingSensorSetups.decrementAndGet();
                Log.w(TAG, "Ambient light module not available");
            }
        } catch (Exception e) {
            pendingSensorSetups.decrementAndGet();
            Log.e(TAG, "Error setting up ambient light", e);
        }
    }

    public void setupBarometer() {
        try {
            var barometerBosch = board.getModule(BarometerBosch.class);
            if (barometerBosch != null) {
                final AtomicInteger barometerRoutes = new AtomicInteger(2);

                barometerBosch.altitude().addRouteAsync(source -> source.stream((data, env) -> {
                    measurementHandler.performMeasurement(MeasurementType.ALTITUDE, float.class, data);
                })).continueWith(task -> {
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up altitude route", task.getError());
                    } else {
                        barometerBosch.altitude().start();
                        barometerBosch.start();
                        synchronized (activeSensors) {
                            if (!activeSensors.contains("Barometer")) {
                                activeSensors.add("Barometer");
                            }
                        }
                        Log.i(TAG, "Barometer (altitude) sensor activated");
                    }

                    if (barometerRoutes.decrementAndGet() == 0) {
                        pendingSensorSetups.decrementAndGet();
                    }
                    return null;
                });

                barometerBosch.pressure().addRouteAsync(source -> source.stream((data, env) -> {
                    measurementHandler.performMeasurement(MeasurementType.PRESSURE, float.class, data);
                })).continueWith(task -> {
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up pressure route", task.getError());
                    } else {
                        barometerBosch.pressure().start();
                        barometerBosch.start();
                        synchronized (activeSensors) {
                            if (!activeSensors.contains("Barometer")) {
                                activeSensors.add("Barometer");
                            }
                        }
                        Log.i(TAG, "Barometer (pressure) sensor activated");
                    }

                    if (barometerRoutes.decrementAndGet() == 0) {
                        pendingSensorSetups.decrementAndGet();
                    }
                    return null;
                });
            } else {
                pendingSensorSetups.decrementAndGet();
                Log.w(TAG, "Barometer module not available");
            }
        } catch (Exception e) {
            pendingSensorSetups.decrementAndGet();
            Log.e(TAG, "Error setting up barometer", e);
        }
    }

    public void setupColorTcs() {
        try {
            var colorTcs = board.getModule(ColorTcs34725.class);
            if (colorTcs != null) {
                colorTcs.adc().addRouteAsync(source -> source.stream((data, env) -> {
                    measurementHandler.performMeasurement(MeasurementType.COLOR_ADC, ColorTcs34725.ColorAdc.class, data);
                })).continueWith(task -> {
                    pendingSensorSetups.decrementAndGet();
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up color ADC route", task.getError());
                    } else {
                        synchronized (activeSensors) {
                            activeSensors.add("Color Sensor");
                        }
                        Log.i(TAG, "Color sensor activated");
                    }
                    return null;
                });
            } else {
                pendingSensorSetups.decrementAndGet();
                Log.w(TAG, "Color TCS module not available");
            }
        } catch (Exception e) {
            pendingSensorSetups.decrementAndGet();
            Log.e(TAG, "Error setting up color TCS", e);
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

    public void setupHumidity() {
        try {
            var humidity = board.getModule(HumidityBme280.class);
            if (humidity != null) {
                humidity.value().addRouteAsync(source -> source.stream((data, env) -> {
                    measurementHandler.performMeasurement(MeasurementType.HUMIDITY, float.class, data);
                })).continueWith(task -> {
                    pendingSensorSetups.decrementAndGet();
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up humidity route", task.getError());
                    } else {
                        synchronized (activeSensors) {
                            activeSensors.add("Humidity Sensor");
                        }
                        Log.i(TAG, "Humidity sensor activated");
                    }
                    return null;
                });
            } else {
                pendingSensorSetups.decrementAndGet();
                Log.w(TAG, "Humidity module not available");
            }
        } catch (Exception e) {
            pendingSensorSetups.decrementAndGet();
            Log.e(TAG, "Error setting up humidity", e);
        }
    }

    public void setupMagnetometer() {
        try {
            var magnetometer = board.getModule(MagnetometerBmm150.class);
            if (magnetometer != null) {

                magnetometer.usePreset(MagnetometerBmm150.Preset.REGULAR);
                magnetometer.magneticField().addRouteAsync(source -> source.stream((data, env) -> {
                    measurementHandler.performMeasurement(MeasurementType.MAGNETIC_FIELD, MagneticField.class, data);
                })).continueWith(task -> {
                    pendingSensorSetups.decrementAndGet();
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up magnetometer route", task.getError());
                    } else {
                        magnetometer.magneticField().start();
                        magnetometer.start();
                        synchronized (activeSensors) {
                            activeSensors.add("Magnetometer");
                        }
                        Log.i(TAG, "Magnetometer sensor activated");
                    }
                    return null;
                });
            } else {
                pendingSensorSetups.decrementAndGet();
                Log.w(TAG, "Magnetometer module not available");
            }
        } catch (Exception e) {
            pendingSensorSetups.decrementAndGet();
            Log.e(TAG, "Error setting up magnetometer", e);
        }
    }

    public void setupProximity() {
        try {
            var proximity = board.getModule(ProximityTsl2671.class);
            if (proximity != null) {
                proximity.adc().addRouteAsync(source -> source.stream((data, env) -> {
                    measurementHandler.performMeasurement(MeasurementType.PROXIMITY_ADC, int.class, data);
                })).continueWith(task -> {
                    pendingSensorSetups.decrementAndGet();
                    if (task.isFaulted()) {
                        Log.e(TAG, "Error setting up proximity route", task.getError());
                    } else {
                        synchronized (activeSensors) {
                            activeSensors.add("Proximity Sensor");
                        }
                        Log.i(TAG, "Proximity sensor activated");
                    }
                    return null;
                });
            } else {
                pendingSensorSetups.decrementAndGet();
                Log.w(TAG, "Proximity module not available");
            }
        } catch (Exception e) {
            pendingSensorSetups.decrementAndGet();
            Log.e(TAG, "Error setting up proximity", e);
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
