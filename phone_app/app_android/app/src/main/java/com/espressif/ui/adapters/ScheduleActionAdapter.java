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
import android.view.animation.LinearInterpolator;
import android.widget.CompoundButton;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.widget.AppCompatCheckBox;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.rainmaker.R;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.Param;

import java.util.ArrayList;
import java.util.Iterator;

public class ScheduleActionAdapter extends RecyclerView.Adapter<ScheduleActionAdapter.ActionViewHolder> {

    private Activity context;
    private ArrayList<Device> deviceList;
    private ScheduleParamAdapter paramAdapter;

    public ScheduleActionAdapter(Activity context, ArrayList<Device> list) {
        this.context = context;
        this.deviceList = list;
    }

    @Override
    public ActionViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_action, parent, false);
        return new ActionViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final ActionViewHolder holder, int position) {

        Device device = deviceList.get(position);
        holder.bind(device);

        ArrayList<Param> params = device.getParams();
        Iterator itr = params.iterator();
        while (itr.hasNext()) {
            Param p = (Param) itr.next();

            if (!p.isDynamicParam()) {
                itr.remove();
            } else if (p.getParamType() != null && p.getParamType().equals(AppConstants.PARAM_TYPE_NAME)) {
                itr.remove();
            } else if (!p.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {
                itr.remove();
            } else if (p.getUiType() != null && p.getUiType().equals(AppConstants.UI_TYPE_HIDDEN)) {
                itr.remove();
            }
        }

        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(context);
        linearLayoutManager.setOrientation(RecyclerView.VERTICAL);
        holder.paramRecyclerView.setLayoutManager(linearLayoutManager);

        paramAdapter = new ScheduleParamAdapter(context, this, device, params);
        holder.paramRecyclerView.setAdapter(paramAdapter);

        switch (device.getSelectedState()) {
            case 0:
                holder.ivDeviceSelect.setChecked(false);
                holder.ivDeviceSelect.setButtonDrawable(R.drawable.ic_checkbox_unchecked);
                break;
            case 1:
                holder.ivDeviceSelect.setChecked(true);
                holder.ivDeviceSelect.setButtonDrawable(R.drawable.ic_checkbox_checked);
                break;
            case 2:
                holder.ivDeviceSelect.setButtonDrawable(R.drawable.ic_checkbox_indeterminate);
                break;
        }

        holder.itemView.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {

                Device d = deviceList.get(holder.getAdapterPosition());
                boolean expanded = d.isExpanded();
                d.setExpanded(!expanded);
                if (expanded) {
                    holder.ivExpandArrow.animate().rotation(0).setInterpolator(new LinearInterpolator()).setDuration(200);
                } else {
                    holder.ivExpandArrow.animate().rotation(90).setInterpolator(new LinearInterpolator()).setDuration(200);
                }
                notifyItemChanged(holder.getAdapterPosition());
            }
        });

        holder.ivDeviceSelect.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {

                // Ignore callback if checkbox value is changed programmatically not by user click.
                if (!buttonView.isPressed()) {
                    return;
                }

                Device d = deviceList.get(holder.getAdapterPosition());
                int selectedState = 0;
                if (isChecked) {
                    selectedState = 1;
                    d.setExpanded(true);
                    holder.ivExpandArrow.animate().rotation(90).setInterpolator(new LinearInterpolator()).setDuration(200);
                }
                d.setSelectedState(selectedState);

                switch (selectedState) {
                    case 0:
                        holder.ivDeviceSelect.setChecked(false);
                        holder.ivDeviceSelect.setButtonDrawable(R.drawable.ic_checkbox_unchecked);
                        break;
                    case 1:
                        holder.ivDeviceSelect.setChecked(true);
                        holder.ivDeviceSelect.setButtonDrawable(R.drawable.ic_checkbox_checked);
                        break;
                }
                ArrayList<Param> deviceParams = d.getParams();
                for (int i = 0; i < deviceParams.size(); i++) {
                    deviceParams.get(i).setSelected(isChecked);
                }
                notifyItemChanged(holder.getAdapterPosition());
            }
        });
    }

    @Override
    public int getItemCount() {
        return deviceList == null ? 0 : deviceList.size();
    }

    static class ActionViewHolder extends RecyclerView.ViewHolder {

        private TextView tvDeviceName;
        private ImageView ivExpandArrow;
        private AppCompatCheckBox ivDeviceSelect;
        private RecyclerView paramRecyclerView;

        public ActionViewHolder(View itemView) {
            super(itemView);

            tvDeviceName = itemView.findViewById(R.id.tv_device_name);
            ivExpandArrow = itemView.findViewById(R.id.iv_expand_arrow);
            ivDeviceSelect = itemView.findViewById(R.id.iv_device_select);
            paramRecyclerView = itemView.findViewById(R.id.rv_param_list);
        }

        private void bind(Device device) {

            boolean expanded = device.isExpanded();
            paramRecyclerView.setVisibility(expanded ? View.VISIBLE : View.GONE);
            tvDeviceName.setText(device.getUserVisibleName());
        }
    }
}
