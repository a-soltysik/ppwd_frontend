package com.example.board_plugin.measurement;

import androidx.annotation.NonNull;

public enum MeasurementType {
    ACCELERATION("acceleration"),
    ANGULAR_VELOCITY("angularVelocity");

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