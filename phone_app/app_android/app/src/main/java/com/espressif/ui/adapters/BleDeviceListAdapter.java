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

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.rainmaker.R;
import com.espressif.ui.activities.BLEProvisionLanding;
import com.espressif.ui.models.BleDevice;

import java.util.ArrayList;

public class BleDeviceListAdapter extends RecyclerView.Adapter<BleDeviceListAdapter.BLEDeviceViewHolder> {

    private Activity context;
    private ArrayList<BleDevice> bluetoothDevices;

    public BleDeviceListAdapter(Activity context, ArrayList<BleDevice> bluetoothDevices) {
        this.context = context;
        this.bluetoothDevices = bluetoothDevices;
    }

    @Override
    public BLEDeviceViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_ble_scan, parent, false);
        BLEDeviceViewHolder vh = new BLEDeviceViewHolder(v); // pass the view to View Holder
        return vh;
    }

    @Override
    public void onBindViewHolder(@NonNull final BLEDeviceViewHolder holder, int position) {

        BleDevice bleDevice = bluetoothDevices.get(position);
        holder.tvBleDeviceName.setText(bleDevice.getName());

        holder.itemView.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                ((BLEProvisionLanding) context).deviceClick(holder.getAdapterPosition());
            }
        });
    }

    @Override
    public int getItemCount() {
        return bluetoothDevices.size();
    }

    static class BLEDeviceViewHolder extends RecyclerView.ViewHolder {

        TextView tvBleDeviceName;

        public BLEDeviceViewHolder(View itemView) {
            super(itemView);
            tvBleDeviceName = itemView.findViewById(R.id.tv_ble_device_name);
        }
    }
}
