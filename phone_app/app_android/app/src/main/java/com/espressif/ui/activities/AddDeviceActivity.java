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
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.wifi.SupplicantState;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Vibrator;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;

import com.budiyev.android.codescanner.CodeScanner;
import com.budiyev.android.codescanner.CodeScannerView;
import com.espressif.AppConstants;
import com.espressif.provisioning.DeviceConnectionEvent;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.ESPDevice;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.provisioning.listeners.QRCodeScanListener;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.card.MaterialCardView;
import com.wang.avi.AVLoadingIndicatorView;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

public class AddDeviceActivity extends AppCompatActivity {

    private static final String TAG = AddDeviceActivity.class.getSimpleName();

    private static final int REQUEST_CAMERA_PERMISSION = 1;
    private static final int REQUEST_ACCESS_FINE_LOCATION = 2;

    private CodeScanner codeScanner;
    //    private CameraSourcePreview cameraPreview;
    private MaterialCardView btnAddManually, btnGetPermission;
    private TextView txtAddManuallyBtn;
    private AVLoadingIndicatorView loader;
    private LinearLayout layoutQrCode, layoutPermissionErr;
    private TextView tvPermissionErr;
    private ImageView ivPermissionErr;

    private ESPDevice espDevice;
    private ESPProvisionManager provisionManager;
    private boolean isQrCodeDataReceived = false;
    private String connectedNetwork;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_device);
        provisionManager = ESPProvisionManager.getInstance(getApplicationContext());
        initViews();
        EventBus.getDefault().register(this);
        connectedNetwork = getWifiSsid();
    }

    @Override
    protected void onResume() {
        super.onResume();

//            if (cameraPreview != null) {
//                try {
//                    cameraPreview.start();
//                } catch (IOException e) {
//                    e.printStackTrace();
//                }
//            }

        if (codeScanner != null && !isQrCodeDataReceived) {
            codeScanner.startPreview();
        }
    }

    /**
     * Stops the camera.
     */
    @Override
    protected void onPause() {
        //        if (cameraPreview != null) {
//            cameraPreview.stop();
//        }
        if (codeScanner != null) {
            codeScanner.releaseResources();
        }
        super.onPause();
    }

    @Override
    protected void onDestroy() {

        hideLoading();
        EventBus.getDefault().unregister(this);
//        if (cameraPreview != null) {
//            cameraPreview.release();
//        }
//        if (codeScanner != null) {
//            codeScanner.releaseResources();
//        }
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
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        Log.e(TAG, "onRequestPermissionsResult , requestCode : " + requestCode);

        if (requestCode == REQUEST_CAMERA_PERMISSION && grantResults.length > 0) {
            if (grantResults[0] == PackageManager.PERMISSION_DENIED) {
                findViewById(R.id.scanner_view).setVisibility(View.GONE);
                layoutQrCode.setVisibility(View.GONE);
                layoutPermissionErr.setVisibility(View.VISIBLE);
                tvPermissionErr.setText(R.string.error_camera_permission);
                ivPermissionErr.setImageResource(R.drawable.ic_no_camera_permission);
            } else {
                layoutQrCode.setVisibility(View.VISIBLE);
                layoutPermissionErr.setVisibility(View.GONE);
                openCamera();
            }
        } else if (requestCode == REQUEST_ACCESS_FINE_LOCATION && grantResults.length > 0) {
            if (grantResults[0] == PackageManager.PERMISSION_DENIED) {
                findViewById(R.id.scanner_view).setVisibility(View.GONE);
                layoutQrCode.setVisibility(View.GONE);
                layoutPermissionErr.setVisibility(View.VISIBLE);
                tvPermissionErr.setText(R.string.error_location_permission);
                ivPermissionErr.setImageResource(R.drawable.ic_no_location_permission);
            } else {
                findViewById(R.id.scanner_view).setVisibility(View.VISIBLE);
                layoutQrCode.setVisibility(View.VISIBLE);
                layoutPermissionErr.setVisibility(View.GONE);
                scanQrCode();
            }
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(DeviceConnectionEvent event) {

        Log.d(TAG, "On Device Connection Event RECEIVED : " + event.getEventType());

        switch (event.getEventType()) {

            case ESPConstants.EVENT_DEVICE_CONNECTED:
                Log.e(TAG, "Device Connected Event Received");
                checkDeviceCapabilities();
                break;

            case ESPConstants.EVENT_DEVICE_DISCONNECTED:
            case ESPConstants.EVENT_DEVICE_CONNECTION_FAILED:
                askForManualDeviceConnection();
                break;
        }
    }

    View.OnClickListener btnAddManuallyClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {

            boolean isSec1 = true;
            if (AppConstants.SECURITY_0.equalsIgnoreCase(BuildConfig.SECURITY)) {
                isSec1 = false;
            }

            if (AppConstants.TRANSPORT_SOFTAP.equalsIgnoreCase(BuildConfig.TRANSPORT)) {

                if (isSec1) {
                    provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_SOFTAP, ESPConstants.SecurityType.SECURITY_1);
                } else {
                    provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_SOFTAP, ESPConstants.SecurityType.SECURITY_0);
                }
                goToWiFiProvisionLanding(isSec1);

            } else if (AppConstants.TRANSPORT_BLE.equalsIgnoreCase(BuildConfig.TRANSPORT)) {

                if (isSec1) {
                    provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, ESPConstants.SecurityType.SECURITY_1);
                } else {
                    provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, ESPConstants.SecurityType.SECURITY_0);
                }
                goToBLEProvisionLanding(isSec1);

            } else if (AppConstants.TRANSPORT_BOTH.equalsIgnoreCase(BuildConfig.TRANSPORT)) {

                askForDeviceType(isSec1);

            } else {
                Toast.makeText(AddDeviceActivity.this, R.string.error_device_type_not_supported, Toast.LENGTH_LONG).show();
            }
        }
    };

    View.OnClickListener btnGetPermissionClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {
            if (ActivityCompat.checkSelfPermission(AddDeviceActivity.this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {

                ActivityCompat.requestPermissions(AddDeviceActivity.this, new
                        String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA_PERMISSION);

            } else if (ActivityCompat.checkSelfPermission(AddDeviceActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {

                ActivityCompat.requestPermissions(AddDeviceActivity.this, new
                        String[]{Manifest.permission.ACCESS_FINE_LOCATION}, REQUEST_ACCESS_FINE_LOCATION);
            }
        }
    };

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        getSupportActionBar().setTitle(R.string.title_activity_add_device);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (provisionManager.getEspDevice() != null) {
                    provisionManager.getEspDevice().disconnectDevice();
                }
                setResult(RESULT_CANCELED, getIntent());
                finish();
            }
        });

        CodeScannerView scannerView = findViewById(R.id.scanner_view);
        codeScanner = new CodeScanner(this, scannerView);

