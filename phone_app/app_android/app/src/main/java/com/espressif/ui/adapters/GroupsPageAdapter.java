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
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.location.LocationManager;
import android.os.Build;
import android.os.Vibrator;
import android.provider.Settings;
import android.util.Log;
import android.view.HapticFeedbackConstants;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.SimpleItemAnimator;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.AddDeviceActivity;
import com.espressif.ui.activities.BLEProvisionLanding;
import com.espressif.ui.activities.EspMainActivity;
import com.espressif.ui.activities.GroupDetailActivity;
import com.espressif.ui.activities.ProvisionLanding;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Group;

import java.util.ArrayList;
import java.util.Map;

public class GroupsPageAdapter extends RecyclerView.Adapter<GroupsPageAdapter.GroupPageViewHolder> {

    private final String TAG = GroupsPageAdapter.class.getSimpleName();

    private Activity context;
    private ArrayList<Group> groups;
    private EspApplication espApp;
    private boolean isRefreshing = false;

    public GroupsPageAdapter(Activity context, ArrayList<Group> groups) {
        this.context = context;
        this.groups = groups;
        espApp = (EspApplication) context.getApplicationContext();
    }

    @NonNull
    @Override
    public GroupPageViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.layout_group_page, parent, false);
        GroupPageViewHolder groupPageViewHolder = new GroupPageViewHolder(v);
        return groupPageViewHolder;
    }

    @Override
    public void onBindViewHolder(@NonNull final GroupPageViewHolder viewHolder, int position) {

        Group group = groups.get(position);
        ArrayList<Device> devices = new ArrayList<>();
        ArrayList<EspNode> nodes = new ArrayList<>();

        GridLayoutManager linearLayoutManager = new GridLayoutManager(context, 2);
        viewHolder.rvDevices.setLayoutManager(linearLayoutManager);
//        viewHolder.rvDevices.setHasFixedSize(true);

        viewHolder.rvNodes.setLayoutManager(new LinearLayoutManager(context));
//        viewHolder.rvNodes.setHasFixedSize(true);

        viewHolder.swipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {

            @Override
            public void onRefresh() {
                isRefreshing = true;
                notifyDataSetChanged();
                ((EspMainActivity) context).refreshDeviceList();
            }
        });

        EspDeviceAdapter deviceAdapter = new EspDeviceAdapter(context, devices);
        viewHolder.rvDevices.setAdapter(deviceAdapter);

        NodeAdapter nodeAdapter = new NodeAdapter(context, nodes);
        viewHolder.rvNodes.setAdapter(nodeAdapter);

        if (position == 0) {

            for (Map.Entry<String, EspNode> entry : espApp.nodeMap.entrySet()) {

                String key = entry.getKey();
                EspNode node = entry.getValue();

                if (node.getDevices().size() == 1) {
                    devices.addAll(node.getDevices());
                } else if (node.getDevices().size() > 1) {
                    nodes.add(node);
                }
            }
        } else {
            ArrayList<String> nodeIds = group.getNodeList();

            if (nodeIds != null && nodeIds.size() > 0) {
                for (int i = 0; i < nodeIds.size(); i++) {
                    EspNode node = espApp.nodeMap.get(nodeIds.get(i));
                    if (node != null) {
                        if (node.getDevices().size() == 1) {
                            devices.addAll(node.getDevices());
                        } else if (node.getDevices().size() > 1) {
                            nodes.add(node);
                        }
                    }
                }
            }
        }
        Log.d(TAG, "Group : " + group.getGroupName() + ",  Device list size : " + devices.size());
        Log.d(TAG, "Group : " + group.getGroupName() + ",  Node list size : " + nodes.size());

        if (devices.size() <= 0 && nodes.size() <= 0) {

            viewHolder.tvNoDevice.setText(R.string.no_devices);
            viewHolder.rlNoDevices.setVisibility(View.VISIBLE);
            viewHolder.tvNoDevice.setVisibility(View.VISIBLE);
            viewHolder.tvAddDevice.setVisibility(View.GONE);
            viewHolder.rvDevices.setVisibility(View.GONE);
            viewHolder.rvNodes.setVisibility(View.GONE);

            if (position == 0) {
                viewHolder.ivNoDevice.setVisibility(View.VISIBLE);
                viewHolder.btnAddDevice.setVisibility(View.VISIBLE);
                viewHolder.btnAddDevice.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {

                        Vibrator vib = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
                        vib.vibrate(HapticFeedbackConstants.VIRTUAL_KEY);

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {

                            if (!isLocationEnabled()) {
                                askForLocation();
                                return;
                            }
                        }
                        goToAddDeviceActivity();
                    }
                });
            } else {
                viewHolder.ivNoDevice.setVisibility(View.GONE);

                if (espApp.nodeMap.size() > 0) {
                    viewHolder.btnAddDevice.setVisibility(View.VISIBLE);
                    viewHolder.btnAddDevice.setOnClickListener(new View.OnClickListener() {

                        @Override
                        public void onClick(View v) {
                            Intent intent = new Intent(context, GroupDetailActivity.class);
                            intent.putExtra(AppConstants.KEY_GROUP, groups.get(viewHolder.getAdapterPosition()));
                            context.startActivity(intent);
                        }
                    });
                } else {
                    viewHolder.btnAddDevice.setVisibility(View.GONE);
                }
            }
        } else {

            viewHolder.rlNoDevices.setVisibility(View.GONE);
            viewHolder.btnAddDevice.setVisibility(View.GONE);

            if (devices.size() > 0) {
                viewHolder.rvDevices.setVisibility(View.VISIBLE);
                deviceAdapter.updateList(devices);
            } else {
                viewHolder.rvDevices.setVisibility(View.GONE);
            }

            if (nodes.size() > 0) {
                viewHolder.rvNodes.setVisibility(View.VISIBLE);
                nodeAdapter.updateList(nodes);
            } else {
                viewHolder.rvNodes.setVisibility(View.GONE);
            }
        }
        viewHolder.swipeRefreshLayout.setRefreshing(isRefreshing);
    }

    public void setRefreshing(boolean refreshing) {
        isRefreshing = refreshing;
    }

    @Override
    public int getItemCount() {
        return groups.size();
    }

    static class GroupPageViewHolder extends RecyclerView.ViewHolder {

        private CardView btnAddDevice;
        private TextView txtAddDeviceBtn;
        private ImageView arrowImage;

        private TextView tvNoDevice, tvAddDevice;
        private RelativeLayout rlNoDevices;
        private ImageView ivNoDevice;
        private RecyclerView rvDevices, rvNodes;
        private SwipeRefreshLayout swipeRefreshLayout;

        public GroupPageViewHolder(View pageView) {
            super(pageView);

            rlNoDevices = pageView.findViewById(R.id.rl_no_device);
            tvNoDevice = pageView.findViewById(R.id.tv_no_device);
            tvAddDevice = pageView.findViewById(R.id.tv_add_device);
            ivNoDevice = pageView.findViewById(R.id.iv_no_device);

            btnAddDevice = pageView.findViewById(R.id.btn_add_device_1);
            txtAddDeviceBtn = pageView.findViewById(R.id.text_btn);
            arrowImage = pageView.findViewById(R.id.iv_arrow);
            txtAddDeviceBtn.setText(R.string.btn_add_device);
            btnAddDevice.setVisibility(View.GONE);
            arrowImage.setVisibility(View.GONE);

            rvDevices = pageView.findViewById(R.id.rv_device_list);
            rvNodes = pageView.findViewById(R.id.rv_node_list);
            swipeRefreshLayout = pageView.findViewById(R.id.swipe_container);

            ((SimpleItemAnimator) rvDevices.getItemAnimator()).setSupportsChangeAnimations(false);
            ((SimpleItemAnimator) rvNodes.getItemAnimator()).setSupportsChangeAnimations(false);
        }
    }

    private void goToAddDeviceActivity() {

        if (BuildConfig.isQRCodeSupported) {
            Intent intent = new Intent(context, AddDeviceActivity.class);
            context.startActivity(intent);
        } else {

            boolean isSec1 = true;
            ESPProvisionManager provisionManager = ESPProvisionManager.getInstance(context.getApplicationContext());

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
                Toast.makeText(context, R.string.error_device_type_not_supported, Toast.LENGTH_LONG).show();
            }

        }
    }

    private void askForDeviceType(final boolean isSec1) {

        final String[] deviceTypes = context.getResources().getStringArray(R.array.prov_transport_types);
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setCancelable(true);
        builder.setTitle(R.string.dialog_msg_device_selection);
        final ESPProvisionManager provisionManager = ESPProvisionManager.getInstance(context.getApplicationContext());

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

    private void goToBLEProvisionLanding(boolean isSec1) {

        Intent intent = new Intent(context, BLEProvisionLanding.class);
        if (isSec1) {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_1);
        } else {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_0);
        }
        context.startActivity(intent);
    }

    private void goToWiFiProvisionLanding(boolean isSec1) {

        Intent intent = new Intent(context, ProvisionLanding.class);
        if (isSec1) {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_1);
        } else {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_0);
        }
        context.startActivity(intent);
    }

    private void askForLocation() {

        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setCancelable(true);
        builder.setMessage(R.string.dialog_msg_for_gps);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_ok, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                context.startActivity(new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS));
            }
        });

        builder.setNegativeButton(R.string.btn_cancel, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        builder.show();
    }

    private boolean isLocationEnabled() {

        boolean gps_enabled = false;
        boolean network_enabled = false;
        LocationManager lm = (LocationManager) context.getApplicationContext().getSystemService(Activity.LOCATION_SERVICE);

        try {
            gps_enabled = lm.isProviderEnabled(LocationManager.GPS_PROVIDER);
        } catch (Exception ex) {
        }

        try {
            network_enabled = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
        } catch (Exception ex) {
        }

        Log.d(TAG, "GPS Enabled : " + gps_enabled + " , Network Enabled : " + network_enabled);

        boolean result = gps_enabled || network_enabled;
        return result;
    }
}
