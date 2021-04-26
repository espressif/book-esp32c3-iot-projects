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
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.widget.ContentLoadingProgressBar;

import com.espressif.AppConstants;
import com.espressif.provisioning.DeviceConnectionEvent;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.rainmaker.R;
import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.card.MaterialCardView;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

public class ProvisionLanding extends AppCompatActivity {

    private static final String TAG = ProvisionLanding.class.getSimpleName();

    private static final int REQUEST_FINE_LOCATION = 10;
    private static final int WIFI_SETTINGS_ACTIVITY_REQUEST = 11;

    private MaterialCardView btnConnect;
    private TextView txtConnectBtn;
    private TextView tvConnectDeviceInstruction, tvDeviceName;
    private ContentLoadingProgressBar progressBar;

    private ESPProvisionManager provisionManager;
    private String securityType, deviceName, pop;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_provision_landing);
        securityType = getIntent().getStringExtra(AppConstants.KEY_SECURITY_TYPE);
        deviceName = getIntent().getStringExtra(AppConstants.KEY_DEVICE_NAME);
        pop = getIntent().getStringExtra(AppConstants.KEY_PROOF_OF_POSSESSION);
        provisionManager = ESPProvisionManager.getInstance(getApplicationContext());
        initViews();
        EventBus.getDefault().register(this);
    }

    @Override
    protected void onDestroy() {
        EventBus.getDefault().unregister(this);
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {

        if (provisionManager.getEspDevice() != null) {
            provisionManager.getEspDevice().disconnectDevice();
        }

        super.onBackPressed();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {

        super.onActivityResult(requestCode, resultCode, data);

        switch (requestCode) {
            case WIFI_SETTINGS_ACTIVITY_REQUEST:
                if (hasPermissions()) {
                    connectDevice();
                }
                break;
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {

        switch (requestCode) {

            case REQUEST_FINE_LOCATION:
                // TODO
                break;
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(DeviceConnectionEvent event) {

        Log.d(TAG, "On Device Connection Event RECEIVED : " + event.getEventType());

        switch (event.getEventType()) {

            case ESPConstants.EVENT_DEVICE_CONNECTED:

                Log.e(TAG, "Device Connected Event Received");

                btnConnect.setEnabled(true);
                btnConnect.setAlpha(1f);
                txtConnectBtn.setText(R.string.btn_connect);
                progressBar.setVisibility(View.GONE);

                checkDeviceCapabilities();
                break;

            case ESPConstants.EVENT_DEVICE_CONNECTION_FAILED:

                btnConnect.setEnabled(true);
                btnConnect.setAlpha(1f);
                txtConnectBtn.setText(R.string.btn_connect);
                progressBar.setVisibility(View.GONE);
                Toast.makeText(this, R.string.error_device_connect_failed, Toast.LENGTH_SHORT).show();
                break;
        }
    }

    View.OnClickListener btnConnectClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {

            startActivityForResult(new Intent(Settings.ACTION_WIFI_SETTINGS), WIFI_SETTINGS_ACTIVITY_REQUEST);
        }
    };

    private void connectDevice() {

        btnConnect.setEnabled(false);
        btnConnect.setAlpha(0.5f);
        txtConnectBtn.setText(R.string.btn_connecting);
        progressBar.setVisibility(View.VISIBLE);

        if (ActivityCompat.checkSelfPermission(ProvisionLanding.this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {

            provisionManager.getEspDevice().connectWiFiDevice();
        } else {
            Log.e(TAG, "Not able to connect device as Location permission is not granted.");
            Toast.makeText(ProvisionLanding.this, "Please give location permission to connect device", Toast.LENGTH_LONG).show();
        }
    }

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        getSupportActionBar().setTitle(R.string.title_activity_connect_device);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                if (provisionManager.getEspDevice() != null) {
                    provisionManager.getEspDevice().disconnectDevice();
                }
                finish();
            }
        });

        btnConnect = findViewById(R.id.btn_connect);
        txtConnectBtn = findViewById(R.id.text_btn);
        findViewById(R.id.iv_arrow).setVisibility(View.GONE);
        progressBar = findViewById(R.id.progress_indicator);
        tvConnectDeviceInstruction = findViewById(R.id.tv_connect_device_instruction);
        tvDeviceName = findViewById(R.id.tv_device_name);
        String instruction = getString(R.string.connect_device_instruction_general);

        if (TextUtils.isEmpty(deviceName)) {

            tvConnectDeviceInstruction.setText(instruction);
            tvDeviceName.setVisibility(View.GONE);

        } else {

            instruction = getString(R.string.connect_device_instruction_specific);
            tvConnectDeviceInstruction.setText(instruction);
            tvDeviceName.setVisibility(View.VISIBLE);
            tvDeviceName.setText(deviceName);
        }

        txtConnectBtn.setText(R.string.btn_connect);
        btnConnect.setOnClickListener(btnConnectClickListener);
        hasPermissions();
    }

    private void checkDeviceCapabilities() {

        ArrayList<String> deviceCaps = provisionManager.getEspDevice().getDeviceCapabilities();
        String versionInfo = provisionManager.getEspDevice().getVersionInfo();
        ArrayList<String> rmakerCaps = new ArrayList<>();

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

        if (rmakerCaps.size() > 0 && rmakerCaps.contains(AppConstants.CAPABILITY_CLAIM)) {

            // Claiming is not supported for SoftAP transport.
            alertForClaimingNotSupported();

        } else {

            if (!TextUtils.isEmpty(pop)) {

                provisionManager.getEspDevice().setProofOfPossession(pop);

                if (deviceCaps != null && deviceCaps.contains(AppConstants.CAPABILITY_WIFI_SACN)) {

                    goToWifiScanListActivity();

                } else {

                    goToWiFiConfigActivity();
                }

            } else {

                if (deviceCaps != null && !deviceCaps.contains(AppConstants.CAPABILITY_NO_POP) && AppConstants.SECURITY_1.equalsIgnoreCase(securityType)) {

                    goToPopActivity();

                } else if (deviceCaps != null && deviceCaps.contains(AppConstants.CAPABILITY_WIFI_SACN)) {

                    goToWifiScanListActivity();

                } else {

                    goToWiFiConfigActivity();
                }
            }
        }
    }

    private void goToPopActivity() {

        finish();
        Intent popIntent = new Intent(getApplicationContext(), ProofOfPossessionActivity.class);
        popIntent.putExtra(AppConstants.KEY_SSID, getIntent().getStringExtra(AppConstants.KEY_SSID));
        startActivity(popIntent);
    }

    private void goToWifiScanListActivity() {

        finish();
        Intent wifiListIntent = new Intent(getApplicationContext(), WiFiScanActivity.class);
        wifiListIntent.putExtra(AppConstants.KEY_SSID, getIntent().getStringExtra(AppConstants.KEY_SSID));
        startActivity(wifiListIntent);
    }

    private void goToWiFiConfigActivity() {

        finish();
        Intent wifiConfigIntent = new Intent(getApplicationContext(), WiFiConfigActivity.class);
        wifiConfigIntent.putExtra(AppConstants.KEY_SSID, getIntent().getStringExtra(AppConstants.KEY_SSID));
        startActivity(wifiConfigIntent);
    }

    private boolean hasPermissions() {

        if (!hasLocationPermissions()) {

            requestLocationPermission();
            return false;
        }
        return true;
    }

    private boolean hasLocationPermissions() {
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestLocationPermission() {
        requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, REQUEST_FINE_LOCATION);
    }

    private void alertForClaimingNotSupported() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(false);
        builder.setMessage(R.string.error_claiming_not_supported);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_ok, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                if (provisionManager.getEspDevice() != null) {
                    provisionManager.getEspDevice().disconnectDevice();
                }
                dialog.dismiss();
                finish();
            }
        });

        builder.show();
    }
}
