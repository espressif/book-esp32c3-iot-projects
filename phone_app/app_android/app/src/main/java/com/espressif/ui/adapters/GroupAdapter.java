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
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.GroupDetailActivity;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Group;

import java.util.ArrayList;

public class GroupAdapter extends RecyclerView.Adapter<GroupAdapter.GroupViewHolder> {

    private Activity context;
    private ArrayList<Group> groupList;

    public GroupAdapter(Activity context, ArrayList<Group> groups) {
        this.context = context;
        this.groupList = groups;
    }

    @Override
    public GroupViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_group, parent, false);
        GroupViewHolder viewHolder = new GroupViewHolder(v);
        return viewHolder;
    }

    @Override
    public void onBindViewHolder(@NonNull final GroupViewHolder groupViewHolder, final int position) {

        Group group = groupList.get(position);
        groupViewHolder.tvGroupName.setText(group.getGroupName());
        groupViewHolder.progressBar.setVisibility(View.GONE);

        // Display group devices
        StringBuilder deviceNames = new StringBuilder();

        ArrayList<String> nodeIds = group.getNodeList();
        EspApplication espApp = (EspApplication) context.getApplicationContext();

        if (nodeIds != null && nodeIds.size() > 0) {
            for (int nodeIndex = 0; nodeIndex < nodeIds.size(); nodeIndex++) {
                EspNode node = espApp.nodeMap.get(nodeIds.get(nodeIndex));
                if (node != null) {
                    ArrayList<Device> devices = node.getDevices();
                    if (devices != null) {
                        for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {

                            String deviceName = devices.get(deviceIndex).getUserVisibleName();
                            if (deviceNames.length() != 0) {
                                deviceNames.append(", ");
                            }
                            deviceNames.append(deviceName);
                        }
                    }
                }
            }
        }

        groupViewHolder.tvGroupDevices.setText(deviceNames);

        groupViewHolder.itemView.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                Group clickedGroup = groupList.get(groupViewHolder.getAdapterPosition());
                Intent intent = new Intent(context, GroupDetailActivity.class);
                intent.putExtra(AppConstants.KEY_GROUP, clickedGroup);
                context.startActivity(intent);
            }
        });
    }

    @Override
    public int getItemCount() {
        return groupList.size();
    }

    static class GroupViewHolder extends RecyclerView.ViewHolder {

        TextView tvGroupName, tvGroupDevices;
        ContentLoadingProgressBar progressBar;

        public GroupViewHolder(View itemView) {
            super(itemView);

            tvGroupName = itemView.findViewById(R.id.tv_group_name);
            progressBar = itemView.findViewById(R.id.sch_progress_indicator);
            tvGroupDevices = itemView.findViewById(R.id.tv_group_devices);
        }
    }
}
