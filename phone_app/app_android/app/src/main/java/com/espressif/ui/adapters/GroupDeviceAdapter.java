// Copyright 2021 Espressif Systems (Shanghai) PTE LTD
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

import android.app.Activity;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CompoundButton;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.GroupDetailActivity;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.Group;
import com.google.android.material.checkbox.MaterialCheckBox;

import java.util.ArrayList;

public class GroupDeviceAdapter extends RecyclerView.Adapter<GroupDeviceAdapter.GroupDeviceVH> {

    private Activity context;
    private Group group;
    private ArrayList<Device> deviceList;
    private boolean isSelection;
    private boolean isSingleDevice;

    public GroupDeviceAdapter(Activity context, Group group, ArrayList<Device> deviceList, boolean isSelection, boolean isSingleDevice) {
        this.context = context;
        this.group = group;
        this.deviceList = deviceList;
        this.isSelection = isSelection;
        this.isSingleDevice = isSingleDevice;
    }

    @Override
    public GroupDeviceVH onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_group_device, parent, false);
        GroupDeviceVH groupDeviceViewHolder = new GroupDeviceVH(v);
        return groupDeviceViewHolder;
    }

    @Override
    public void onBindViewHolder(@NonNull final GroupDeviceVH myViewHolder, final int position) {

        Device device = deviceList.get(position);

        if (isSingleDevice) {
            if (isSelection) {
                myViewHolder.cbDevice.setVisibility(View.VISIBLE);
                myViewHolder.ivRemove.setVisibility(View.GONE);
            } else {
                myViewHolder.cbDevice.setVisibility(View.GONE);
                myViewHolder.ivRemove.setVisibility(View.VISIBLE);
            }
        } else {
            myViewHolder.cbDevice.setVisibility(View.GONE);
            myViewHolder.ivRemove.setVisibility(View.GONE);
        }

        // set device name
        myViewHolder.tvDeviceName.setText(device.getUserVisibleName());

        // set device icon

        if (TextUtils.isEmpty(device.getDeviceType())) {

            myViewHolder.ivDevice.setImageResource(R.drawable.ic_device);

        } else {

            if (AppConstants.ESP_DEVICE_BULB.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device_bulb);

            } else if (AppConstants.ESP_DEVICE_BULB_CCT.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device_bulb_cct);

            } else if (AppConstants.ESP_DEVICE_BULB_RGB.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device_bulb_rgb);

            } else if (AppConstants.ESP_DEVICE_SWITCH.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device_switch);

            } else if (AppConstants.ESP_DEVICE_LOCK.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device_lock);

            } else if (AppConstants.ESP_DEVICE_THERMOSTAT.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device_thermostat);

            } else if (AppConstants.ESP_DEVICE_FAN.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device_fan);

            } else if (AppConstants.ESP_DEVICE_SENSOR.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device);

            } else if (AppConstants.ESP_DEVICE_TEMP_SENSOR.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device_temp_sensor);

            } else if (AppConstants.ESP_DEVICE_OUTLET.equals(device.getDeviceType())) {

                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device_outlet);

            } else {
                myViewHolder.ivDevice.setImageResource(R.drawable.ic_device);
            }
        }

        if (group != null) {
            myViewHolder.ivRemove.setOnClickListener(new View.OnClickListener() {

                @Override
                public void onClick(View view) {

                    if (context instanceof GroupDetailActivity) {
                        String nodeId = deviceList.get(myViewHolder.getAdapterPosition()).getNodeId();
                        ((GroupDetailActivity) context).removeDevice(nodeId);
                    }
                }
            });
        }

        myViewHolder.cbDevice.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                deviceList.get(myViewHolder.getAdapterPosition()).setSelectedState(isChecked ? 1 : 0);
            }
        });

        myViewHolder.itemView.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View view) {
                myViewHolder.cbDevice.toggle();
            }
        });
    }

    @Override
    public int getItemCount() {
        return deviceList.size();
    }

    static class GroupDeviceVH extends RecyclerView.ViewHolder {

        TextView tvDeviceName;
        ImageView ivDevice, ivRemove;
        MaterialCheckBox cbDevice;

        public GroupDeviceVH(View itemView) {
            super(itemView);

            tvDeviceName = itemView.findViewById(R.id.tv_device_name);
            ivDevice = itemView.findViewById(R.id.iv_device);
            cbDevice = itemView.findViewById(R.id.cb_device);
            ivRemove = itemView.findViewById(R.id.iv_remove);
        }
    }
}
