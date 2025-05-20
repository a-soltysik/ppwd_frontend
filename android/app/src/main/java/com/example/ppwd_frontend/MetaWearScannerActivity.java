package com.example.ppwd_frontend;

import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;

import com.mbientlab.bletoolbox.scanner.BleScannerFragment;
import java.util.UUID;

public class MetaWearScannerActivity extends AppCompatActivity
        implements BleScannerFragment.ScannerCommunicationBus {

    private static final String TAG = "MetaWearScannerActivity";
    public static final String EXTRA_DEVICE_NAME = "device_name";
    public static final String EXTRA_MAC_ADDRESS = "mac_address";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.i(TAG, "Creating MetaWear scanner activity");
        setContentView(R.layout.activity_metawear_scanner);
        
        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle("Select MetaWear Device");
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }
    }

    @Override
    public void onDeviceSelected(BluetoothDevice device) {
        Log.i(TAG, "Device selected: " + device.getName() + " (" + device.getAddress() + ")");
        
        Intent result = new Intent();
        result.putExtra(EXTRA_DEVICE_NAME, device.getName() == null ? "Unknown Device" : device.getName());
        result.putExtra(EXTRA_MAC_ADDRESS, device.getAddress());
        
        setResult(Activity.RESULT_OK, result);
        finish();
    }
    
    @Override
    public UUID[] getFilterServiceUuids() {
        return new UUID[] {
            UUID.fromString("326a9000-85cb-9195-d9dd-464cfbbae75a")
        };
    }

    @Override
    public long getScanDuration() {
        return 10000;
    }
    
    @Override
    public boolean onSupportNavigateUp() {
        setResult(Activity.RESULT_CANCELED);
        finish();
        return true;
    }
    
    @Override
    public void onBackPressed() {
        setResult(Activity.RESULT_CANCELED);
        super.onBackPressed();
    }
}
