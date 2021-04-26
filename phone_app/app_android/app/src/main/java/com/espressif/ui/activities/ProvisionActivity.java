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

import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.widget.ContentLoadingProgressBar;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.provisioning.DeviceConnectionEvent;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.provisioning.listeners.ProvisionListener;
import com.espressif.provisioning.listeners.ResponseListener;
import com.espressif.rainmaker.R;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Param;
import com.espressif.ui.models.Service;
import com.espressif.ui.models.UpdateEvent;
import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.card.MaterialCardView;
import com.google.gson.JsonObject;
import com.google.protobuf.InvalidProtocolBufferException;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.ArrayList;
import java.util.TimeZone;
import java.util.UUID;

import rainmaker.EspRmakerUserMapping;

public class ProvisionActivity extends AppCompatActivity {

    private static final String TAG = ProvisionActivity.class.getSimpleName();

    private static final long ADD_DEVICE_REQ_TIME = 5000;
    private static final long NODE_STATUS_REQ_TIME = 35000;

    private ImageView tick1, tick2, tick3, tick4, tick5;
    private ContentLoadingProgressBar progress1, progress2, progress3, progress4, progress5;
    private TextView tvErrAtStep1, tvErrAtStep2, tvErrAtStep3, tvErrAtStep4, tvErrAtStep5, tvProvError;

    private MaterialCardView btnOk;
    private TextView txtOkBtn;

    private int addDeviceReqCount = 0;
    private String ssidValue, passphraseValue = "";
    private String receivedNodeId, secretKey;

