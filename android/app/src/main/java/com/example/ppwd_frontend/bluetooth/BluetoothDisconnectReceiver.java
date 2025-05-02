package com.example.ppwd_frontend.bluetooth;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.example.ppwd_frontend.NotificationHelper;

public class BluetoothDisconnectReceiver extends BroadcastReceiver {
    private static final String TAG = "BtDisconnectReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.i(TAG, "Disconnect button pressed");

        new NotificationHelper(context).showAppKilledNotification();

        var serviceIntent = new Intent(context, BluetoothForegroundService.class);
        context.stopService(serviceIntent);

        Intent disconnectIntent = new Intent("com.example.ppwd_frontend.DISCONNECT");
        context.sendBroadcast(disconnectIntent);

        try {
            Thread.sleep(300);
        } catch (InterruptedException ignored) {
        }

        Log.i(TAG, "Killing application process");
        android.os.Process.killProcess(android.os.Process.myPid());
        System.exit(0);
    }
}