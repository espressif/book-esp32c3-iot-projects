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

package com.espressif.ui.activities;

import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.WindowManager;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.coordinatorlayout.widget.CoordinatorLayout;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.SimpleItemAnimator;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.rainmaker.R;
import com.espressif.ui.adapters.GroupDeviceAdapter;
import com.espressif.ui.adapters.GroupNodeAdapter;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Group;
import com.google.android.material.appbar.MaterialToolbar;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.util.ArrayList;
import java.util.Map;

public class GroupNodeSelectionActivity extends AppCompatActivity {

    private String groupName;
    private ArrayList<EspNode> nodes = new ArrayList<>();
    private ArrayList<Device> devices = new ArrayList<>();
    private Group group;
    private RecyclerView rvDevices, rvNodes;
    private EspApplication espApp;
    private RelativeLayout layoutProgress;
    private CoordinatorLayout layoutDeviceSelection;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_group_node_selection);

        espApp = (EspApplication) getApplicationContext();
        group = getIntent().getParcelableExtra(AppConstants.KEY_GROUP);
        groupName = getIntent().getStringExtra(AppConstants.KEY_GROUP_NAME);
        initViews();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        menu.add(Menu.NONE, 1, Menu.NONE, R.string.btn_done).setShowAsAction(MenuItem.SHOW_AS_ACTION_ALWAYS);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {

            case 1:
                saveSelectedDevices();
                return true;

            default:
                return super.onOptionsItemSelected(item);
        }
    }

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        getSupportActionBar().setTitle(R.string.title_activity_select_devices);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        rvDevices = findViewById(R.id.rv_device_list);
        rvNodes = findViewById(R.id.rv_node_list);

        layoutDeviceSelection = findViewById(R.id.layout_node_device);
        layoutProgress = findViewById(R.id.layout_progress);

        ArrayList<String> nodeIds = null;
        if (group != null) {
            nodeIds = group.getNodeList();
        }

        if (nodeIds == null || nodeIds.size() <= 0) {
            for (Map.Entry<String, EspNode> entry : espApp.nodeMap.entrySet()) {

                String key = entry.getKey();
                EspNode node = entry.getValue();

                if (node != null) {
                    if (node.getDevices().size() == 1) {
                        devices.add(new Device(node.getDevices().get(0)));
                    } else if (node.getDevices().size() > 1) {
                        nodes.add(new EspNode(node));
                    }
                }
            }
        } else {
            for (Map.Entry<String, EspNode> entry : espApp.nodeMap.entrySet()) {

                String key = entry.getKey();
                EspNode node = entry.getValue();

                if (node != null && !nodeIds.contains(node.getNodeId())) {

                    if (node.getDevices().size() == 1) {
                        devices.add(new Device(node.getDevices().get(0)));
                    } else if (node.getDevices().size() > 1) {
                        nodes.add(new EspNode(node));
                    }
                }
            }
        }

        ((SimpleItemAnimator) rvDevices.getItemAnimator()).setSupportsChangeAnimations(false);
        GroupDeviceAdapter deviceAdapter = new GroupDeviceAdapter(this, group, devices, true, true);
        GridLayoutManager gridLayoutManager = new GridLayoutManager(this, 2);
        rvDevices.setLayoutManager(gridLayoutManager); // set LayoutManager to RecyclerView
        rvDevices.setAdapter(deviceAdapter);
//        rvDevices.setHasFixedSize(true);

        ((SimpleItemAnimator) rvNodes.getItemAnimator()).setSupportsChangeAnimations(false);
        GroupNodeAdapter nodeAdapter = new GroupNodeAdapter(this, group, nodes, true);
        rvNodes.setLayoutManager(new LinearLayoutManager(this));
        rvNodes.setAdapter(nodeAdapter);
//        rvNodes.setHasFixedSize(true);
    }

    private void saveSelectedDevices() {

        ApiManager apiManager = ApiManager.getInstance(GroupNodeSelectionActivity.this);
        JsonObject body = new JsonObject();
        JsonArray nodesArray = new JsonArray();
        body.addProperty(AppConstants.KEY_GROUP_NAME, groupName);

        for (int i = 0; i < devices.size(); i++) {
            if (devices.get(i).getSelectedState() == 1) {
                nodesArray.add(devices.get(i).getNodeId());
            }
        }
        for (int i = 0; i < nodes.size(); i++) {
            if (nodes.get(i).isSelected()) {
                nodesArray.add(nodes.get(i).getNodeId());
            }
        }
        body.add(AppConstants.KEY_NODES, nodesArray);

        if (group == null) {

            if (nodesArray.size() == 0) {
                body.remove(AppConstants.KEY_NODES);
            }
            showLoading(getString(R.string.progress_create_group));
            apiManager.createGroup(body, new ApiResponseListener() {
                @Override
                public void onSuccess(Bundle data) {
                    hideLoading();
                    Toast.makeText(GroupNodeSelectionActivity.this, R.string.success_group_create, Toast.LENGTH_LONG).show();
                    setResult(RESULT_OK);
                    finish();
                }

                @Override
                public void onResponseFailure(Exception exception) {
                    hideLoading();
                    if (exception instanceof CloudException) {
                        Toast.makeText(GroupNodeSelectionActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                    } else {
                        Toast.makeText(GroupNodeSelectionActivity.this, R.string.error_group_create, Toast.LENGTH_SHORT).show();
                    }
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                    hideLoading();
                    if (exception instanceof CloudException) {
                        Toast.makeText(GroupNodeSelectionActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                    } else {
                        Toast.makeText(GroupNodeSelectionActivity.this, R.string.error_group_create, Toast.LENGTH_SHORT).show();
                    }
                }
            });
        } else {
            showLoading(getString(R.string.progress_update_group));
            body.addProperty(AppConstants.KEY_OPERATION, AppConstants.KEY_OPERATION_ADD);
            apiManager.updateGroup(group.getGroupId(), body, new ApiResponseListener() {
                @Override
                public void onSuccess(Bundle data) {
                    hideLoading();
                    Toast.makeText(GroupNodeSelectionActivity.this, R.string.success_group_update, Toast.LENGTH_LONG).show();
                    setResult(RESULT_OK);
                    finish();
                }

                @Override
                public void onResponseFailure(Exception exception) {
                    hideLoading();
                    if (exception instanceof CloudException) {
                        Toast.makeText(GroupNodeSelectionActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                    } else {
                        Toast.makeText(GroupNodeSelectionActivity.this, R.string.error_group_update, Toast.LENGTH_SHORT).show();
                    }
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                    hideLoading();
                    if (exception instanceof CloudException) {
                        Toast.makeText(GroupNodeSelectionActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                    } else {
                        Toast.makeText(GroupNodeSelectionActivity.this, R.string.error_group_update, Toast.LENGTH_SHORT).show();
                    }
                }
            });
        }
    }

    private void showLoading(String msg) {
        layoutDeviceSelection.setAlpha(0.3f);
        layoutProgress.setVisibility(View.VISIBLE);
        TextView progressText = layoutProgress.findViewById(R.id.tv_loading);
        progressText.setText(msg);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
    }

    public void hideLoading() {
        layoutDeviceSelection.setAlpha(1);
        layoutProgress.setVisibility(View.GONE);
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
    }
}
