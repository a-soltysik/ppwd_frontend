package com.example.board_plugin;

import androidx.annotation.NonNull;

public enum MeasurementType {
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