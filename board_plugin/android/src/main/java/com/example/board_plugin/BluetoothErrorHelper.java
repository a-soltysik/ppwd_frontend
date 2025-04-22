package com.example.board_plugin;

public class BluetoothErrorHelper {
    public String getBluetoothErrorMessage(Throwable error) {
        if (error == null) return "Unknown connection error";

        String message = error.getMessage();
        if (message == null) return "Connection failed";

        if (message.contains("status (19)")) {
            return "Device not reachable or already connected to another app";
        } else if (message.contains("status (8)")) {
            return "Connection timeout - device might be out of range";
        } else if (message.contains("status (133)")) {
            return "GATT operation failed - try again";
        } else if (message.contains("status (62)")) {
            return "Device is busy - try again later";
        } else if (message.contains("status (1)")) {
            return "Connection failed - unknown error";
        } else if (message.contains("status (22)")) {
            return "Device disconnected";
        } else if (message.contains("status (256)")) {
            return "Connection failed - try again";
        }

        return "Connection failed: " + message;
    }

    public boolean shouldRetryConnection(Throwable error) {
        if (error == null) return false;

        String message = error.getMessage();
        if (message == null) return true;

        // Don't retry for these specific cases
        if (message.contains("INVALID_MAC") ||
                message.contains("Bluetooth is turned off") ||
                message.contains("Bluetooth adapter unavailable")) {
            return false;
        }

        // These are likely temporary issues worth retrying
        if (message.contains("status (19)") || // Connection terminated by peer
                message.contains("status (8)") ||  // Connection timeout
                message.contains("status (133)") || // Could be a temporary gatt failure
                message.contains("status (62)")) {  // Resource busy
            return true;
        }

        // Default to retry for unknown errors
        return true;
    }
}
