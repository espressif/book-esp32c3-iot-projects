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

import android.app.Activity;
import android.content.DialogInterface;
import android.content.Intent;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Vibrator;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;
import android.view.HapticFeedbackConstants;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.app.NotificationManagerCompat;
import androidx.fragment.app.Fragment;
import androidx.viewpager.widget.ViewPager;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.JsonDataParser;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.db.EspDatabase;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.espressif.ui.adapters.HomeScreenPagerAdapter;
import com.espressif.ui.fragments.DevicesFragment;
import com.espressif.ui.fragments.ScenesFragment;
import com.espressif.ui.fragments.SchedulesFragment;
import com.espressif.ui.fragments.UserProfileFragment;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Group;
import com.espressif.ui.models.UpdateEvent;
import com.google.android.material.appbar.CollapsingToolbarLayout;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.snackbar.Snackbar;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

public class EspMainActivity extends AppCompatActivity {

    private static final String TAG = EspMainActivity.class.getSimpleName();

    private static final int REQUEST_LOCATION = 1;

    private CollapsingToolbarLayout collapsingToolbarLayout;
    private Toolbar appbar;
    private BottomNavigationView bottomNavigationView;
    private ViewPager viewPager;

    private Fragment deviceFragment, scheduleFragment, sceneFragment;
    private MenuItem prevMenuItem;
    private HomeScreenPagerAdapter pagerAdapter;
    private Snackbar snackbar;
    private MenuItem menuAdd;

