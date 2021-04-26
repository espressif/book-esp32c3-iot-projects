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
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.NetworkApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.rainmaker.R;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Param;
import com.espressif.ui.models.Service;
import com.espressif.ui.models.SharingRequest;
import com.espressif.ui.widgets.EspDropDown;
import com.google.gson.JsonObject;

import java.util.ArrayList;
import java.util.Arrays;

public class NodeDetailsAdapter extends RecyclerView.Adapter<NodeDetailsAdapter.NodeDetailViewHolder> {

    private final String TAG = NodeDetailsAdapter.class.getSimpleName();

    private Activity context;
    private ArrayList<String> nodeInfoList;
    private ArrayList<String> nodeInfoValueList;
    private ArrayList<SharingRequest> sharingRequests;
    private SharedUserAdapter userAdapter;
    private EspNode node;

    public NodeDetailsAdapter(Activity context, ArrayList<String> nodeInfoList, ArrayList<String> nodeValueList,
                              EspNode node, ArrayList<SharingRequest> sharingRequests) {
        this.context = context;
        this.nodeInfoList = nodeInfoList;
        this.nodeInfoValueList = nodeValueList;
        this.sharingRequests = sharingRequests;
        this.node = node;
    }

    @Override
    public NodeDetailViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_node_info, parent, false);
        NodeDetailViewHolder vh = new NodeDetailViewHolder(v);
        return vh;
    }

    @Override
    public void onBindViewHolder(@NonNull final NodeDetailViewHolder nodeDetailVh, final int position) {

        // set the data in items
        nodeDetailVh.tvNodeInfoLabel.setText(nodeInfoList.get(position));

        if (nodeInfoList.get(position).equals(context.getString(R.string.node_shared_with))
                || nodeInfoList.get(position).equals(context.getString(R.string.node_shared_by))) {

            nodeDetailVh.rvSharedUsers.setVisibility(View.VISIBLE);
            nodeDetailVh.tvNodeInfoValue.setVisibility(View.GONE);
            nodeDetailVh.dropDownTimezone.setVisibility(View.GONE);

            LinearLayoutManager linearLayoutManager = new LinearLayoutManager(context);
            linearLayoutManager.setOrientation(RecyclerView.VERTICAL);
            nodeDetailVh.rvSharedUsers.setLayoutManager(linearLayoutManager);
            userAdapter = new SharedUserAdapter(context, node, sharingRequests, false);
            nodeDetailVh.rvSharedUsers.setAdapter(userAdapter);

        } else if (nodeInfoList.get(position).equals(context.getString(R.string.pending_requests))) {

            nodeDetailVh.rvSharedUsers.setVisibility(View.VISIBLE);
            nodeDetailVh.tvNodeInfoValue.setVisibility(View.GONE);
            nodeDetailVh.dropDownTimezone.setVisibility(View.GONE);

            LinearLayoutManager linearLayoutManager = new LinearLayoutManager(context);
            linearLayoutManager.setOrientation(RecyclerView.VERTICAL);
            nodeDetailVh.rvSharedUsers.setLayoutManager(linearLayoutManager);
            userAdapter = new SharedUserAdapter(context, node, sharingRequests, true);
            nodeDetailVh.rvSharedUsers.setAdapter(userAdapter);

        } else if (nodeInfoList.get(position).equals(context.getString(R.string.node_timezone))) {

            nodeDetailVh.rvSharedUsers.setVisibility(View.GONE);
            nodeDetailVh.tvNodeInfoValue.setVisibility(View.GONE);
            nodeDetailVh.rlTimezone.setVisibility(View.VISIBLE);
            nodeDetailVh.dropDownTimezone.setVisibility(View.VISIBLE);
            nodeDetailVh.dropDownTimezone.setEnabled(false);
            nodeDetailVh.dropDownTimezone.setOnItemSelectedListener(null);

            ArrayList<Service> services = node.getServices();
            Service tzService = null;
            String tzValue = null, tzPosixValue = null;
            String tzParamName = null;

            for (int i = 0; i < services.size(); i++) {
                Service s = services.get(i);
                if (!TextUtils.isEmpty(s.getType()) && s.getType().equals(AppConstants.SERVICE_TYPE_TIME)) {
                    tzService = s;
                    break;
                }
            }

            if (tzService != null) {
                ArrayList<Param> tzParams = tzService.getParams();
                if (tzParams != null) {
                    for (int paramIdx = 0; paramIdx < tzParams.size(); paramIdx++) {
                        Param timeParam = tzParams.get(paramIdx);
                        if (AppConstants.PARAM_TYPE_TZ.equalsIgnoreCase(timeParam.getParamType())) {
                            tzValue = timeParam.getLabelValue();
                            tzParamName = timeParam.getName();
                        } else if (AppConstants.PARAM_TYPE_TZ_POSIX.equalsIgnoreCase(timeParam.getParamType())) {
                            tzPosixValue = timeParam.getLabelValue();
                        }
                    }
                }

                String[] timeZoneArray = context.getResources().getStringArray(R.array.timezones);
                ArrayList<String> spinnerValues = new ArrayList<>(Arrays.asList(timeZoneArray));
                int tzValueIndex = -1;
                Log.d(TAG, "TZ : " + tzValue);
                Log.d(TAG, "TZ POSIX : " + tzPosixValue);

                if (TextUtils.isEmpty(tzValue) || TextUtils.isEmpty(tzPosixValue)) {
                    spinnerValues.add(0, context.getString(R.string.select_timezone));
                    nodeDetailVh.dropDownTimezone.setTag(R.id.position, 0);
                } else {
                    if (spinnerValues.contains(tzValue)) {
                        tzValueIndex = spinnerValues.indexOf(tzValue);
                        nodeDetailVh.dropDownTimezone.setTag(R.id.position, tzValueIndex);
                    } else {
                        spinnerValues.add(0, context.getString(R.string.select_timezone));
                        nodeDetailVh.dropDownTimezone.setTag(R.id.position, 0);
                    }
                }

                ArrayAdapter<String> dataAdapter = new ArrayAdapter<String>(context, android.R.layout.simple_spinner_item, spinnerValues);
                dataAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                nodeDetailVh.dropDownTimezone.setAdapter(dataAdapter);

                if (tzValueIndex != -1) {
                    nodeDetailVh.dropDownTimezone.setSelection(tzValueIndex, true);
                }
                final Service finalTzService = tzService;
                final String finalTzParamName = tzParamName;
                final int oldTzValueIndex = tzValueIndex;
                nodeDetailVh.dropDownTimezone.setEnabled(true);

                nodeDetailVh.dropDownTimezone.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {

                    @Override
                    public void onItemSelected(AdapterView<?> parent, View view, final int position, long id) {

                        if ((int) nodeDetailVh.dropDownTimezone.getTag(R.id.position) != position) {

                            final String newValue = parent.getItemAtPosition(position).toString();
                            nodeDetailVh.dropDownTimezone.setEnabled(false);
                            nodeDetailVh.tzProgress.setVisibility(View.VISIBLE);
                            Log.d(TAG, "New timezone value : " + newValue);

                            JsonObject body = new JsonObject();
                            JsonObject jsonParam = new JsonObject();
                            jsonParam.addProperty(finalTzParamName, newValue);
                            body.add(finalTzService.getName(), jsonParam);

                            NetworkApiManager networkApiManager = new NetworkApiManager(context.getApplicationContext());
                            networkApiManager.updateParamValue(node.getNodeId(), body, new ApiResponseListener() {

                                @Override
                                public void onSuccess(Bundle data) {

                                    context.runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {

                                            nodeDetailVh.tzProgress.setVisibility(View.GONE);
                                            nodeDetailVh.dropDownTimezone.setEnabled(true);
                                            nodeDetailVh.dropDownTimezone.setTag(R.id.position, position);
                                        }
                                    });
                                }

                                @Override
                                public void onResponseFailure(Exception exception) {

                                    if (exception instanceof CloudException) {
                                        Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                                    } else {
                                        Toast.makeText(context, R.string.error_update_timezone, Toast.LENGTH_SHORT).show();
                                    }

                                    context.runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            nodeDetailVh.tzProgress.setVisibility(View.GONE);
                                            nodeDetailVh.dropDownTimezone.setEnabled(true);
                                            nodeDetailVh.dropDownTimezone.setSelection(oldTzValueIndex, true);
                                        }
                                    });
                                }

                                @Override
                                public void onNetworkFailure(Exception exception) {

                                    if (exception instanceof CloudException) {
                                        Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                                    } else {
                                        Toast.makeText(context, R.string.error_update_timezone, Toast.LENGTH_SHORT).show();
                                    }

                                    context.runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            nodeDetailVh.tzProgress.setVisibility(View.GONE);
                                            nodeDetailVh.dropDownTimezone.setEnabled(true);
                                            nodeDetailVh.dropDownTimezone.setSelection(oldTzValueIndex, true);
                                        }
                                    });
                                }
                            });
                        }
                    }

                    @Override
                    public void onNothingSelected(AdapterView<?> parent) {
                    }
                });
            }

        } else if (!TextUtils.isEmpty(nodeInfoValueList.get(position))) {

            nodeDetailVh.rvSharedUsers.setVisibility(View.GONE);
            nodeDetailVh.dropDownTimezone.setVisibility(View.GONE);
            nodeDetailVh.tvNodeInfoValue.setVisibility(View.VISIBLE);
            nodeDetailVh.tvNodeInfoValue.setText(nodeInfoValueList.get(position));
        }
    }

    @Override
    public int getItemCount() {
        return nodeInfoList.size();
    }

    static class NodeDetailViewHolder extends RecyclerView.ViewHolder {

        TextView tvNodeInfoLabel, tvNodeInfoValue;
        RecyclerView rvSharedUsers;
        EspDropDown dropDownTimezone;
        RelativeLayout rlTimezone;
        ContentLoadingProgressBar tzProgress;

        public NodeDetailViewHolder(View itemView) {
            super(itemView);

            tvNodeInfoLabel = itemView.findViewById(R.id.tv_node_label);
            tvNodeInfoValue = itemView.findViewById(R.id.tv_node_value);
            rvSharedUsers = itemView.findViewById(R.id.rv_users_list);
            dropDownTimezone = itemView.findViewById(R.id.dropdown_time_zone);
            rlTimezone = itemView.findViewById(R.id.rl_timezone);
            tzProgress = itemView.findViewById(R.id.progress_indicator_timezone);
        }
    }
}