    private ApiManager apiManager;
    private Handler handler;
    private ESPProvisionManager provisionManager;
    private boolean isProvisioningCompleted = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_provision);

        Intent intent = getIntent();
        ssidValue = intent.getStringExtra(AppConstants.KEY_SSID);
        passphraseValue = intent.getStringExtra(AppConstants.KEY_PASSWORD);
        provisionManager = ESPProvisionManager.getInstance(getApplicationContext());

        handler = new Handler();
        apiManager = ApiManager.getInstance(getApplicationContext());
        initViews();

        Log.d(TAG, "Selected AP - " + ssidValue);
        EventBus.getDefault().register(this);
        showLoading();
        doStep1();
    }

    @Override
    public void onBackPressed() {
        provisionManager.getEspDevice().disconnectDevice();
        super.onBackPressed();
    }

    @Override
    protected void onDestroy() {

        apiManager.cancelRequestStatusPollingTask();
        handler.removeCallbacks(getNodeStatusTask);
        handler.removeCallbacks(nodeStatusReqFailed);
        EventBus.getDefault().unregister(this);
        super.onDestroy();
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(UpdateEvent event) {
        Log.d(TAG, "ON UPDATE EVENT RECEIVED : " + event.getEventType());

        switch (event.getEventType()) {

            case EVENT_DEVICE_ADDED:
                doStep5();
                break;

            case EVENT_ADD_DEVICE_TIME_OUT:
                tick4.setImageResource(R.drawable.ic_error);
                tick4.setVisibility(View.VISIBLE);
                progress4.setVisibility(View.GONE);
                tvErrAtStep4.setVisibility(View.VISIBLE);
                tvErrAtStep4.setText(R.string.error_prov_step_4);
                tvProvError.setVisibility(View.VISIBLE);
                break;
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(DeviceConnectionEvent event) {

        Log.d(TAG, "On Device Connection Event RECEIVED : " + event.getEventType());

        switch (event.getEventType()) {

            case ESPConstants.EVENT_DEVICE_DISCONNECTED:
                if (!isFinishing() && !isProvisioningCompleted) {
                    showAlertForDeviceDisconnected();
                }
                break;
        }
    }


    private View.OnClickListener okBtnClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {
            provisionManager.getEspDevice().disconnectDevice();
            finish();
        }
    };

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(false);
        getSupportActionBar().setDisplayShowHomeEnabled(false);
        getSupportActionBar().setTitle(R.string.title_activity_provisioning);

        tick1 = findViewById(R.id.iv_tick_1);
        tick2 = findViewById(R.id.iv_tick_2);
        tick3 = findViewById(R.id.iv_tick_3);
        tick4 = findViewById(R.id.iv_tick_4);
        tick5 = findViewById(R.id.iv_tick_5);

        progress1 = findViewById(R.id.prov_progress_1);
        progress2 = findViewById(R.id.prov_progress_2);
        progress3 = findViewById(R.id.prov_progress_3);
        progress4 = findViewById(R.id.prov_progress_4);
        progress5 = findViewById(R.id.prov_progress_5);

        tvErrAtStep1 = findViewById(R.id.tv_prov_error_1);
        tvErrAtStep2 = findViewById(R.id.tv_prov_error_2);
        tvErrAtStep3 = findViewById(R.id.tv_prov_error_3);
        tvErrAtStep4 = findViewById(R.id.tv_prov_error_4);
        tvErrAtStep5 = findViewById(R.id.tv_prov_error_5);
        tvProvError = findViewById(R.id.tv_prov_error);

        btnOk = findViewById(R.id.btn_ok);
        txtOkBtn = findViewById(R.id.text_btn);
        btnOk.findViewById(R.id.iv_arrow).setVisibility(View.GONE);

        txtOkBtn.setText(R.string.btn_ok);
        btnOk.setOnClickListener(okBtnClickListener);
    }

    private void doStep1() {

        tick1.setVisibility(View.GONE);
        progress1.setVisibility(View.VISIBLE);

        associateDevice();
    }

    private void doStep2() {

        tick1.setImageResource(R.drawable.ic_checkbox_on);
        tick1.setVisibility(View.VISIBLE);
        progress1.setVisibility(View.GONE);
        tick2.setVisibility(View.GONE);
        progress2.setVisibility(View.VISIBLE);
    }

    private void doStep3(boolean isSuccessInStep2) {

        if (isSuccessInStep2) {
            tick2.setImageResource(R.drawable.ic_checkbox_on);
        } else {
            tick2.setImageResource(R.drawable.ic_alert);
        }

        tick2.setVisibility(View.VISIBLE);
        progress2.setVisibility(View.GONE);
        tick3.setVisibility(View.GONE);
        progress3.setVisibility(View.VISIBLE);

        handler.postDelayed(addDeviceTask, ADD_DEVICE_REQ_TIME);
    }

    private void doStep4() {

        hideLoading();
        tick3.setImageResource(R.drawable.ic_checkbox_on);
        tick3.setVisibility(View.VISIBLE);
        progress3.setVisibility(View.GONE);
        tick4.setVisibility(View.GONE);
        progress4.setVisibility(View.VISIBLE);
    }

    private void doStep5() {

        Log.d(TAG, "================= Do step 5 =================");
        Log.d(TAG, "Received node id : " + receivedNodeId);
        tick4.setImageResource(R.drawable.ic_checkbox_on);
        tick4.setVisibility(View.VISIBLE);
        progress4.setVisibility(View.GONE);
        tick5.setVisibility(View.GONE);
        progress5.setVisibility(View.VISIBLE);
        handler.postDelayed(nodeStatusReqFailed, NODE_STATUS_REQ_TIME);

        apiManager.getNodeDetails(receivedNodeId, new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {
                Log.e(TAG, "Get node details - success");
                handler.postDelayed(getNodeStatusTask, 1000);
            }

            @Override
            public void onResponseFailure(Exception exception) {
                Log.e(TAG, "Get node details - failure");
                handler.postDelayed(getNodeStatusTask, 1000);
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                Log.e(TAG, "Get node details - failure");
                handler.postDelayed(getNodeStatusTask, 1000);
            }
        });
    }

    private void provision() {

        Log.d(TAG, "+++++++++++++++++++++++++++++ PROVISION +++++++++++++++++++++++++++++");

        provisionManager.getEspDevice().provision(ssidValue, passphraseValue, new ProvisionListener() {

            @Override
            public void createSessionFailed(Exception e) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Toast.makeText(ProvisionActivity.this, R.string.error_session, Toast.LENGTH_LONG).show();
                    }
                });
            }

            @Override
            public void wifiConfigSent() {
                // Nothing to do here
                Log.d(TAG, "WiFi Config sent");
            }

            @Override
            public void wifiConfigFailed(Exception e) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {

                        tick1.setImageResource(R.drawable.ic_error);
                        tick1.setVisibility(View.VISIBLE);
                        progress1.setVisibility(View.GONE);
                        tvErrAtStep2.setVisibility(View.VISIBLE);
                        tvErrAtStep2.setText(R.string.error_prov_step_2);
                        hideLoading();
                    }
                });

            }

            @Override
            public void wifiConfigApplied() {

                Log.d(TAG, "WiFi Config Applied");
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        doStep2();
                    }
                });
            }

            @Override
            public void wifiConfigApplyFailed(Exception e) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {

                        tick1.setImageResource(R.drawable.ic_error);
                        tick1.setVisibility(View.VISIBLE);
                        progress1.setVisibility(View.GONE);
                        tvErrAtStep2.setVisibility(View.VISIBLE);
                        tvErrAtStep2.setText(R.string.error_prov_step_2);
                        hideLoading();
                    }
                });
            }

            @Override
            public void provisioningFailedFromDevice(final ESPConstants.ProvisionFailureReason failureReason) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {

                        switch (failureReason) {

                            case AUTH_FAILED:
                                tvErrAtStep2.setText(R.string.error_authentication_failed);
                                displayFailureAtStep2();
                                break;

                            case NETWORK_NOT_FOUND:
                                tvErrAtStep2.setText(R.string.error_network_not_found);
                                displayFailureAtStep2();
                                break;

                            case DEVICE_DISCONNECTED:
                                doStep3(false);
                                break;

                            case UNKNOWN:
                                tvErrAtStep2.setText(R.string.error_prov_step_3);
                                displayFailureAtStep2();
                                break;
                        }
                    }
                });
            }

            @Override
            public void deviceProvisioningSuccess() {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        isProvisioningCompleted = true;
                        doStep3(true);
                    }
                });
            }

            @Override
            public void onProvisioningFailed(Exception e) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {

                        doStep3(false);
                    }
                });
            }
        });
    }

    private void displayFailureAtStep2() {

        tick2.setImageResource(R.drawable.ic_error);
        tick2.setVisibility(View.VISIBLE);
        progress2.setVisibility(View.GONE);
        tvErrAtStep2.setVisibility(View.VISIBLE);
        tvProvError.setVisibility(View.VISIBLE);
        hideLoading();
    }

    private void associateDevice() {

        Log.d(TAG, "Associate device");
        final String secretKey = UUID.randomUUID().toString();

        EspRmakerUserMapping.CmdSetUserMapping deviceSecretRequest = EspRmakerUserMapping.CmdSetUserMapping.newBuilder()
                .setUserID(ApiManager.userId)
                .setSecretKey(secretKey)
                .build();
        EspRmakerUserMapping.RMakerConfigMsgType msgType = EspRmakerUserMapping.RMakerConfigMsgType.TypeCmdSetUserMapping;
        EspRmakerUserMapping.RMakerConfigPayload payload = EspRmakerUserMapping.RMakerConfigPayload.newBuilder()
                .setMsg(msgType)
                .setCmdSetUserMapping(deviceSecretRequest)
                .build();

        provisionManager.getEspDevice().sendDataToCustomEndPoint(AppConstants.HANDLER_RM_USER_MAPPING, payload.toByteArray(), new ResponseListener() {

            @Override
            public void onSuccess(byte[] returnData) {

                Log.d(TAG, "Successfully sent user id and secrete key");
                processDetails(returnData, secretKey);
            }

            @Override
            public void onFailure(Exception e) {

                Log.e(TAG, "Send config data : Error : " + e.getMessage());

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {

                        tick1.setImageResource(R.drawable.ic_error);
                        tick1.setVisibility(View.VISIBLE);
                        progress1.setVisibility(View.GONE);
                        tvErrAtStep1.setVisibility(View.VISIBLE);
                        tvErrAtStep1.setText(R.string.error_prov_step_1);
                        hideLoading();
                    }
                });

                e.printStackTrace();
            }
        });
    }

    private void processDetails(byte[] responseData, String secretKey) {

        try {
            EspRmakerUserMapping.RMakerConfigPayload payload = EspRmakerUserMapping.RMakerConfigPayload.parseFrom(responseData);
            EspRmakerUserMapping.RespSetUserMapping response = payload.getRespSetUserMapping();

            if (response.getStatus() == EspRmakerUserMapping.RMakerConfigStatus.Success) {

                receivedNodeId = response.getNodeId();
                this.secretKey = secretKey;

                provision();
            }

        } catch (InvalidProtocolBufferException e) {

            e.printStackTrace();
            runOnUiThread(new Runnable() {

                @Override
                public void run() {

                    tick1.setImageResource(R.drawable.ic_error);
                    tick1.setVisibility(View.VISIBLE);
                    progress1.setVisibility(View.GONE);
                    tvErrAtStep1.setVisibility(View.VISIBLE);
                    tvErrAtStep1.setText(R.string.error_prov_step_1);
                    hideLoading();
                }
            });
        }
    }

    private void addDeviceToCloud(final ApiResponseListener responseListener) {

        Log.d(TAG, "Add device to cloud, count : " + addDeviceReqCount);
        apiManager.addNode(receivedNodeId, secretKey, new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {
                responseListener.onSuccess(null);
            }

            @Override
            public void onResponseFailure(Exception exception) {
                exception.printStackTrace();
                responseListener.onNetworkFailure(exception);
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                exception.printStackTrace();
                responseListener.onNetworkFailure(exception);
            }
        });
    }

    private Runnable addDeviceTask = new Runnable() {

        @Override
        public void run() {

            addDeviceReqCount++;

            addDeviceToCloud(new ApiResponseListener() {

                @Override
                public void onSuccess(Bundle data) {

                    runOnUiThread(new Runnable() {

                        @Override
                        public void run() {
                            doStep4();
                        }
                    });
                }

                @Override
                public void onResponseFailure(Exception exception) {

                    if (addDeviceReqCount == 7) {

                        runOnUiThread(new Runnable() {

                            @Override
                            public void run() {

                                tick3.setImageResource(R.drawable.ic_error);
                                tick3.setVisibility(View.VISIBLE);
                                progress3.setVisibility(View.GONE);
                                tvErrAtStep3.setVisibility(View.VISIBLE);
                                tvErrAtStep3.setText(R.string.error_prov_step_3);
                                tvProvError.setVisibility(View.VISIBLE);
                                hideLoading();
                            }
                        });
                    } else {
                        handler.postDelayed(addDeviceTask, ADD_DEVICE_REQ_TIME);
                    }
                }

                @Override
                public void onNetworkFailure(Exception exception) {

                    if (addDeviceReqCount == 7) {

                        runOnUiThread(new Runnable() {

                            @Override
                            public void run() {

                                tick3.setImageResource(R.drawable.ic_error);
                                tick3.setVisibility(View.VISIBLE);
                                progress3.setVisibility(View.GONE);
                                tvErrAtStep3.setVisibility(View.VISIBLE);
                                tvErrAtStep3.setText(R.string.error_prov_step_3);
                                tvProvError.setVisibility(View.VISIBLE);
                                hideLoading();
                            }
                        });
                    } else {
                        handler.postDelayed(addDeviceTask, ADD_DEVICE_REQ_TIME);
                    }
                }
            });
        }
    };

    private Runnable getNodeStatusTask = new Runnable() {

        @Override
        public void run() {

            if (isFinishing()) {
                return;
            }
            apiManager.getNodeStatus(receivedNodeId, new ApiResponseListener() {

                @Override
                public void onSuccess(Bundle data) {

                    runOnUiThread(new Runnable() {

                        @Override
                        public void run() {
                            EspApplication espApp = (EspApplication) getApplicationContext();
                            EspNode espNode = espApp.nodeMap.get(receivedNodeId);
                            if (espNode != null && espNode.isOnline()) {

                                // Send time zone to device.
                                ArrayList<Service> services = espNode.getServices();
                                boolean isTimeZoneServiceAvailable = false;
                                String paramName = "";

                                for (int i = 0; i < services.size(); i++) {

                                    Service s = services.get(i);
                                    if (!TextUtils.isEmpty(s.getType()) && s.getType().equals(AppConstants.SERVICE_TYPE_TIME)) {

                                        ArrayList<Param> timeParams = s.getParams();
                                        for (int index = 0; index < timeParams.size(); index++) {
                                            if (AppConstants.PARAM_TYPE_TZ.equals(timeParams.get(index).getParamType())) {
                                                isTimeZoneServiceAvailable = true;
                                                paramName = timeParams.get(index).getName();
                                                break;
                                            }
                                        }
                                        if (isTimeZoneServiceAvailable) {
                                            break;
                                        }
                                    }
                                }

                                if (isTimeZoneServiceAvailable) {

                                    Log.e(TAG, "Time zone service is available");
                                    TimeZone tz = TimeZone.getDefault();
                                    String timeZoneId = tz.getID();
                                    Log.e(TAG, "Time zone id : " + timeZoneId);

                                    JsonObject body = new JsonObject();
                                    JsonObject jsonParam = new JsonObject();
                                    jsonParam.addProperty(paramName, timeZoneId);
                                    body.add(AppConstants.KEY_TIME, jsonParam);
                                    apiManager.updateParamValue(espNode.getNodeId(), body, new ApiResponseListener() {

                                        @Override
                                        public void onSuccess(Bundle data) {
                                            tick5.setImageResource(R.drawable.ic_checkbox_on);
                                            tick5.setVisibility(View.VISIBLE);
                                            progress5.setVisibility(View.GONE);
                                            handler.removeCallbacks(nodeStatusReqFailed);
                                        }

                                        @Override
                                        public void onResponseFailure(Exception exception) {
                                            Log.e(TAG, "Failed to send time zone value");
                                            handler.removeCallbacks(getNodeStatusTask);
                                            tick5.setImageResource(R.drawable.ic_alert);
                                            tick5.setVisibility(View.VISIBLE);
                                            progress5.setVisibility(View.GONE);
                                        }

                                        @Override
                                        public void onNetworkFailure(Exception exception) {
                                            Log.e(TAG, "Failed to send time zone value");
                                            handler.removeCallbacks(getNodeStatusTask);
                                            tick5.setImageResource(R.drawable.ic_alert);
                                            tick5.setVisibility(View.VISIBLE);
                                            progress5.setVisibility(View.GONE);
                                        }
                                    });
                                } else {
                                    Log.e(TAG, "Time zone service is not available");
                                    tick5.setImageResource(R.drawable.ic_checkbox_on);
                                    tick5.setVisibility(View.VISIBLE);
                                    progress5.setVisibility(View.GONE);
                                    handler.removeCallbacks(nodeStatusReqFailed);
                                }
                            } else {
                                handler.removeCallbacks(getNodeStatusTask);
                                handler.postDelayed(getNodeStatusTask, 2000);
                            }
                        }
                    });
                }

                @Override
                public void onResponseFailure(Exception exception) {
                    handler.removeCallbacks(getNodeStatusTask);
                    handler.postDelayed(getNodeStatusTask, 2000);
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                    handler.removeCallbacks(getNodeStatusTask);
                    handler.postDelayed(getNodeStatusTask, 2000);
                }
            });
        }
    };

    private Runnable nodeStatusReqFailed = new Runnable() {

        @Override
        public void run() {

            if (isFinishing()) {
                return;
            }
            Log.d(TAG, "Stop node status polling. Timeout");
            handler.removeCallbacks(getNodeStatusTask);
            tick5.setImageResource(R.drawable.ic_alert);
            tick5.setVisibility(View.VISIBLE);
            progress5.setVisibility(View.GONE);
        }
    };

    private void showLoading() {

        btnOk.setEnabled(false);
        btnOk.setAlpha(0.5f);
    }

    public void hideLoading() {

        btnOk.setEnabled(true);
        btnOk.setAlpha(1f);
    }

    private void showAlertForDeviceDisconnected() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(false);
        builder.setTitle(R.string.error_title);
        builder.setMessage(R.string.dialog_msg_ble_device_disconnection);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_ok, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
                finish();
            }
        });
        builder.show();
    }
}
