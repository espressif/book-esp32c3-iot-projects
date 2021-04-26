// Copyright 2020 Espressif Systems (Shanghai) PTE LTD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.espressif.ui.activities;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.recyclerview.widget.DividerItemDecoration;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.provisioning.DeviceConnectionEvent;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.ESPDevice;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.provisioning.listeners.BleScanListener;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.espressif.ui.adapters.BleDeviceListAdapter;
import com.espressif.ui.models.BleDevice;
import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.card.MaterialCardView;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;

public class BLEProvisionLanding extends AppCompatActivity {

    private static final String TAG = BLEProvisionLanding.class.getSimpleName();

    // Request codes
    private static final int REQUEST_ENABLE_BT = 1;
    private static final int REQUEST_FINE_LOCATION = 2;

    // Time out
    private static final long DEVICE_CONNECT_TIMEOUT = 20000;

    private MaterialCardView btnScan;
    private TextView btnPrefix;
    private TextView txtScanBtn;
    private RecyclerView rvBleDevices;
    private ContentLoadingProgressBar progressBar;
    private RelativeLayout prefixLayout;
    private TextView textPrefix;

    private BleDeviceListAdapter adapter;
    private BluetoothAdapter bleAdapter;
    private ArrayList<BleDevice> deviceList;
    private HashMap<BluetoothDevice, String> bluetoothDevices;
    private Handler handler;

