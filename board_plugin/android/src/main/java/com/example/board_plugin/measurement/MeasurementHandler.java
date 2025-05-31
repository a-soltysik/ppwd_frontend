package com.example.board_plugin.measurement;

import android.util.Log;

import com.mbientlab.metawear.Data;

import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

public class MeasurementHandler {

    private static final String TAG = "MeasurementHandler";
    private static final long dataFetchingPeriodInMillis = 20;
    private final Map<String, List<List<Object>>> sensorDataBuffer = new ConcurrentHashMap<>();

    private static String cleanedUpString(String rawData) {
        final String removeUnitsRegex = "([-+]?[0-9]*\\.?[0-9]+)\\S*(?=[,}])";
        return rawData.replaceAll(removeUnitsRegex, "$1").replaceAll("(\\w+):", "\"$1\":").trim();
    }

    private boolean shouldFetchMeasurement(MeasurementType type) {
        var measurements = sensorDataBuffer.get(type.toString());
        if (measurements != null && !measurements.isEmpty()) {
            List<Object> lastMeasurement = measurements.get(measurements.size() - 1);
            Long lastTimestamp = (Long) lastMeasurement.get(1);

            return (new Date().getTime() - lastTimestamp) > dataFetchingPeriodInMillis;
        }
        return true;
    }

    public <T> void performMeasurement(MeasurementType type, Class<T> sensor, Data data) {
        try {
            if (shouldFetchMeasurement(type)) {
                var measurement = data.value(sensor).toString();
                var timestamp = new Date().getTime();

                sensorDataBuffer.computeIfAbsent(
                        type.toString(),
                        key -> new CopyOnWriteArrayList<>()
                ).add(List.of(cleanedUpString(measurement), timestamp));
            }
        } catch (Exception e) {
            Log.e(TAG, "Error performing measurement for " + type, e);
        }
    }

    public Map<String, List<List<Object>>> getMeasurementsBuffer() {
        return sensorDataBuffer;
    }

    public void clearMeasurements() {
        sensorDataBuffer.clear();
    }

}