//        cameraPreview = findViewById(R.id.preview);
        loader = findViewById(R.id.loader);
        layoutQrCode = findViewById(R.id.layout_qr_code_txt);
        layoutPermissionErr = findViewById(R.id.layout_permission_error);
        tvPermissionErr = findViewById(R.id.tv_permission_error);
        ivPermissionErr = findViewById(R.id.iv_permission_error);

        btnAddManually = findViewById(R.id.btn_add_device_manually);
        txtAddManuallyBtn = btnAddManually.findViewById(R.id.text_btn);
        txtAddManuallyBtn.setText(R.string.btn_no_qr_code);
        btnAddManually.setOnClickListener(btnAddManuallyClickListener);

        btnGetPermission = findViewById(R.id.btn_get_permission);
        TextView btnPermissionText = btnGetPermission.findViewById(R.id.text_btn);
        btnPermissionText.setText(R.string.btn_get_permission);
        btnGetPermission.setOnClickListener(btnGetPermissionClickListener);

        if (ActivityCompat.checkSelfPermission(AddDeviceActivity.this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            openCamera();
        } else {
            ActivityCompat.requestPermissions(AddDeviceActivity.this, new
                    String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA_PERMISSION);
        }
    }

    private void openCamera() {
        findViewById(R.id.scanner_view).setVisibility(View.VISIBLE);
        if (codeScanner != null) {
            codeScanner.startPreview();
        }
        scanQrCode();
    }

    private void scanQrCode() {

        if (ActivityCompat.checkSelfPermission(AddDeviceActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            provisionManager.scanQRCode(codeScanner, qrCodeScanListener);
        } else {
            ActivityCompat.requestPermissions(AddDeviceActivity.this, new
                    String[]{Manifest.permission.ACCESS_FINE_LOCATION}, REQUEST_ACCESS_FINE_LOCATION);
        }
    }

    private void askForDeviceType(final boolean isSec1) {

        final String[] deviceTypes = getResources().getStringArray(R.array.prov_transport_types);
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(true);
        builder.setTitle(R.string.dialog_msg_device_selection);

        builder.setItems(deviceTypes, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int position) {

                switch (position) {
                    case 0:
                        if (isSec1) {
                            provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, ESPConstants.SecurityType.SECURITY_1);
                        } else {
                            provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, ESPConstants.SecurityType.SECURITY_0);
                        }
                        goToBLEProvisionLanding(isSec1);
                        break;

                    case 1:
                        if (isSec1) {
                            provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_SOFTAP, ESPConstants.SecurityType.SECURITY_1);
                        } else {
                            provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_SOFTAP, ESPConstants.SecurityType.SECURITY_0);
                        }
                        goToWiFiProvisionLanding(isSec1);
                        break;
                }
                dialog.dismiss();
            }
        });
        builder.show();
    }

    private void showLoading() {
        loader.setVisibility(View.VISIBLE);
        loader.show();
    }

    private void hideLoading() {
        loader.hide();
    }

    private QRCodeScanListener qrCodeScanListener = new QRCodeScanListener() {

        @Override
        public void qrCodeScanned() {

            runOnUiThread(new Runnable() {

                @Override
                public void run() {
                    showLoading();
                    Vibrator vib = (Vibrator) getSystemService(VIBRATOR_SERVICE);
                    vib.vibrate(50);
                    isQrCodeDataReceived = true;
                }
            });
        }

        @Override
        public void deviceDetected(final ESPDevice device) {

            Log.e(TAG, "Device detected");
            espDevice = device;

            runOnUiThread(new Runnable() {

                @Override
                public void run() {

                    if (ActivityCompat.checkSelfPermission(AddDeviceActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                        Log.e(TAG, "Location Permission not granted.");
                        return;
                    }

                    if (espDevice.getTransportType().equals(ESPConstants.TransportType.TRANSPORT_SOFTAP)
                            && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {

                        WifiManager wifiManager = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);

                        if (!wifiManager.isWifiEnabled()) {
                            alertForWiFi();
                            return;
                        }
                    }
                    device.connectToDevice();
                }
            });
        }

        @Override
        public void onFailure(final Exception e) {

            Log.e(TAG, "Error : " + e.getMessage());

            runOnUiThread(new Runnable() {

                @Override
                public void run() {
                    hideLoading();
                    Toast.makeText(AddDeviceActivity.this, e.getMessage(), Toast.LENGTH_LONG).show();
                    finish();
                }
            });
        }
    };

    private void checkDeviceCapabilities() {

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

        if (rmakerCaps.size() > 0 && rmakerCaps.contains(AppConstants.CAPABILITY_CLAIM)) {

            if (espDevice.getTransportType().equals(ESPConstants.TransportType.TRANSPORT_BLE)) {
                goToClaimingActivity();
            } else {
                alertForClaimingNotSupported();
            }
        } else {

            if (deviceCaps.contains(AppConstants.CAPABILITY_WIFI_SACN)) {
                goToWiFiScanActivity();
            } else {
                goToWiFiConfigActivity();
            }
        }
    }

    private void alertForWiFi() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(false);
        builder.setMessage(R.string.error_wifi_off);

        builder.setPositiveButton(R.string.btn_ok, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
                espDevice = null;
                hideLoading();

                if (codeScanner != null) {

                    codeScanner.releaseResources();
                    codeScanner.startPreview();

                    if (ActivityCompat.checkSelfPermission(AddDeviceActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                            && ActivityCompat.checkSelfPermission(AddDeviceActivity.this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {

                        provisionManager.scanQRCode(codeScanner, qrCodeScanListener);
                    }
                }
            }
        });

        builder.show();
    }

    private void alertForClaimingNotSupported() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(false);
        builder.setMessage(R.string.error_claiming_not_supported);

        builder.setPositiveButton(R.string.btn_ok, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                if (provisionManager.getEspDevice() != null) {
                    provisionManager.getEspDevice().disconnectDevice();
                }
                dialog.dismiss();
                espDevice = null;
                hideLoading();
                finish();
            }
        });

        builder.show();
    }

    private void goToBLEProvisionLanding(boolean isSec1) {

        finish();
        Intent intent = new Intent(getApplicationContext(), BLEProvisionLanding.class);
        if (isSec1) {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_1);
        } else {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_0);
        }

        if (espDevice != null) {
            intent.putExtra(AppConstants.KEY_DEVICE_NAME, espDevice.getDeviceName());
            intent.putExtra(AppConstants.KEY_PROOF_OF_POSSESSION, espDevice.getProofOfPossession());
            intent.putExtra(AppConstants.KEY_SSID, connectedNetwork);
        }
        startActivity(intent);
    }

    private void goToWiFiProvisionLanding(boolean isSec1) {

        finish();
        Intent intent = new Intent(getApplicationContext(), ProvisionLanding.class);
        if (isSec1) {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_1);
        } else {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_0);
        }

        if (espDevice != null) {
            intent.putExtra(AppConstants.KEY_DEVICE_NAME, espDevice.getDeviceName());
            intent.putExtra(AppConstants.KEY_PROOF_OF_POSSESSION, espDevice.getProofOfPossession());
            intent.putExtra(AppConstants.KEY_SSID, connectedNetwork);
        }
        startActivity(intent);
    }

    private void goToWiFiScanActivity() {
        finish();
        Intent wifiListIntent = new Intent(getApplicationContext(), WiFiScanActivity.class);
        wifiListIntent.putExtra(AppConstants.KEY_SSID, connectedNetwork);
        startActivity(wifiListIntent);
    }

    private void goToWiFiConfigActivity() {
        finish();
        Intent wifiConfigIntent = new Intent(getApplicationContext(), WiFiConfigActivity.class);
        wifiConfigIntent.putExtra(AppConstants.KEY_SSID, connectedNetwork);
        startActivity(wifiConfigIntent);
    }

    private void goToClaimingActivity() {
        finish();
        Intent claimingIntent = new Intent(getApplicationContext(), ClaimingActivity.class);
        claimingIntent.putExtra(AppConstants.KEY_SSID, connectedNetwork);
        startActivity(claimingIntent);
    }

    private void askForManualDeviceConnection() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(true);
        builder.setMessage(R.string.dialog_msg_connect_device_manually);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_yes, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
                if (espDevice != null) {
                    if (espDevice.getTransportType().equals(ESPConstants.TransportType.TRANSPORT_SOFTAP)) {
                        if (espDevice.getSecurityType().equals(ESPConstants.SecurityType.SECURITY_0)) {
                            goToWiFiProvisionLanding(false);
                        } else {
                            goToWiFiProvisionLanding(true);
                        }
                    } else {
                        if (espDevice.getSecurityType().equals(ESPConstants.SecurityType.SECURITY_0)) {
                            goToBLEProvisionLanding(false);
                        } else {
                            goToBLEProvisionLanding(true);
                        }
                    }
                } else {
                    finish();
                }
            }
        });

        builder.setNegativeButton(R.string.btn_cancel, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
                finish();
            }
        });

        AlertDialog alertDialog = builder.create();
        if (!isFinishing()) {
            alertDialog.show();
        }
    }

    private String getWifiSsid() {

        String ssid = null;
        WifiManager wifiManager = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        WifiInfo wifiInfo = wifiManager.getConnectionInfo();
        if (wifiInfo.getSupplicantState() == SupplicantState.COMPLETED) {

            ssid = wifiInfo.getSSID();
            ssid = ssid.replace("\"", "");
        }
        return ssid;
    }
}
