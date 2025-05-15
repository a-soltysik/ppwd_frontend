package com.example.board_plugin;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.core.app.NotificationCompat;

public class NotificationHelper {
    // Notification channel IDs
    public static final String FOREGROUND_CHANNEL_ID = "bluetooth_foreground_channel";
    public static final String BATTERY_CHANNEL_ID = "bluetooth_battery_channel";
    public static final String STATUS_CHANNEL_ID = "app_status_channel";
    // Notification IDs
    public static final int FOREGROUND_NOTIFICATION_ID = 1001;
    public static final int BATTERY_NOTIFICATION_ID = 1002;
    public static final int APP_KILLED_NOTIFICATION_ID = 1003;
    public static final int BT_DISCONNECTION_NOTIFICATION_ID = 1004;
    public static final int BATTERY_ALERT_THRESHOLD = 20;
    public static final long BATTERY_NOTIFICATION_MIN_INTERVAL = 1800000; // 30 minutes
    private static final String TAG = "NotificationHelper";
    private final Context context;
    private final NotificationManager notificationManager;
    private final int iconResId;

    public NotificationHelper(Context context, int iconResId) {
        this.context = context;
        this.notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        this.iconResId = iconResId;

        createForegroundChannel();
        createBatteryChannel();
        createStatusChannel();
    }

    private void createForegroundChannel() {
        NotificationChannel channel = new NotificationChannel(
                FOREGROUND_CHANNEL_ID,
                "Bluetooth Foreground Service",
                NotificationManager.IMPORTANCE_LOW);
        channel.setDescription("Used for keeping the Bluetooth connection alive");

        if (notificationManager != null) {
            notificationManager.createNotificationChannel(channel);
        }
    }

    private void createBatteryChannel() {
        NotificationChannel channel = new NotificationChannel(
                BATTERY_CHANNEL_ID,
                "Battery Notifications",
                NotificationManager.IMPORTANCE_HIGH);
        channel.setDescription("Shows alerts when device battery is low");
        channel.enableVibration(true);
        channel.enableLights(true);

        if (notificationManager != null) {
            notificationManager.createNotificationChannel(channel);
        }
    }


    private void createStatusChannel() {
        NotificationChannel channel = new NotificationChannel(
                STATUS_CHANNEL_ID,
                "App Status Notifications",
                NotificationManager.IMPORTANCE_HIGH);
        channel.setDescription("Shows notifications about app status");
        channel.enableVibration(true);
        channel.enableLights(true);

        if (notificationManager != null) {
            notificationManager.createNotificationChannel(channel);
        }
    }

    public Notification createForegroundNotification(String macAddress, int batteryLevel, PendingIntent disconnectPendingIntent) {
        Intent notificationIntent = new Intent();
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0,
                notificationIntent, PendingIntent.FLAG_IMMUTABLE);

        var contentText = "Connected to " + macAddress;
        if (batteryLevel > 0) {
            contentText += " | Battery: " + batteryLevel + "%";

            if (batteryLevel <= BATTERY_ALERT_THRESHOLD) {
                contentText += " ⚠️";
            }
        }

        return new NotificationCompat.Builder(context, FOREGROUND_CHANNEL_ID)
                .setContentTitle("DO NOT, EVER, REMOVE THIS NOTIFICATION")
                .setContentText(contentText)
                .setSmallIcon(iconResId)
                .setContentIntent(pendingIntent)
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Disconnect", disconnectPendingIntent)
                .setOngoing(true)
                .build();
    }

    public void showBatteryLowNotification(int batteryLevel, PendingIntent disconnectPendingIntent) {
        Log.i(TAG, "Showing battery low notification: " + batteryLevel + "%");

        if (notificationManager == null) return;

        Intent notificationIntent = new Intent();
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0,
                notificationIntent, PendingIntent.FLAG_IMMUTABLE);

        Notification notification = new NotificationCompat.Builder(context, BATTERY_CHANNEL_ID)
                .setContentTitle("Battery Low Alert")
                .setContentText("Warning: Battery has fallen below " + batteryLevel + "%. Charge now, if life itself is dear to you!")
                .setSmallIcon(iconResId)
                .setContentIntent(pendingIntent)
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Disconnect", disconnectPendingIntent)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .build();

        notificationManager.notify(BATTERY_NOTIFICATION_ID, notification);
    }

    public void showAppKilledNotification() {
        Log.i(TAG, "Showing app killed notification");

        if (notificationManager == null) return;

        Intent notificationIntent = new Intent();
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0,
                notificationIntent, PendingIntent.FLAG_IMMUTABLE);

        Notification notification = new NotificationCompat.Builder(context, STATUS_CHANNEL_ID)
                .setContentTitle("Connection Terminated")
                .setContentText("Fool! You have killed the app. Restore it quickly, or your phone will be formatted!")
                .setSmallIcon(iconResId)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .build();

        notificationManager.notify(APP_KILLED_NOTIFICATION_ID, notification);
    }

    public void showBluetoothDisconnectionNotification(String reason) {
        Log.i(TAG, "Showing Bluetooth disconnection notification. Reason: " + reason);

        if (notificationManager == null) return;

        Intent notificationIntent = new Intent();
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0,
                notificationIntent, PendingIntent.FLAG_IMMUTABLE);

        Notification notification = new NotificationCompat.Builder(context, STATUS_CHANNEL_ID)
                .setContentTitle("Bluetooth Connection Lost")
                .setContentText("Bluetooth betrayal! Connection lost. Reconnect now!")
                .setStyle(new NotificationCompat.BigTextStyle()
                        .bigText("Betrayed by Bluetooth! Your precious connection has vanished into the digital void. Reconnect now, or forever wander in data darkness!\n\nReason: " + reason))
                .setSmallIcon(iconResId)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ERROR)
                .setAutoCancel(true)
                .build();

        notificationManager.notify(BT_DISCONNECTION_NOTIFICATION_ID, notification);
    }

    public void updateForegroundNotification(String macAddress, int batteryLevel, PendingIntent disconnectPendingIntent) {
        if (notificationManager != null) {
            notificationManager.notify(FOREGROUND_NOTIFICATION_ID,
                    createForegroundNotification(macAddress, batteryLevel, disconnectPendingIntent));
        }
    }

    public long checkAndNotifyLowBattery(int currentBatteryLevel, int previousBatteryLevel, long lastNotificationTime, PendingIntent disconnectPendingIntent) {
        if (currentBatteryLevel <= BATTERY_ALERT_THRESHOLD && currentBatteryLevel > 0) {
            long currentTime = System.currentTimeMillis();

            if (previousBatteryLevel > BATTERY_ALERT_THRESHOLD || currentTime - lastNotificationTime > BATTERY_NOTIFICATION_MIN_INTERVAL) {

                Log.i(TAG, "Battery dropped below alert threshold: " + currentBatteryLevel + "%");
                showBatteryLowNotification(currentBatteryLevel, disconnectPendingIntent);
                return currentTime;
            }
        }

        return lastNotificationTime;
    }
}