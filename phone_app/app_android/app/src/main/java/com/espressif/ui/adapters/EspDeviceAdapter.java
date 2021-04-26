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

package com.espressif.ui.adapters;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.aar.tapholdupbutton.TapHoldUpButton;
import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.NetworkApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.local_control.EspLocalDevice;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.EspDeviceActivity;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Param;
import com.google.gson.JsonObject;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;

public class EspDeviceAdapter extends RecyclerView.Adapter<EspDeviceAdapter.DeviceViewHolder> {

    private Context context;
    private NetworkApiManager networkApiManager;
    private ArrayList<Device> deviceList;

    public EspDeviceAdapter(Context context, ArrayList<Device> deviceList) {
        this.context = context;
        this.deviceList = deviceList;
        networkApiManager = new NetworkApiManager(context.getApplicationContext());
    }

    @Override
    public DeviceViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_esp_device, parent, false);
        DeviceViewHolder vh = new DeviceViewHolder(v);
        return vh;
    }

    @Override
    public void onBindViewHolder(@NonNull final DeviceViewHolder deviceVh, final int position) {

        final Device device = deviceList.get(position);
        EspApplication espApp = (EspApplication) context.getApplicationContext();
        EspNode node = espApp.nodeMap.get(device.getNodeId());

        // set the data in items
        deviceVh.tvDeviceName.setText(device.getUserVisibleName());

        if (TextUtils.isEmpty(device.getDeviceType())) {

            deviceVh.ivDevice.setImageResource(R.drawable.ic_device);

        } else {

            if (AppConstants.ESP_DEVICE_BULB.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device_bulb);

            } else if (AppConstants.ESP_DEVICE_BULB_CCT.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device_bulb_cct);

            } else if (AppConstants.ESP_DEVICE_BULB_RGB.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device_bulb_rgb);

            } else if (AppConstants.ESP_DEVICE_SWITCH.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device_switch);

            } else if (AppConstants.ESP_DEVICE_LOCK.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device_lock);

            } else if (AppConstants.ESP_DEVICE_THERMOSTAT.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device_thermostat);

            } else if (AppConstants.ESP_DEVICE_FAN.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device_fan);

            } else if (AppConstants.ESP_DEVICE_SENSOR.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device);

            } else if (AppConstants.ESP_DEVICE_TEMP_SENSOR.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device_temp_sensor);

            } else if (AppConstants.ESP_DEVICE_OUTLET.equals(device.getDeviceType())) {

                deviceVh.ivDevice.setImageResource(R.drawable.ic_device_outlet);

            } else {
                deviceVh.ivDevice.setImageResource(R.drawable.ic_device);
            }
        }

        if (!TextUtils.isEmpty(device.getPrimaryParamName())) {

            String paramName = device.getPrimaryParamName();
            boolean isParamFound = false;
            int paramIndex = -1;

            for (int i = 0; i < device.getParams().size(); i++) {

                Param p = device.getParams().get(i);
                if (p != null && paramName.equals(p.getName())) {
                    isParamFound = true;
                    paramIndex = i;
                    break;
                }
            }

            if (isParamFound) {

                final Param param = device.getParams().get(paramIndex);
                String dataType = param.getDataType();

                if (TextUtils.isEmpty(dataType)) {

                    deviceVh.ivDeviceStatus.setVisibility(View.GONE);
                    deviceVh.tvStringValue.setVisibility(View.GONE);
                    deviceVh.btnTrigger.setVisibility(View.GONE);

                } else if (AppConstants.UI_TYPE_TOGGLE.equalsIgnoreCase(param.getUiType())) {

                    deviceVh.ivDeviceStatus.setVisibility(View.VISIBLE);
                    deviceVh.tvStringValue.setVisibility(View.GONE);
                    deviceVh.btnTrigger.setVisibility(View.GONE);

                    final boolean isOn = param.getSwitchStatus();

                    if (isOn) {
                        deviceVh.ivDeviceStatus.setImageResource(R.drawable.ic_output_on);
                    } else {
                        deviceVh.ivDeviceStatus.setImageResource(R.drawable.ic_output_off);
                    }

                    if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

                        deviceVh.ivDeviceStatus.setOnClickListener(new View.OnClickListener() {

                            @Override
                            public void onClick(View v) {

                                final boolean status = param.getSwitchStatus();

                                if (status) {
                                    deviceVh.ivDeviceStatus.setImageResource(R.drawable.ic_output_off);
                                } else {
                                    deviceVh.ivDeviceStatus.setImageResource(R.drawable.ic_output_on);
                                }

                                JsonObject jsonParam = new JsonObject();
                                JsonObject body = new JsonObject();

                                jsonParam.addProperty(param.getName(), !status);
                                body.add(device.getDeviceName(), jsonParam);

                                networkApiManager.updateParamValue(device.getNodeId(), body, new ApiResponseListener() {

                                    @Override
                                    public void onSuccess(Bundle data) {
                                        param.setSwitchStatus(!status);
                                    }

                                    @Override
                                    public void onResponseFailure(Exception exception) {
                                        Toast.makeText(context, R.string.error_param_update, Toast.LENGTH_SHORT).show();
                                    }

                                    @Override
                                    public void onNetworkFailure(Exception exception) {
                                        Toast.makeText(context, R.string.error_param_update, Toast.LENGTH_SHORT).show();
                                    }
                                });
                            }
                        });
                    }

                } else if (AppConstants.UI_TYPE_TRIGGER.equalsIgnoreCase(param.getUiType())) {

                    deviceVh.ivDeviceStatus.setVisibility(View.GONE);
                    deviceVh.tvStringValue.setVisibility(View.GONE);
                    deviceVh.btnTrigger.setVisibility(View.VISIBLE);

                    if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

                        deviceVh.btnTrigger.setAlpha(1f);
                        deviceVh.btnTrigger.setEnabled(true);
                        deviceVh.btnTrigger.setClickable(true);
                        deviceVh.btnTrigger.enableLongHold(true);
                        deviceVh.btnTrigger.setOnButtonClickListener(new TapHoldUpButton.OnButtonClickListener() {

                            @Override
                            public void onLongHoldStart(View v) {
                            }

                            @Override
                            public void onLongHoldEnd(View v) {
                                JsonObject jsonParam = new JsonObject();
                                JsonObject body = new JsonObject();

                                jsonParam.addProperty(param.getName(), true);
                                body.add(device.getDeviceName(), jsonParam);

                                networkApiManager.updateParamValue(device.getNodeId(), body, new ApiResponseListener() {

                                    @Override
                                    public void onSuccess(Bundle data) {
                                    }

                                    @Override
                                    public void onResponseFailure(Exception exception) {
                                        Toast.makeText(context, R.string.error_param_update, Toast.LENGTH_SHORT).show();
                                    }

                                    @Override
                                    public void onNetworkFailure(Exception exception) {
                                        Toast.makeText(context, R.string.error_param_update, Toast.LENGTH_SHORT).show();
                                    }
                                });
                            }

                            @Override
                            public void onClick(View v) {
                                JsonObject jsonParam = new JsonObject();
                                JsonObject body = new JsonObject();

                                jsonParam.addProperty(param.getName(), true);
                                body.add(device.getDeviceName(), jsonParam);

                                networkApiManager.updateParamValue(device.getNodeId(), body, new ApiResponseListener() {

                                    @Override
                                    public void onSuccess(Bundle data) {
                                    }

                                    @Override
                                    public void onResponseFailure(Exception exception) {
                                        Toast.makeText(context, R.string.error_param_update, Toast.LENGTH_SHORT).show();
                                    }

                                    @Override
                                    public void onNetworkFailure(Exception exception) {
                                        Toast.makeText(context, R.string.error_param_update, Toast.LENGTH_SHORT).show();
                                    }
                                });
                            }
                        });
                    } else {
                        deviceVh.btnTrigger.setEnabled(false);
                        deviceVh.btnTrigger.setOnButtonClickListener(null);
                    }

                } else if (dataType.equalsIgnoreCase("bool") || dataType.equalsIgnoreCase("boolean")) {

                    deviceVh.ivDeviceStatus.setVisibility(View.VISIBLE);
                    deviceVh.tvStringValue.setVisibility(View.GONE);
                    deviceVh.btnTrigger.setVisibility(View.GONE);

                    String value = param.getLabelValue();
                    boolean isOn = false;

                    if (value != null && value.equalsIgnoreCase("true")) {
                        isOn = true;
                    }

                    if (isOn) {
                        deviceVh.ivDeviceStatus.setImageResource(R.drawable.ic_output_on);
                    } else {
                        deviceVh.ivDeviceStatus.setImageResource(R.drawable.ic_output_off);
                    }

                    if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

                        deviceVh.ivDeviceStatus.setOnClickListener(new View.OnClickListener() {

                            @Override
                            public void onClick(View v) {

                                String value = param.getLabelValue();
                                boolean finalIsOn = false;

                                if (value != null && value.equalsIgnoreCase("true")) {
                                    finalIsOn = true;
                                }

                                JsonObject jsonParam = new JsonObject();
                                JsonObject body = new JsonObject();

                                jsonParam.addProperty(param.getName(), !finalIsOn);
                                body.add(device.getDeviceName(), jsonParam);

                                final boolean finalIsOn1 = finalIsOn;
                                networkApiManager.updateParamValue(device.getNodeId(), body, new ApiResponseListener() {

                                    @Override
                                    public void onSuccess(Bundle data) {

                                        if (finalIsOn1) {
                                            deviceVh.ivDeviceStatus.setImageResource(R.drawable.ic_output_off);
                                            param.setLabelValue("false");
                                        } else {
                                            deviceVh.ivDeviceStatus.setImageResource(R.drawable.ic_output_on);
                                            param.setLabelValue("true");
                                        }
                                    }

                                    @Override
                                    public void onResponseFailure(Exception exception) {
                                        Toast.makeText(context, R.string.error_param_update, Toast.LENGTH_SHORT).show();
                                    }

                                    @Override
                                    public void onNetworkFailure(Exception exception) {
                                        Toast.makeText(context, R.string.error_param_update, Toast.LENGTH_SHORT).show();
                                    }
                                });
                            }
                        });
                    }

                } else if (dataType.equalsIgnoreCase("int") || dataType.equalsIgnoreCase("integer")) {

                    deviceVh.ivDeviceStatus.setVisibility(View.GONE);
                    deviceVh.btnTrigger.setVisibility(View.GONE);
                    deviceVh.tvStringValue.setVisibility(View.VISIBLE);
                    deviceVh.tvStringValue.setText(param.getLabelValue());

                } else if (dataType.equalsIgnoreCase("float") || dataType.equalsIgnoreCase("double")) {

                    deviceVh.ivDeviceStatus.setVisibility(View.GONE);
                    deviceVh.btnTrigger.setVisibility(View.GONE);
                    deviceVh.tvStringValue.setVisibility(View.VISIBLE);
                    deviceVh.tvStringValue.setText(param.getLabelValue());

                } else if (dataType.equalsIgnoreCase("string")) {

                    deviceVh.ivDeviceStatus.setVisibility(View.GONE);
                    deviceVh.btnTrigger.setVisibility(View.GONE);
                    deviceVh.tvStringValue.setVisibility(View.VISIBLE);
                    deviceVh.tvStringValue.setText(param.getLabelValue());
                }
            } else {
                deviceVh.btnTrigger.setVisibility(View.GONE);
                deviceVh.ivDeviceStatus.setVisibility(View.GONE);
                deviceVh.tvStringValue.setVisibility(View.GONE);
            }
        } else {
            deviceVh.btnTrigger.setVisibility(View.GONE);
            deviceVh.ivDeviceStatus.setVisibility(View.GONE);
            deviceVh.tvStringValue.setVisibility(View.GONE);
        }

        if (node != null && !node.isOnline()) {

            deviceVh.itemView.setAlpha(0.8f);
            deviceVh.ivDeviceStatus.setImageResource(R.drawable.ic_output_disable);
            deviceVh.ivDeviceStatus.setOnClickListener(null);
            deviceVh.btnTrigger.setAlpha(0.3f);
            deviceVh.btnTrigger.setEnabled(false);
            deviceVh.btnTrigger.setClickable(false);
            deviceVh.btnTrigger.enableLongHold(false);
            deviceVh.btnTrigger.setOnButtonClickListener(null);

            if (espApp.getAppState().equals(EspApplication.AppState.GET_DATA_SUCCESS)
                    || espApp.getAppState().equals(EspApplication.AppState.REFRESH_DATA)
                    || espApp.getAppState().equals(EspApplication.AppState.GET_DATA_FAILED)) {

                deviceVh.llOffline.setVisibility(View.VISIBLE);
                deviceVh.ivOffline.setVisibility(View.VISIBLE);
                String offlineText = context.getString(R.string.status_offline);
                deviceVh.tvOffline.setText(offlineText);
                deviceVh.tvOffline.setTextColor(context.getColor(R.color.colorAccent));

                if (node.getTimeStampOfStatus() != 0) {

                    Calendar calendar = Calendar.getInstance();
                    int day = calendar.get(Calendar.DATE);

                    calendar.setTimeInMillis(node.getTimeStampOfStatus());
                    int offlineDay = calendar.get(Calendar.DATE);

                    if (day == offlineDay) {

                        SimpleDateFormat formatter = new SimpleDateFormat("HH:mm");
                        String time = formatter.format(calendar.getTime());
                        offlineText = context.getString(R.string.offline_at) + " " + time;

                    } else {

                        SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yy, HH:mm");
                        String time = formatter.format(calendar.getTime());
                        offlineText = context.getString(R.string.offline_at) + " " + time;
                    }
                    deviceVh.tvOffline.setText(offlineText);
                }

            } else {
                deviceVh.llOffline.setVisibility(View.INVISIBLE);
            }
        } else {
            deviceVh.itemView.setAlpha(1f);
            deviceVh.btnTrigger.setAlpha(1f);
            deviceVh.btnTrigger.setEnabled(true);
            deviceVh.btnTrigger.setClickable(true);
            deviceVh.btnTrigger.enableLongHold(true);
            deviceVh.llOffline.setVisibility(View.INVISIBLE);
        }

        String nodeId = device.getNodeId();
        if (espApp.localDeviceMap.containsKey(nodeId)) {
            deviceVh.llOffline.setVisibility(View.VISIBLE);

            EspLocalDevice localDevice = espApp.localDeviceMap.get(nodeId);
            if (localDevice.getSecurityType() == 1) {
                deviceVh.ivSecureLocal.setVisibility(View.VISIBLE);
                deviceVh.ivOffline.setVisibility(View.INVISIBLE);
            } else {
                deviceVh.ivSecureLocal.setVisibility(View.INVISIBLE);
                deviceVh.ivOffline.setVisibility(View.GONE);
            }
            deviceVh.tvOffline.setText(R.string.local_device_text);
            deviceVh.tvOffline.setTextColor(context.getColor(R.color.colorPrimaryDark));
        }

        // implement setOnClickListener event on item view.
        deviceVh.itemView.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View view) {
                Intent intent = new Intent(context, EspDeviceActivity.class);
                intent.putExtra(AppConstants.KEY_ESP_DEVICE, device);
                context.startActivity(intent);
            }
        });
    }

    @Override
    public int getItemCount() {
        return deviceList.size();
    }

    public void updateList(ArrayList<Device> updatedDeviceList) {
        deviceList = updatedDeviceList;
        notifyDataSetChanged();
    }

    static class DeviceViewHolder extends RecyclerView.ViewHolder {

        TextView tvDeviceName, tvStringValue, tvOffline;
        ImageView ivDevice, ivDeviceStatus, ivOffline, ivSecureLocal;
        RelativeLayout llOffline;
        TapHoldUpButton btnTrigger;

        public DeviceViewHolder(View itemView) {
            super(itemView);

            tvDeviceName = itemView.findViewById(R.id.tv_device_name);
            ivDevice = itemView.findViewById(R.id.iv_device);
            llOffline = itemView.findViewById(R.id.ll_offline);
            ivOffline = itemView.findViewById(R.id.iv_offline);
            tvOffline = itemView.findViewById(R.id.tv_offline);
            ivSecureLocal = itemView.findViewById(R.id.iv_secure_local);
            ivDeviceStatus = itemView.findViewById(R.id.iv_on_off);
            tvStringValue = itemView.findViewById(R.id.tv_string);
            btnTrigger = itemView.findViewById(R.id.btn_trigger);
        }
    }
}
