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
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.WindowManager;
import android.widget.RelativeLayout;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.espressif.ui.adapters.NodeDetailsAdapter;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Param;
import com.espressif.ui.models.Service;
import com.espressif.ui.models.SharingRequest;
import com.google.android.material.appbar.MaterialToolbar;

import java.util.ArrayList;

public class NodeDetailsActivity extends AppCompatActivity {

    private RecyclerView nodeInfoRecyclerView;
    private ContentLoadingProgressBar progressBarNodeDetails;
    private ConstraintLayout layoutNodeDetails;
    private RelativeLayout layoutRemoveNodeLoading;

    private EspNode node;
    private EspApplication espApp;
    private ApiManager apiManager;
    private NodeDetailsAdapter nodeDetailsAdapter;
    private ArrayList<String> nodeInfoList;
    private ArrayList<String> nodeInfoValueList;
    private ArrayList<SharingRequest> pendingRequests;
    private String nodeId;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_node_details);

        nodeInfoList = new ArrayList<>();
        nodeInfoValueList = new ArrayList<>();
        pendingRequests = new ArrayList<>();
        espApp = (EspApplication) getApplicationContext();
        apiManager = ApiManager.getInstance(getApplicationContext());
        nodeId = getIntent().getStringExtra(AppConstants.KEY_NODE_ID);
        node = espApp.nodeMap.get(nodeId);
        initViews();
        setNodeInfo();

        if (BuildConfig.isNodeSharingSupported) {
            getNodeSharingInfo();
            progressBarNodeDetails.setVisibility(View.VISIBLE);
        } else {
            progressBarNodeDetails.setVisibility(View.GONE);
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        menu.add(Menu.NONE, 1, Menu.NONE, R.string.btn_remove).setShowAsAction(MenuItem.SHOW_AS_ACTION_ALWAYS);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {

            case 1:
                confirmForRemoveNode();
                return true;

            default:
                return super.onOptionsItemSelected(item);
        }
    }

    public void addPendingRequest(SharingRequest request) {
        pendingRequests.add(request);
        setNodeInfo();
    }

    public void clearPendingRequest() {
        pendingRequests.clear();
        setNodeInfo();
    }

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        getSupportActionBar().setTitle(R.string.title_activity_node_details);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        nodeInfoRecyclerView = findViewById(R.id.rv_node_details_list);
        progressBarNodeDetails = findViewById(R.id.progress_get_node_details);
        layoutNodeDetails = findViewById(R.id.layout_node_details);
        layoutRemoveNodeLoading = findViewById(R.id.rl_progress_remove_node);

        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(getApplicationContext());
        linearLayoutManager.setOrientation(RecyclerView.VERTICAL);
        nodeInfoRecyclerView.setLayoutManager(linearLayoutManager);

        nodeDetailsAdapter = new NodeDetailsAdapter(this, nodeInfoList, nodeInfoValueList, node, pendingRequests);
        nodeInfoRecyclerView.setAdapter(nodeDetailsAdapter);
    }

    private void setNodeInfo() {

        nodeInfoList.clear();
        nodeInfoValueList.clear();
        nodeInfoList.add(getString(R.string.node_id));
        nodeInfoValueList.add(node.getNodeId());

        nodeInfoList.add(getString(R.string.node_type));
        nodeInfoValueList.add(node.getNodeType());

        nodeInfoList.add(getString(R.string.node_fw_version));
        nodeInfoValueList.add(node.getFwVersion());

        // Display time zone of device.
        ArrayList<Service> services = node.getServices();
        Service tzService = null;

        for (int i = 0; i < services.size(); i++) {

            Service s = services.get(i);
            if (!TextUtils.isEmpty(s.getType()) && s.getType().equals(AppConstants.SERVICE_TYPE_TIME)) {
                tzService = s;
                break;
            }
        }

        if (tzService != null) {
            nodeInfoList.add(getString(R.string.node_timezone));
            nodeInfoValueList.add(getString(R.string.node_timezone));// TODO
        }

        // Attributes
        ArrayList<Param> attributes = node.getAttributes();

        if (attributes != null && attributes.size() > 0) {
            for (int i = 0; i < attributes.size(); i++) {
                Param param = attributes.get(i);
                nodeInfoList.add(param.getName());
                nodeInfoValueList.add(param.getLabelValue());
            }
        }

        // Sharing information
        if (BuildConfig.isNodeSharingSupported) {

            boolean shouldDisplaySharingView = true;
            String userRole = node.getUserRole();

            if (!TextUtils.isEmpty(userRole)) {
                if (!userRole.equals(AppConstants.KEY_USER_ROLE_PRIMARY)) {
                    ArrayList<String> members = node.getSecondaryUsers();
                    if (members.size() <= 0) {
                        shouldDisplaySharingView = false;
                    }
                }
            } else {
                shouldDisplaySharingView = false;
            }

            if (shouldDisplaySharingView) {
                if (AppConstants.KEY_USER_ROLE_PRIMARY.equals(userRole)) {
                    nodeInfoList.add(getString(R.string.node_shared_with));
                    nodeInfoValueList.add(getString(R.string.node_shared_with)); // Just added to maintain sequence for key and value

                    if (pendingRequests.size() > 0) {
                        nodeInfoList.add(getString(R.string.pending_requests));
                        nodeInfoValueList.add(getString(R.string.pending_requests));
                    }
                } else {
                    nodeInfoList.add(getString(R.string.node_shared_by));
                    nodeInfoValueList.add(getString(R.string.node_shared_by)); // Just added to maintain sequence for key and value
                }
            }
        }
        nodeDetailsAdapter.notifyDataSetChanged();
    }

    private void getNodeSharingInfo() {

        apiManager.getNodeSharing(node.getNodeId(), new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {

                String userRole = node.getUserRole();
                if (!TextUtils.isEmpty(userRole) && userRole.equals(AppConstants.KEY_USER_ROLE_PRIMARY)) {
                    getSharingRequests();
                } else {
                    setNodeInfo();
                    progressBarNodeDetails.setVisibility(View.GONE);
                }
            }

            @Override
            public void onResponseFailure(Exception e) {
                setNodeInfo();
                progressBarNodeDetails.setVisibility(View.GONE);
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                setNodeInfo();
                progressBarNodeDetails.setVisibility(View.GONE);
            }
        });
    }

    private void getSharingRequests() {

        apiManager.getSharingRequests(true, new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {

                if (data != null) {
                    ArrayList<SharingRequest> requests = data.getParcelableArrayList(AppConstants.KEY_SHARING_REQUESTS);
                    if (requests != null && requests.size() > 0) {
                        for (int i = 0; i < requests.size(); i++) {
                            SharingRequest req = requests.get(i);
                            if (req.getNodeIds().contains(nodeId) && AppConstants.KEY_REQ_STATUS_PENDING.equals(req.getReqStatus())) {
                                pendingRequests.add(req);
                            }
                        }
                    }
                }
                setNodeInfo();
                progressBarNodeDetails.setVisibility(View.GONE);
            }

            @Override
            public void onResponseFailure(Exception e) {
                setNodeInfo();
                progressBarNodeDetails.setVisibility(View.GONE);
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                setNodeInfo();
                progressBarNodeDetails.setVisibility(View.GONE);
            }
        });
    }

    private void showLoading() {
        layoutNodeDetails.setAlpha(0.3f);
        layoutRemoveNodeLoading.setVisibility(View.VISIBLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
    }

    private void hideLoading() {
        layoutNodeDetails.setAlpha(1);
        layoutRemoveNodeLoading.setVisibility(View.GONE);
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
    }

    private void confirmForRemoveNode() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);

        if (node.getDevices() != null && node.getDevices().size() > 1) {
            builder.setTitle(R.string.dialog_msg_delete_node);
            builder.setMessage(R.string.text_remove_node);
        } else {
            builder.setTitle(R.string.dialog_msg_delete_node);
        }

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_yes, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
                removeDevice();
            }
        });

        builder.setNegativeButton(R.string.btn_no, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
            }
        });

        AlertDialog alertDialog = builder.create();
        alertDialog.show();
    }

    private void removeDevice() {

        showLoading();
        apiManager.removeNode(node.getNodeId(), new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {
                hideLoading();
                setResult(RESULT_OK);
                finish();
            }

            @Override
            public void onResponseFailure(Exception exception) {
                hideLoading();
                exception.printStackTrace();
                if (exception instanceof CloudException) {
                    Toast.makeText(NodeDetailsActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(NodeDetailsActivity.this, R.string.error_delete_node, Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                hideLoading();
                exception.printStackTrace();
                if (exception instanceof CloudException) {
                    Toast.makeText(NodeDetailsActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(NodeDetailsActivity.this, R.string.error_delete_node, Toast.LENGTH_SHORT).show();
                }
            }
        });
    }
}