    private int position = -1;
    private boolean isDeviceConnected = false, isConnecting = false;
    private ESPProvisionManager provisionManager;
    private SharedPreferences sharedPreferences;
    private String securityType;
    private boolean isScanning = false;
    private String deviceNamePrefix;

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bleprovision_landing);

        securityType = AppConstants.SECURITY_1;
        if (AppConstants.SECURITY_0.equalsIgnoreCase(BuildConfig.SECURITY)) {
            securityType = AppConstants.SECURITY_0;
        }

        // Use this check to determine whether BLE is supported on the device.  Then you can
        // selectively disable BLE-related features.
        if (!getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            Toast.makeText(this, R.string.error_ble_not_supported, Toast.LENGTH_SHORT).show();
            finish();
        }

        final BluetoothManager bluetoothManager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        bleAdapter = bluetoothManager.getAdapter();

        // Checks if Bluetooth is supported on the device.
        if (bleAdapter == null) {
            Toast.makeText(this, R.string.error_bluetooth_not_supported, Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        isConnecting = false;
        isDeviceConnected = false;
        handler = new Handler();
        bluetoothDevices = new HashMap<>();
        deviceList = new ArrayList<>();

        provisionManager = ESPProvisionManager.getInstance(getApplicationContext());
        sharedPreferences = getSharedPreferences(AppConstants.ESP_PREFERENCES, Context.MODE_PRIVATE);
        if (BuildConfig.isFilterPrefixEditable) {
            deviceNamePrefix = sharedPreferences.getString(AppConstants.KEY_DEVICE_NAME_PREFIX, BuildConfig.DEVICE_NAME_PREFIX);
        } else {
            deviceNamePrefix = BuildConfig.DEVICE_NAME_PREFIX;
        }
        initViews();
        EventBus.getDefault().register(this);
    }

    @Override
    protected void onResume() {
        super.onResume();

        // Ensures Bluetooth is enabled on the device.  If Bluetooth is not currently enabled,
        // fire an intent to display a dialog asking the user to grant permission to enable it.
        if (!bleAdapter.isEnabled()) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        } else {

            if (!isDeviceConnected && !isConnecting) {
                startScan();
            }
        }
    }

    @Override
    public void onBackPressed() {

        if (isScanning) {
            stopScan();
        }
        if (provisionManager.getEspDevice() != null) {
            provisionManager.getEspDevice().disconnectDevice();
        }

        super.onBackPressed();
    }

    @Override
    protected void onDestroy() {
        EventBus.getDefault().unregister(this);
        super.onDestroy();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {

        super.onActivityResult(requestCode, resultCode, data);
        Log.d(TAG, "onActivityResult, requestCode : " + requestCode + ", resultCode : " + resultCode);

        // User chose not to enable Bluetooth.
        if (requestCode == REQUEST_ENABLE_BT && resultCode == Activity.RESULT_CANCELED) {
            finish();
            return;
        }

        if (requestCode == REQUEST_ENABLE_BT && resultCode == RESULT_OK) {
            startScan();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {

        switch (requestCode) {

            case REQUEST_FINE_LOCATION: {
                // If request is cancelled, the result arrays are empty.
                if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    startScan();
                } else if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_DENIED) {
                    finish();
                }
            }
            break;
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(DeviceConnectionEvent event) {

        Log.d(TAG, "ON Device Prov Event RECEIVED : " + event.getEventType());
        handler.removeCallbacks(disconnectDeviceTask);

        switch (event.getEventType()) {

            case ESPConstants.EVENT_DEVICE_CONNECTED:
                Log.e(TAG, "Device Connected Event Received");
                progressBar.setVisibility(View.GONE);
                isConnecting = false;
                isDeviceConnected = true;
                checkDeviceCapabilities();
                break;

            case ESPConstants.EVENT_DEVICE_DISCONNECTED:

                progressBar.setVisibility(View.GONE);
                isConnecting = false;
                isDeviceConnected = false;
                Toast.makeText(BLEProvisionLanding.this, "Device disconnected", Toast.LENGTH_LONG).show();
                break;

            case ESPConstants.EVENT_DEVICE_CONNECTION_FAILED:
                progressBar.setVisibility(View.GONE);
                isConnecting = false;
                isDeviceConnected = false;
                alertForDeviceNotSupported("Failed to connect with device");
                break;
        }
    }

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setTitle(R.string.title_activity_connect_device);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                ESPProvisionManager provisionManager = ESPProvisionManager.getInstance(getApplicationContext());
                provisionManager.getEspDevice().disconnectDevice();
                finish();
            }
        });

        btnScan = findViewById(R.id.btn_scan);
        txtScanBtn = findViewById(R.id.text_btn);
        findViewById(R.id.iv_arrow).setVisibility(View.GONE);
        txtScanBtn.setText(R.string.btn_scan_again);

        rvBleDevices = findViewById(R.id.rv_device_list);
        progressBar = findViewById(R.id.ble_landing_progress_indicator);
        prefixLayout = findViewById(R.id.prefix_layout);
        prefixLayout.setVisibility(View.GONE);

        btnPrefix = findViewById(R.id.btn_change_prefix);
        textPrefix = findViewById(R.id.prefix_value);
        prefixLayout = findViewById(R.id.prefix_layout);
        textPrefix.setText(deviceNamePrefix);

        // Set visibility of Prefix layout
        if (BuildConfig.isFilterPrefixEditable) {
            prefixLayout.setVisibility(View.VISIBLE);
        } else {
            prefixLayout.setVisibility(View.GONE);
        }

        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(getApplicationContext());
        linearLayoutManager.setOrientation(RecyclerView.VERTICAL);
        rvBleDevices.setLayoutManager(linearLayoutManager);
        DividerItemDecoration itemDecor = new DividerItemDecoration(this, DividerItemDecoration.VERTICAL);
        rvBleDevices.addItemDecoration(itemDecor);

        adapter = new BleDeviceListAdapter(this, deviceList);
        rvBleDevices.setAdapter(adapter);

        btnScan.setOnClickListener(btnScanClickListener);
        btnPrefix.setOnClickListener(btnPrefixChangeClickListener);
    }

    private boolean hasPermissions() {

        if (bleAdapter == null || !bleAdapter.isEnabled()) {

            requestBluetoothEnable();
            return false;

        } else if (!hasLocationPermissions()) {

            requestLocationPermission();
            return false;
        }
        return true;
    }

    private void requestBluetoothEnable() {
        Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
        startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        Log.d(TAG, "Requested user enables Bluetooth.");
    }

    private boolean hasLocationPermissions() {
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestLocationPermission() {
        requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, REQUEST_FINE_LOCATION);
    }

    private void startScan() {

        if (!hasPermissions() || isScanning) {
            return;
        }

        isScanning = true;
        deviceList.clear();
        bluetoothDevices.clear();

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            provisionManager.searchBleEspDevices(deviceNamePrefix, bleScanListener);
            updateProgressAndScanBtn();
        } else {
            Log.e(TAG, "Not able to start scan as Location permission is not granted.");
            Toast.makeText(BLEProvisionLanding.this, "Please give location permission to start BLE scan", Toast.LENGTH_LONG).show();
        }
    }

    private void stopScan() {

        isScanning = false;

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            provisionManager.stopBleScan();
            updateProgressAndScanBtn();
        } else {
            Log.e(TAG, "Not able to stop scan as Location permission is not granted.");
            Toast.makeText(BLEProvisionLanding.this, "Please give location permission to stop BLE scan", Toast.LENGTH_LONG).show();
        }

        if (deviceList.size() <= 0) {
            Toast.makeText(BLEProvisionLanding.this, R.string.error_no_ble_device, Toast.LENGTH_SHORT).show();
        }
    }

    /**
     * This method will update UI (Scan button enable / disable and progressbar visibility)
     */
    private void updateProgressAndScanBtn() {

        if (isScanning) {

            btnScan.setEnabled(false);
            btnScan.setAlpha(0.5f);
            progressBar.setVisibility(View.VISIBLE);
            rvBleDevices.setVisibility(View.GONE);

        } else {

            btnScan.setEnabled(true);
            btnScan.setAlpha(1f);
            progressBar.setVisibility(View.GONE);
            rvBleDevices.setVisibility(View.VISIBLE);
        }
    }

    private void alertForDeviceNotSupported(String msg) {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(false);

        builder.setTitle(R.string.error_title);
        builder.setMessage(msg);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_ok, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                finish();
            }
        });

        if (!isFinishing()) {
            builder.show();
        }
    }

    private void checkDeviceCapabilities() {

        ESPDevice espDevice = provisionManager.getEspDevice();
        String versionInfo = espDevice.getVersionInfo();
        ArrayList<String> rmakerCaps = new ArrayList<>();
        ArrayList<String> deviceCaps = espDevice.getDeviceCapabilities();

        try {
            JSONObject jsonObject = new JSONObject(versionInfo);
            JSONObject rmakerInfo = jsonObject.optJSONObject("rmaker");

            if (rmakerInfo != null) {

                JSONArray rmakerCapabilities = rmakerInfo.optJSONArray("cap");
                if (rmakerCapabilities != null) {
                    for (int i = 0; i < rmakerCapabilities.length(); i++) {
                        String cap = rmakerCapabilities.getString(i);
                        rmakerCaps.add(cap);
                    }
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
            Log.d(TAG, "Version Info JSON not available.");
        }

        if (deviceCaps != null && !deviceCaps.contains(AppConstants.CAPABILITY_NO_POP) && AppConstants.SECURITY_1.equalsIgnoreCase(securityType)) {

            goToPopActivity();

        } else if (rmakerCaps.size() > 0 && rmakerCaps.contains(AppConstants.CAPABILITY_CLAIM)) {

            goToClaimingActivity();

        } else if (deviceCaps != null && deviceCaps.contains(AppConstants.CAPABILITY_WIFI_SACN)) {

            goToWifiScanListActivity();

        } else {
            goToWiFiConfigActivity();
        }
    }

    private View.OnClickListener btnScanClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {

            bluetoothDevices.clear();
            adapter.notifyDataSetChanged();
            startScan();
        }
    };

    private BleScanListener bleScanListener = new BleScanListener() {

        @Override
        public void scanStartFailed() {
            Toast.makeText(BLEProvisionLanding.this, "Please turn on Bluetooth to connect BLE device", Toast.LENGTH_SHORT).show();
        }

        @Override
        public void onPeripheralFound(BluetoothDevice device, ScanResult scanResult) {

            Log.d(TAG, "====== onPeripheralFound ===== " + device.getName());
            boolean deviceExists = false;
            String serviceUuid = "";

            if (scanResult.getScanRecord().getServiceUuids() != null && scanResult.getScanRecord().getServiceUuids().size() > 0) {
                serviceUuid = scanResult.getScanRecord().getServiceUuids().get(0).toString();
            }
            Log.d(TAG, "Add service UUID : " + serviceUuid);

            if (bluetoothDevices.containsKey(device)) {
                deviceExists = true;
            }

            if (!deviceExists) {
                BleDevice bleDevice = new BleDevice();
                bleDevice.setName(scanResult.getScanRecord().getDeviceName());
                bleDevice.setBluetoothDevice(device);

                rvBleDevices.setVisibility(View.VISIBLE);
                bluetoothDevices.put(device, serviceUuid);
                deviceList.add(bleDevice);
                adapter.notifyDataSetChanged();
            }
        }

        @Override
        public void scanCompleted() {
            isScanning = false;
            updateProgressAndScanBtn();
        }

        @Override
        public void onFailure(Exception e) {
            Log.e(TAG, e.getMessage());
            e.printStackTrace();
        }
    };

    public void deviceClick(int deviceClickedPosition) {

        stopScan();
        isConnecting = true;
        isDeviceConnected = false;
        btnScan.setVisibility(View.GONE);
        rvBleDevices.setVisibility(View.GONE);
        progressBar.setVisibility(View.VISIBLE);
        this.position = deviceClickedPosition;
        BleDevice bleDevice = deviceList.get(deviceClickedPosition);
        String uuid = bluetoothDevices.get(bleDevice.getBluetoothDevice());
        Log.d(TAG, "=================== Connect to device : " + bleDevice.getName() + " UUID : " + uuid);

        if (ActivityCompat.checkSelfPermission(BLEProvisionLanding.this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {

            boolean isSec1 = true;
            if (AppConstants.SECURITY_0.equalsIgnoreCase(BuildConfig.SECURITY)) {
                isSec1 = false;
            }
            if (isSec1) {
                provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, ESPConstants.SecurityType.SECURITY_1);
            } else {
                provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, ESPConstants.SecurityType.SECURITY_0);
            }

            provisionManager.getEspDevice().connectBLEDevice(bleDevice.getBluetoothDevice(), uuid);
            handler.postDelayed(disconnectDeviceTask, DEVICE_CONNECT_TIMEOUT);
        } else {
            Log.e(TAG, "Not able to connect device as Location permission is not granted.");
            Toast.makeText(BLEProvisionLanding.this, "Please give location permission to connect device", Toast.LENGTH_LONG).show();
        }
    }

    private Runnable disconnectDeviceTask = new Runnable() {

        @Override
        public void run() {

            Log.e(TAG, "Disconnect device");

            // TODO Disconnect device
            progressBar.setVisibility(View.GONE);
            alertForDeviceNotSupported(getString(R.string.error_device_not_supported));
        }
    };

    private View.OnClickListener btnPrefixChangeClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {

            askForPrefix();
        }
    };

    private void askForPrefix() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(true);

        LayoutInflater layoutInflaterAndroid = LayoutInflater.from(this);
        View view = layoutInflaterAndroid.inflate(R.layout.dialog_prefix, null);
        builder.setView(view);
        final EditText etPrefix = view.findViewById(R.id.et_prefix);
        etPrefix.setText(deviceNamePrefix);
        etPrefix.setSelection(etPrefix.getText().length());

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_save, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                String prefix = etPrefix.getText().toString();

                if (prefix != null) {
                    prefix = prefix.trim();
                }

                SharedPreferences.Editor editor = sharedPreferences.edit();
                editor.putString(AppConstants.KEY_DEVICE_NAME_PREFIX, prefix);
                editor.apply();
                deviceNamePrefix = prefix;
                textPrefix.setText(prefix);
                startScan();
            }
        });

        builder.setNegativeButton(R.string.btn_cancel, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {
            }
        });

        builder.show();
    }

    private void goToPopActivity() {
        finish();
        Intent popIntent = new Intent(getApplicationContext(), ProofOfPossessionActivity.class);
        popIntent.putExtra(AppConstants.KEY_DEVICE_NAME, deviceList.get(position).getName());
        popIntent.putExtra(AppConstants.KEY_SSID, getIntent().getStringExtra(AppConstants.KEY_SSID));
        startActivity(popIntent);
    }

    private void goToWifiScanListActivity() {
        finish();
        Intent wifiListIntent = new Intent(getApplicationContext(), WiFiScanActivity.class);
        wifiListIntent.putExtra(AppConstants.KEY_DEVICE_NAME, deviceList.get(position).getName());
        wifiListIntent.putExtra(AppConstants.KEY_SSID, getIntent().getStringExtra(AppConstants.KEY_SSID));
        startActivity(wifiListIntent);
    }

    private void goToWiFiConfigActivity() {
        finish();
        Intent wifiConfigIntent = new Intent(getApplicationContext(), WiFiConfigActivity.class);
        wifiConfigIntent.putExtra(AppConstants.KEY_SSID, getIntent().getStringExtra(AppConstants.KEY_SSID));
        startActivity(wifiConfigIntent);
    }

    private void goToClaimingActivity() {
        finish();
        Intent claimingIntent = new Intent(getApplicationContext(), ClaimingActivity.class);
        claimingIntent.putExtra(AppConstants.KEY_SSID, getIntent().getStringExtra(AppConstants.KEY_SSID));
        startActivity(claimingIntent);
    }
}