    private ApiManager apiManager;
    private EspApplication espApp;
    private ArrayList<UiUpdateListener> updateListenerArrayList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_esp_main);

        espApp = (EspApplication) getApplicationContext();
        apiManager = ApiManager.getInstance(getApplicationContext());
        snackbar = Snackbar.make(findViewById(R.id.frame_container), R.string.msg_no_internet, Snackbar.LENGTH_INDEFINITE);

        initViews();
        loadDataFromLocalStorage();
        String reqId = getIntent().getStringExtra(AppConstants.KEY_REQ_ID);
        if (!TextUtils.isEmpty(reqId)) {
            Log.e(TAG, "Intent string is not empty");
            Log.e(TAG, "Req id : " + reqId);
            NotificationManagerCompat notificationManager = NotificationManagerCompat.from(espApp);
            notificationManager.cancel(getIntent().getIntExtra(AppConstants.KEY_ID, -1));

            ApiManager.getInstance(espApp).updateSharingRequest(reqId, true, new ApiResponseListener() {

                @Override
                public void onSuccess(Bundle data) {
                }

                @Override
                public void onResponseFailure(Exception exception) {
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                }
            });
        }
        getSupportedVersions();
        espApp.registerDeviceToken();
    }

    @Override
    protected void onResume() {
        super.onResume();
        EventBus.getDefault().register(this);
        getNodes();
    }

    @Override
    protected void onPause() {
        super.onPause();
        EventBus.getDefault().unregister(this);
    }

    @Override
    protected void onDestroy() {
        if (updateListenerArrayList != null) {
            updateListenerArrayList.clear();
        }
        espApp.stopLocalDeviceDiscovery();
        super.onDestroy();
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        super.onPrepareOptionsMenu(menu);
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.menu_toolbar, menu);
        menuAdd = menu.findItem(R.id.action_add);

        if (espApp.nodeMap.size() > 0) {
            menuAdd.setVisible(true);
        } else {
            menuAdd.setVisible(false);
        }
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {

            case R.id.action_add:
                addDeviceBtnCLick();
                return true;

            default:
                return super.onOptionsItemSelected(item);
        }
    }

    private void addDeviceBtnCLick() {

        Vibrator vib = (Vibrator) getSystemService(VIBRATOR_SERVICE);
        vib.vibrate(HapticFeedbackConstants.VIRTUAL_KEY);
        switch (bottomNavigationView.getSelectedItemId()) {
            case R.id.action_devices:
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {

                    if (!isLocationEnabled()) {
                        askForLocation();
                        return;
                    }
                }
                goToAddDeviceActivity();
                break;
            case R.id.action_schedules:
                goToAddScheduleActivity();
                break;
            case R.id.action_scenes:
                goToAddSceneActivity();
                break;
            case R.id.action_user:
                break;
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(UpdateEvent event) {

        Log.d(TAG, "Update Event Received : " + event.getEventType());

        switch (event.getEventType()) {

            case EVENT_DEVICE_ADDED:
            case EVENT_DEVICE_REMOVED:
                refreshDeviceList();
                break;

            case EVENT_STATE_CHANGE_UPDATE:
                Bundle data = event.getData();
                if (data != null) {
                    String errMsg = data.getString(AppConstants.KEY_ERROR_MSG);
                    if (!TextUtils.isEmpty(errMsg)) {
                        Toast.makeText(EspMainActivity.this, errMsg, Toast.LENGTH_SHORT).show();
                    }
                }
                updateUi();
                break;

            case EVENT_DEVICE_STATUS_UPDATE:
//                if (!espApp.getCurrentStatus().equals(GetDataStatus.FETCHING_DATA)) {
//                    updateUi();
//                }
            case EVENT_DEVICE_ONLINE:
            case EVENT_DEVICE_OFFLINE:
                updateUi();
                break;

            case EVENT_LOCAL_DEVICE_UPDATE:
                updateUi();
                break;
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        switch (requestCode) {

            case REQUEST_LOCATION:

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {

                    if (isLocationEnabled()) {
                        goToAddDeviceActivity();
                    }
                }
                break;
        }
    }

    BottomNavigationView.OnNavigationItemSelectedListener navigationItemSelectedListener = new BottomNavigationView.OnNavigationItemSelectedListener() {

        @Override
        public boolean onNavigationItemSelected(@NonNull MenuItem menuItem) {

            String title = menuItem.getTitle().toString();
            collapsingToolbarLayout.setTitle(title);
            int pageIndex = pagerAdapter.getItemPosition(title);
            viewPager.setCurrentItem(pageIndex);
            updateActionBar();
            updateUi();
            return true;
        }
    };

    public void setUpdateListener(UiUpdateListener updateListener) {
        updateListenerArrayList.add(updateListener);
    }

    public void removeUpdateListener(UiUpdateListener updateListener) {
        updateListenerArrayList.remove(updateListener);
    }

    public void refreshDeviceList() {
        getNodes();
    }

    public void updateActionBar() {

        if (menuAdd != null) {
            switch (bottomNavigationView.getSelectedItemId()) {
                case R.id.action_devices:
                    if (espApp.nodeMap.size() > 0) {
                        menuAdd.setVisible(true);
                    } else {
                        menuAdd.setVisible(false);
                    }
                    break;
                case R.id.action_schedules:
                    if (espApp.scheduleMap.size() > 0) {
                        menuAdd.setVisible(true);
                    } else {
                        menuAdd.setVisible(false);
                    }
                    break;
                case R.id.action_scenes:
                    if (espApp.sceneMap.size() > 0) {
                        menuAdd.setVisible(true);
                    } else {
                        menuAdd.setVisible(false);
                    }
                    break;
                case R.id.action_user:
                    menuAdd.setVisible(false);
                    break;
            }
        }
    }

    private void initViews() {

        collapsingToolbarLayout = findViewById(R.id.collapsing_toolbar_layout);
        collapsingToolbarLayout.setTitle(getResources().getString(R.string.devices_title));
        appbar = findViewById(R.id.appbar);
        setSupportActionBar(appbar);

        bottomNavigationView = findViewById(R.id.bottom_navigation_view);
        Menu menu = bottomNavigationView.getMenu();
        if (!BuildConfig.isScheduleSupported) {
            menu.removeItem(R.id.action_schedules);
        }
        if (!BuildConfig.isSceneSupported) {
            menu.removeItem(R.id.action_scenes);
        }

        viewPager = findViewById(R.id.view_pager);
        bottomNavigationView.setOnNavigationItemSelectedListener(navigationItemSelectedListener);
        setupViewPager();
    }

    private void setupViewPager() {

        pagerAdapter = new HomeScreenPagerAdapter(getSupportFragmentManager(), this);
        deviceFragment = new DevicesFragment();
        pagerAdapter.addFragment(deviceFragment);

        if (BuildConfig.isScheduleSupported) {
            scheduleFragment = new SchedulesFragment();
            pagerAdapter.addFragment(scheduleFragment);
        }

        if (BuildConfig.isSceneSupported) {
            sceneFragment = new ScenesFragment();
            pagerAdapter.addFragment(sceneFragment);
        }
        pagerAdapter.addFragment(new UserProfileFragment());
        viewPager.setAdapter(pagerAdapter);
        viewPager.addOnPageChangeListener(pageChangeListener);
    }

    ViewPager.OnPageChangeListener pageChangeListener = new ViewPager.OnPageChangeListener() {

        @Override
        public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
        }

        @Override
        public void onPageSelected(int position) {

            if (prevMenuItem != null) {
                prevMenuItem.setChecked(false);
            } else {
                bottomNavigationView.getMenu().getItem(0).setChecked(false);
            }
            bottomNavigationView.getMenu().getItem(position).setChecked(true);
            prevMenuItem = bottomNavigationView.getMenu().getItem(position);
            String title = bottomNavigationView.getMenu().getItem(position).getTitle().toString();
            collapsingToolbarLayout.setTitle(title);
            updateActionBar();
            updateUi();
        }

        @Override
        public void onPageScrollStateChanged(int state) {
        }
    };

    private void updateUi() {

        switch (espApp.getAppState()) {

            case NO_INTERNET:
                if (snackbar == null) {
                    snackbar = Snackbar.make(findViewById(R.id.frame_container), R.string.msg_no_internet, Snackbar.LENGTH_INDEFINITE);
                }
                Log.e(TAG, "Display No internet");
                snackbar.show();
                break;

            case GET_DATA_SUCCESS:
                snackbar.dismiss();
                updateActionBar();
                break;

            case GET_DATA_FAILED:
                snackbar.dismiss();
                // TODO Display toast
//                for (Map.Entry<String, EspNode> entry : espApp.nodeMap.entrySet()) {
//
//                    EspNode node = entry.getValue();
//
//                    if (node != null && !espApp.localDeviceMap.containsKey(node.getNodeId())) {
////                        node.setOnline(false);
//                    }
//                }
                break;

            case GETTING_DATA:
            case REFRESH_DATA:
                break;

            case NO_USER_LOGIN:
                finish();
                return;
        }

        if (updateListenerArrayList != null) {
            for (UiUpdateListener listener : updateListenerArrayList) {
                listener.updateUi();
            }
        }
    }

    private void getSupportedVersions() {

        apiManager.getSupportedVersions(new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {

                String updateMsg = data.getString(AppConstants.KEY_ADDITIONAL_INFO);
                ArrayList<String> versions = data.getStringArrayList(AppConstants.KEY_SUPPORTED_VERSIONS);

                if (!versions.contains(AppConstants.CURRENT_VERSION)) {
                    alertForForceUpdate(updateMsg);
                } else {

                    int currentVersion = getVersionNumber(AppConstants.CURRENT_VERSION);

                    for (int i = 0; i < versions.size(); i++) {

                        int version = getVersionNumber(versions.get(i));

                        if (version > currentVersion) {

                            // TODO Make flag true once alert is shown so that update popup will not come every time.
                            if (!TextUtils.isEmpty(updateMsg)) {
                                alertForNewVersion(updateMsg);
                            } else {
                                alertForNewVersion("");
                            }
                            break;
                        }
                    }
                }
                getNodes();
            }

            @Override
            public void onResponseFailure(Exception exception) {
                Bundle data = new Bundle();
                data.putString(AppConstants.KEY_ERROR_MSG, exception.getMessage());
                espApp.changeAppState(EspApplication.AppState.GET_DATA_FAILED, data);
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                espApp.changeAppState(EspApplication.AppState.NO_INTERNET, null);
            }
        });
    }

    private int getVersionNumber(String versionString) {

        versionString = versionString.replace("v", "");
        int version = Integer.valueOf(versionString);
        return version;
    }

    private void loadDataFromLocalStorage() {

        EspDatabase espDatabase = EspDatabase.getInstance(getApplicationContext());
        ArrayList<EspNode> nodeList = (ArrayList<EspNode>) espDatabase.getNodeDao().getNodesFromStorage();

        for (int nodeIndex = 0; nodeIndex < nodeList.size(); nodeIndex++) {

            EspNode node = nodeList.get(nodeIndex);

            if (node != null) {

                String configData = node.getConfigData();
                String paramData = node.getParamData();

                if (configData != null) {
                    try {
                        node = JsonDataParser.setNodeConfig(node, new JSONObject(configData));
                        if (paramData != null) {
                            JSONObject paramsJson = new JSONObject(paramData);
                            JsonDataParser.setAllParams(espApp, node, paramsJson);
                        } else {
                            Log.e(TAG, "Param configuration is not available.");
                        }
                        espApp.nodeMap.put(node.getNodeId(), node);

                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } else {
                    Log.e(TAG, "Node configuration is not available.");
                }
            }
        }

        // Set all devices offline
//        for (Map.Entry<String, EspNode> entry : espApp.nodeMap.entrySet()) {
//
//            String key = entry.getKey();
//            EspNode node = entry.getValue();
//
//            if (node != null) {
//                node.setOnline(false);
//                ArrayList<Device> espDevices = node.getDevices();
//                devices.addAll(espDevices);
//            }
//        }

        if (BuildConfig.isNodeGroupingSupported) {
            ArrayList<Group> groupList = (ArrayList<Group>) espDatabase.getGroupDao().getGroupsFromStorage();
            for (int groupIndex = 0; groupIndex < groupList.size(); groupIndex++) {

                Group group = groupList.get(groupIndex);
                if (group != null) {
                    espApp.groupMap.put(group.getGroupId(), group);
                }
            }
        }
        Log.d(TAG, "Node list size from local storage : " + espApp.nodeMap.size());
    }

    private void getNodes() {
        espApp.refreshData();
    }

    private void goToAddDeviceActivity() {

        if (BuildConfig.isQRCodeSupported) {
            Intent intent = new Intent(this, AddDeviceActivity.class);
            startActivity(intent);
        } else {

            boolean isSec1 = true;
            ESPProvisionManager provisionManager = ESPProvisionManager.getInstance(getApplicationContext());

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
                Toast.makeText(this, R.string.error_device_type_not_supported, Toast.LENGTH_LONG).show();
            }
        }
    }

    private void goToAddScheduleActivity() {

        Intent intent = new Intent(this, AddScheduleActivity.class);
        startActivity(intent);
    }

    private void goToAddSceneActivity() {

        Intent intent = new Intent(this, SceneDetailActivity.class);
        startActivity(intent);
    }

    private void askForDeviceType(final boolean isSec1) {

        final String[] deviceTypes = getResources().getStringArray(R.array.prov_transport_types);
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(true);
        builder.setTitle(R.string.dialog_msg_device_selection);
        final ESPProvisionManager provisionManager = ESPProvisionManager.getInstance(getApplicationContext());

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

        Intent intent = new Intent(getApplicationContext(), BLEProvisionLanding.class);
        if (isSec1) {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_1);
        } else {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_0);
        }
        startActivity(intent);
    }

    private void goToWiFiProvisionLanding(boolean isSec1) {

        Intent intent = new Intent(getApplicationContext(), ProvisionLanding.class);
        if (isSec1) {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_1);
        } else {
            intent.putExtra(AppConstants.KEY_SECURITY_TYPE, AppConstants.SECURITY_0);
        }
        startActivity(intent);
    }

    private void alertForForceUpdate(String message) {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(false);

        builder.setTitle(R.string.dialog_title_new_version_available);
        builder.setMessage(message);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_update, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                final String appPackageName = getPackageName(); // getPackageName() from Context or Activity object
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + appPackageName)));
                } catch (android.content.ActivityNotFoundException anfe) {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=" + appPackageName)));
                }
            }
        });
        builder.show();
    }

    private void alertForNewVersion(String message) {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(true);

        builder.setTitle(R.string.dialog_title_new_version_available);
        builder.setMessage(message);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_update, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                final String appPackageName = getPackageName(); // getPackageName() from Context or Activity object
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + appPackageName)));
                } catch (android.content.ActivityNotFoundException anfe) {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=" + appPackageName)));
                }
            }
        });

        builder.setNegativeButton(R.string.btn_cancel, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
            }
        });

        builder.show();
    }

    private void askForLocation() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(true);
        builder.setMessage(R.string.dialog_msg_for_gps);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_ok, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                startActivityForResult(new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS), REQUEST_LOCATION);
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
        LocationManager lm = (LocationManager) getApplicationContext().getSystemService(Activity.LOCATION_SERVICE);

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

    public interface UiUpdateListener {
        void updateUi();
    }
}
