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

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.NetworkApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.local_control.EspLocalDevice;
import com.espressif.rainmaker.R;
import com.espressif.ui.adapters.AttrParamAdapter;
import com.espressif.ui.adapters.ParamAdapter;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.Param;
import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.snackbar.Snackbar;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;

public class EspDeviceActivity extends AppCompatActivity {

    private static final String TAG = EspDeviceActivity.class.getSimpleName();

    private static final int NODE_DETAILS_ACTIVITY_REQUEST = 10;
    private static final int UPDATE_INTERVAL = 5000;

    private RelativeLayout rlNodeStatus;
    private TextView tvNoParam, tvNodeStatus;
    private ImageView ivSecureLocal;
    private RecyclerView paramRecyclerView;
    private RecyclerView attrRecyclerView;
    private SwipeRefreshLayout swipeRefreshLayout;
    private Snackbar snackbar;

    private Device device;
    private EspApplication espApp;
    private NetworkApiManager networkApiManager;
    private ParamAdapter paramAdapter;
    private AttrParamAdapter attrAdapter;
    private ArrayList<Param> paramList;
    private ArrayList<Param> attributeList;
    private Handler handler;
    private ContentLoadingProgressBar progressBar;
    private boolean isNodeOnline;
    private long timeStampOfStatus;
    private boolean isNetworkAvailable = true;
    private boolean shouldGetParams = true;
    private RelativeLayout rlProgress, rlParam;

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_esp_device);

        espApp = (EspApplication) getApplicationContext();
        networkApiManager = new NetworkApiManager(getApplicationContext());
        device = getIntent().getParcelableExtra(AppConstants.KEY_ESP_DEVICE);
        handler = new Handler();
        isNodeOnline = espApp.nodeMap.get(device.getNodeId()).isOnline();
        timeStampOfStatus = espApp.nodeMap.get(device.getNodeId()).getTimeStampOfStatus();
        snackbar = Snackbar.make(findViewById(R.id.params_parent_layout), R.string.msg_no_internet, Snackbar.LENGTH_INDEFINITE);
        ArrayList<Param> espDeviceParams = device.getParams();
        setParamList(espDeviceParams);

        initViews();
        updateUi();
    }

    @Override
    protected void onResume() {
        super.onResume();
        getNodeDetails();
    }

    @Override
    protected void onPause() {
        super.onPause();
        stopUpdateValueTask();
    }

    @Override
    protected void onDestroy() {
        stopUpdateValueTask();
        super.onDestroy();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        menu.add(Menu.NONE, 1, Menu.NONE, R.string.btn_info).setIcon(R.drawable.ic_node_info).setShowAsAction(MenuItem.SHOW_AS_ACTION_ALWAYS);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {

            case 1:
                goToNodeDetailsActivity();
                return true;

            default:
                return super.onOptionsItemSelected(item);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == NODE_DETAILS_ACTIVITY_REQUEST && resultCode == RESULT_OK) {
            finish();
        }
    }

    public void updateDeviceNameInTitle(String deviceName) {
        getSupportActionBar().setTitle(deviceName);
    }

    public boolean isNodeOnline() {
        return isNodeOnline;
    }

    public void startUpdateValueTask() {
        shouldGetParams = true;
        handler.removeCallbacks(updateValuesTask);
        handler.postDelayed(updateValuesTask, UPDATE_INTERVAL);
    }

    public void stopUpdateValueTask() {
        shouldGetParams = false;
        handler.removeCallbacks(updateValuesTask);
    }

    private void goToNodeDetailsActivity() {
        Intent intent = new Intent(EspDeviceActivity.this, NodeDetailsActivity.class);
        intent.putExtra(AppConstants.KEY_NODE_ID, device.getNodeId());
        startActivityForResult(intent, NODE_DETAILS_ACTIVITY_REQUEST);
    }

    private Runnable updateValuesTask = new Runnable() {

        @Override
        public void run() {
            if (shouldGetParams) {
                getValues();
            }
        }
    };

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        tvNoParam = findViewById(R.id.tv_no_params);
        progressBar = findViewById(R.id.progress_get_params);

        rlParam = findViewById(R.id.params_parent_layout);
        rlProgress = findViewById(R.id.rl_progress);

        rlNodeStatus = findViewById(R.id.rl_node_status);
        tvNodeStatus = findViewById(R.id.tv_device_status);
        ivSecureLocal = findViewById(R.id.iv_secure_local);

        getSupportActionBar().setTitle(device.getUserVisibleName());

        paramRecyclerView = findViewById(R.id.rv_dynamic_param_list);
        attrRecyclerView = findViewById(R.id.rv_static_param_list);
        swipeRefreshLayout = findViewById(R.id.swipe_container);

        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(getApplicationContext());
        linearLayoutManager.setOrientation(RecyclerView.VERTICAL);
        paramRecyclerView.setLayoutManager(linearLayoutManager);

        LinearLayoutManager linearLayoutManager1 = new LinearLayoutManager(getApplicationContext());
        linearLayoutManager1.setOrientation(RecyclerView.VERTICAL);
        attrRecyclerView.setLayoutManager(linearLayoutManager1);

        paramAdapter = new ParamAdapter(this, device, paramList);
        paramRecyclerView.setAdapter(paramAdapter);

        attrAdapter = new AttrParamAdapter(this, device.getNodeId(), device.getDeviceName(), attributeList);
        attrRecyclerView.setAdapter(attrAdapter);

        swipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {

            @Override
            public void onRefresh() {
                getNodeDetails();
            }
        });
    }

    private void getNodeDetails() {

        stopUpdateValueTask();

        networkApiManager.getNodeDetails(device.getNodeId(), new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {

                        isNetworkAvailable = true;
                        hideLoading();
                        snackbar.dismiss();
                        swipeRefreshLayout.setRefreshing(false);
                        updateUi();
                        startUpdateValueTask();
                    }
                });
            }

            @Override
            public void onResponseFailure(Exception exception) {

                isNetworkAvailable = true;
                hideLoading();
                snackbar.dismiss();
                swipeRefreshLayout.setRefreshing(false);
                if (exception instanceof CloudException) {
                    Toast.makeText(EspDeviceActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(EspDeviceActivity.this, "Failed to get node details", Toast.LENGTH_SHORT).show();
                }
                updateUi();
            }

            @Override
            public void onNetworkFailure(Exception exception) {

                hideLoading();
                swipeRefreshLayout.setRefreshing(false);
                if (exception instanceof CloudException) {
                    Toast.makeText(EspDeviceActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(EspDeviceActivity.this, "Failed to get node details", Toast.LENGTH_SHORT).show();
                }
                updateUi();
            }
        });
    }

    private void getValues() {

        networkApiManager.getParamsValues(device.getNodeId(), new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        isNetworkAvailable = true;
                        hideLoading();
                        swipeRefreshLayout.setRefreshing(false);
                        updateUi();
                        handler.postDelayed(updateValuesTask, UPDATE_INTERVAL);
                    }
                });
            }

            @Override
            public void onResponseFailure(Exception exception) {

                stopUpdateValueTask();
                isNetworkAvailable = true;
                hideLoading();
                swipeRefreshLayout.setRefreshing(false);
                if (exception instanceof CloudException) {
                    Toast.makeText(EspDeviceActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(EspDeviceActivity.this, "Failed to get param values", Toast.LENGTH_SHORT).show();
                }
                updateUi();
            }

            @Override
            public void onNetworkFailure(Exception exception) {

                stopUpdateValueTask();
                hideLoading();
                swipeRefreshLayout.setRefreshing(false);
                if (exception instanceof CloudException) {
                    Toast.makeText(EspDeviceActivity.this, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(EspDeviceActivity.this, "Failed to get param values", Toast.LENGTH_SHORT).show();
                }
                updateUi();
            }
        });
    }

    private void setParamList(ArrayList<Param> paramArrayList) {

        if (paramList == null || attributeList == null) {

            paramList = new ArrayList<>();
            attributeList = new ArrayList<>();
        }

        for (int i = 0; i < paramArrayList.size(); i++) {

            Param updatedParam = paramArrayList.get(i);
            boolean isFound = false;

            if (updatedParam.isDynamicParam()) {

                for (int j = 0; j < paramList.size(); j++) {

                    if (paramList.get(j).getName() != null && paramList.get(j).getName().equals(updatedParam.getName())) {

                        isFound = true;
                        paramList.set(j, updatedParam);
                        break;
                    }
                }

                if (!isFound) {
                    paramList.add(updatedParam);
                }

            } else {

                for (int j = 0; j < attributeList.size(); j++) {

                    if (attributeList.get(j).getName() != null && attributeList.get(j).getName().equals(updatedParam.getName())) {

                        isFound = true;
                        attributeList.set(j, updatedParam);
                        break;
                    }
                }

                if (!isFound) {
                    attributeList.add(updatedParam);
                }
            }
        }
    }

    private void updateUi() {

        boolean deviceFound = false;
        if (espApp.nodeMap.containsKey(device.getNodeId())) {

            ArrayList<Device> devices = espApp.nodeMap.get(device.getNodeId()).getDevices();
            isNodeOnline = espApp.nodeMap.get(device.getNodeId()).isOnline();
            timeStampOfStatus = espApp.nodeMap.get(device.getNodeId()).getTimeStampOfStatus();

            for (int i = 0; i < devices.size(); i++) {

                if (device.getDeviceName().equals(devices.get(i).getDeviceName())) {

                    device = devices.get(i);
                    deviceFound = true;
                    break;
                }
            }

        } else {
            Log.e(TAG, "Node does not exist in list. It may be deleted.");
            finish();
            return;
        }

        if (!deviceFound) {
            Log.e(TAG, "Device does not exist in node.");
            finish();
            return;
        }

        ArrayList<Param> espDeviceParams = device.getParams();
        setParamList(espDeviceParams);

        if (!isNodeOnline) {

            if (espApp.getAppState().equals(EspApplication.AppState.GET_DATA_SUCCESS)) {

                rlNodeStatus.setVisibility(View.VISIBLE);

                if (espApp.localDeviceMap.containsKey(device.getNodeId())) {

                    EspLocalDevice localDevice = espApp.localDeviceMap.get(device.getNodeId());
                    if (localDevice.getSecurityType() == 1) {
                        ivSecureLocal.setVisibility(View.VISIBLE);
                    } else {
                        ivSecureLocal.setVisibility(View.GONE);
                    }
                    tvNodeStatus.setText(R.string.local_device_text);

                } else {
                    ivSecureLocal.setVisibility(View.GONE);
                    String offlineText = getString(R.string.status_offline);
                    tvNodeStatus.setText(offlineText);

                    if (timeStampOfStatus != 0) {

                        Calendar calendar = Calendar.getInstance();
                        int day = calendar.get(Calendar.DATE);

                        calendar.setTimeInMillis(timeStampOfStatus);
                        int offlineDay = calendar.get(Calendar.DATE);

                        if (day == offlineDay) {

                            SimpleDateFormat formatter = new SimpleDateFormat("HH:mm");
                            String time = formatter.format(calendar.getTime());
                            offlineText = getString(R.string.offline_at) + " " + time;

                        } else {

                            SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yy, HH:mm");
                            String time = formatter.format(calendar.getTime());
                            offlineText = getString(R.string.offline_at) + " " + time;
                        }
                        tvNodeStatus.setText(offlineText);
                    }
                }
            } else {
                rlNodeStatus.setVisibility(View.INVISIBLE);
            }

        } else {

            if (espApp.localDeviceMap.containsKey(device.getNodeId())) {

                rlNodeStatus.setVisibility(View.VISIBLE);
                EspLocalDevice localDevice = espApp.localDeviceMap.get(device.getNodeId());
                if (localDevice.getSecurityType() == 1) {
                    ivSecureLocal.setVisibility(View.VISIBLE);
                } else {
                    ivSecureLocal.setVisibility(View.GONE);
                }
                tvNodeStatus.setText(R.string.local_device_text);
            } else {
                rlNodeStatus.setVisibility(View.INVISIBLE);
            }
        }

        paramAdapter.updateList(paramList);
        paramAdapter.notifyDataSetChanged();

        attrAdapter.updateList(attributeList);
        attrAdapter.notifyDataSetChanged();

        if (paramList.size() <= 0 && attributeList.size() <= 0) {

            tvNoParam.setVisibility(View.VISIBLE);
            paramRecyclerView.setVisibility(View.GONE);
            attrRecyclerView.setVisibility(View.GONE);

        } else {

            tvNoParam.setVisibility(View.GONE);
            paramRecyclerView.setVisibility(View.VISIBLE);
            attrRecyclerView.setVisibility(View.VISIBLE);
        }

        getSupportActionBar().setTitle(device.getUserVisibleName());

        if (!isNetworkAvailable) {
            if (!snackbar.isShown()) {
                snackbar = Snackbar.make(findViewById(R.id.params_parent_layout), R.string.msg_no_internet, Snackbar.LENGTH_INDEFINITE);
            }
            snackbar.show();
        }
    }

    private void showLoading() {

        progressBar.setVisibility(View.VISIBLE);
        swipeRefreshLayout.setVisibility(View.GONE);
    }

    private void hideLoading() {

        progressBar.setVisibility(View.GONE);
        swipeRefreshLayout.setVisibility(View.VISIBLE);
    }

    public void showParamUpdateLoading(String msg) {
        rlParam.setAlpha(0.3f);
        rlProgress.setVisibility(View.VISIBLE);
        TextView progressText = findViewById(R.id.tv_loading);
        progressText.setText(msg);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
    }

    public void hideParamUpdateLoading() {
        rlParam.setAlpha(1);
        rlProgress.setVisibility(View.GONE);
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
    }
}
