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

package com.espressif;

import android.app.Application;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.db.EspDatabase;
import com.espressif.local_control.LocalControlApiManager;
import com.espressif.local_control.EspLocalDevice;
import com.espressif.local_control.mDNSManager;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.ConsentActivity;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Group;
import com.espressif.ui.models.Param;
import com.espressif.ui.models.Scene;
import com.espressif.ui.models.Schedule;
import com.espressif.ui.models.Service;
import com.espressif.ui.models.UpdateEvent;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.messaging.FirebaseMessaging;

import org.greenrobot.eventbus.EventBus;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;

public class EspApplication extends Application {

    private static final String TAG = EspApplication.class.getSimpleName();

    private AppState appState = AppState.NO_USER_LOGIN;

    public HashMap<String, EspNode> nodeMap;
    public HashMap<String, Schedule> scheduleMap;
    public HashMap<String, Scene> sceneMap;
    public HashMap<String, EspLocalDevice> localDeviceMap;
    public HashMap<String, Group> groupMap;

    private SharedPreferences appPreferences;
    private ApiManager apiManager;
    private mDNSManager mdnsManager;
    private String deviceToken;

    public enum AppState {
        NO_USER_LOGIN,
        GETTING_DATA,
        GET_DATA_SUCCESS,
        GET_DATA_FAILED,
        NO_INTERNET,
        REFRESH_DATA
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "ESP Application is created");
        nodeMap = new HashMap<>();
        scheduleMap = new HashMap<>();
        sceneMap = new HashMap<>();
        localDeviceMap = new HashMap<>();
        groupMap = new HashMap<>();
        appPreferences = getSharedPreferences(AppConstants.ESP_PREFERENCES, Context.MODE_PRIVATE);
        apiManager = ApiManager.getInstance(this);
        ESPProvisionManager.getInstance(this);
        if (BuildConfig.isLocalControlSupported) {
            mdnsManager = mDNSManager.getInstance(getApplicationContext(), AppConstants.MDNS_SERVICE_TYPE, listener);
        }

        if (isPlayServicesAvailable()) {
            FirebaseMessaging.getInstance().setAutoInitEnabled(false);
            setupNotificationChannels();
        }
    }

    public AppState getAppState() {
        return appState;
    }

    public void changeAppState(AppState newState, Bundle extras) {

        switch (newState) {
            case GETTING_DATA:
                if (BuildConfig.isLocalControlSupported) {
                    mdnsManager.initializeNsd();
                }
            case REFRESH_DATA:
                if (!appState.equals(newState)) {
                    appState = newState;
                    getNodesFromCloud();
                }
                EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_STATE_CHANGE_UPDATE));
                break;

            case GET_DATA_FAILED:
                appState = newState;
                UpdateEvent updateEvent = new UpdateEvent(AppConstants.UpdateEventType.EVENT_STATE_CHANGE_UPDATE);
                if (extras != null) {
                    updateEvent.setData(extras);
                }
                EventBus.getDefault().post(updateEvent);
                startLocalDeviceDiscovery();
                break;

            case NO_USER_LOGIN:
                Intent loginActivity = new Intent(this, ConsentActivity.class);
                loginActivity.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP
                        | Intent.FLAG_ACTIVITY_CLEAR_TASK
                        | Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(loginActivity);
                appState = newState;
                EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_STATE_CHANGE_UPDATE));
                break;

            case GET_DATA_SUCCESS:
            case NO_INTERNET:
                appState = newState;
                EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_STATE_CHANGE_UPDATE));
                startLocalDeviceDiscovery();
                break;
        }
    }

    private void getNodesFromCloud() {

        apiManager.getNodes(new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {

                if (BuildConfig.isNodeGroupingSupported) {

                    apiManager.getUserGroups(null, new ApiResponseListener() {

                        @Override
                        public void onSuccess(Bundle data) {
                            changeAppState(AppState.GET_DATA_SUCCESS, null);
                        }

                        @Override
                        public void onResponseFailure(Exception exception) {
                            Bundle data = new Bundle();
                            data.putString(AppConstants.KEY_ERROR_MSG, exception.getMessage());
                            changeAppState(EspApplication.AppState.GET_DATA_FAILED, data);
                        }

                        @Override
                        public void onNetworkFailure(Exception exception) {
                            changeAppState(AppState.NO_INTERNET, null);
                        }
                    });
                } else {
                    changeAppState(AppState.GET_DATA_SUCCESS, null);
                }
            }

            @Override
            public void onResponseFailure(Exception exception) {
                Bundle data = new Bundle();
                data.putString(AppConstants.KEY_ERROR_MSG, exception.getMessage());
                changeAppState(EspApplication.AppState.GET_DATA_FAILED, data);
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                changeAppState(AppState.NO_INTERNET, null);
            }
        });
    }

    public void refreshData() {
        if (!appState.equals(AppState.GETTING_DATA)) {
            changeAppState(AppState.REFRESH_DATA, null);
        }
    }

    public void loginSuccess() {
        clearData();
    }

    public void registerDeviceToken() {

        if (!isPlayServicesAvailable()) {
            Log.e(TAG, "Google Play Services not available.");
            return;
        }
        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(new OnCompleteListener<String>() {

            @Override
            public void onComplete(@NonNull Task<String> task) {
                if (!task.isSuccessful()) {
                    Log.d(TAG, "Fetching FCM registration token failed", task.getException());
                    return;
                }

                // Get new FCM registration token
                deviceToken = task.getResult();

                // Log and toast
                Log.e("FCM TOKEN  ", deviceToken);

                if (!TextUtils.isEmpty(deviceToken)) {
                    apiManager.registerDeviceToken(deviceToken, new ApiResponseListener() {
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
            }
        });
    }

    public void logout() {

        if (appState.equals(AppState.NO_USER_LOGIN)) {
            return;
        }

        // Do logout and clear all data
        if (!ApiManager.isOAuthLogin) {

            apiManager.logout(new ApiResponseListener() {

                @Override
                public void onSuccess(Bundle data) {
                }

                @Override
                public void onResponseFailure(Exception exception) {
                    // Ignore failure
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                    // Ignore failure
                }
            });
        }

        if (isPlayServicesAvailable()) {
            // Delete endpoint API
            apiManager.unregisterDeviceToken(deviceToken, new ApiResponseListener() {
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
        clearUserSession();
    }

    public void clearUserSession() {

        clearData();
        SharedPreferences.Editor editor = appPreferences.edit();
        editor.clear();
        editor.apply();

        SharedPreferences wifiNetworkPref = getSharedPreferences(AppConstants.PREF_FILE_WIFI_NETWORKS, Context.MODE_PRIVATE);
        SharedPreferences.Editor wifiNetworkEditor = wifiNetworkPref.edit();
        wifiNetworkEditor.clear();
        wifiNetworkEditor.apply();

        if (isPlayServicesAvailable()) {
            FirebaseMessaging.getInstance().deleteToken();
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.cancelAll();
        }

        Log.e(TAG, "Deleted all things from local storage.");
        changeAppState(AppState.NO_USER_LOGIN, null);
    }

    private void clearData() {
        EspDatabase.getInstance(this).getNodeDao().deleteAll();
        EspDatabase.getInstance(this).getGroupDao().deleteAll();
        EspDatabase.getInstance(this).getNotificationDao().deleteAll();
        nodeMap.clear();
        scheduleMap.clear();
        sceneMap.clear();
        localDeviceMap.clear();
        groupMap.clear();
    }

    private void startLocalDeviceDiscovery() {
        if (BuildConfig.isLocalControlSupported) {
            if (nodeMap.size() > 0) {
                mdnsManager.discoverServices();
            }
        }
    }

    public void stopLocalDeviceDiscovery() {
        if (BuildConfig.isLocalControlSupported) {
            mdnsManager.stopDiscovery();
        }
    }

    mDNSManager.mDNSEvenListener listener = new mDNSManager.mDNSEvenListener() {

        @Override
        public void deviceFound(EspLocalDevice newDevice) {

            Log.e(TAG, "Device Found on Local Network");
            final LocalControlApiManager localControlApiManager = new LocalControlApiManager(getApplicationContext());
            final String nodeId = newDevice.getNodeId();
            EspNode node = nodeMap.get(nodeId);
            Service localService = null;

            if (node == null) {
                Log.e(TAG, "Node is not available with id : " + nodeId);
//                return;
            } else {
                newDevice.setNodeId(nodeId);
                ArrayList<Service> services = node.getServices();

                for (int i = 0; i < services.size(); i++) {
                    Service s = services.get(i);
                    if (!TextUtils.isEmpty(s.getType()) && s.getType().equals(AppConstants.SERVICE_TYPE_LOCAL_CONTROL)) {
                        localService = s;
                        break;
                    }
                }
            }

            Log.e(TAG, "Found node " + nodeId + " on local network.");
            if (localDeviceMap.containsKey(nodeId)) {
                Log.e(TAG, "Local Device session is already available");
                newDevice = localDeviceMap.get(nodeId);
            }

            if (localService != null) {
                ArrayList<Param> popParams = localService.getParams();
                if (popParams != null) {
                    for (int paramIdx = 0; paramIdx < popParams.size(); paramIdx++) {
                        Param popParam = popParams.get(paramIdx);
                        if (AppConstants.PARAM_TYPE_LOCAL_CONTROL_POP.equalsIgnoreCase(popParam.getParamType())) {
                            String popValue = popParam.getLabelValue();
                            newDevice.setPop(popValue);
                        } else if (AppConstants.PARAM_TYPE_LOCAL_CONTROL_TYPE.equalsIgnoreCase(popParam.getParamType())) {
                            int type = (int) popParam.getValue();
                            newDevice.setSecurityType(type);
                        }
                    }
                }
            }

            final EspLocalDevice localDevice = newDevice;
            localControlApiManager.getPropertyCount(AppConstants.LOCAL_CONTROL_ENDPOINT, localDevice, new ApiResponseListener() {

                @Override
                public void onSuccess(Bundle data) {

                    if (data != null) {

                        int count = data.getInt(AppConstants.KEY_PROPERTY_COUNT, 0);
                        localDevice.setPropertyCount(count);

                        localControlApiManager.getPropertyValues(AppConstants.LOCAL_CONTROL_ENDPOINT, localDevice, new ApiResponseListener() {

                            @Override
                            public void onSuccess(Bundle data) {

                                if (data != null) {

                                    String configData = data.getString(AppConstants.KEY_CONFIG);
                                    String paramsData = data.getString(AppConstants.KEY_PARAMS);

                                    Log.d(TAG, "Config data : " + configData);
                                    Log.d(TAG, "Params data : " + paramsData);

                                    if (!TextUtils.isEmpty(configData)) {

                                        JSONObject configJson = null;
                                        try {
                                            configJson = new JSONObject(configData);
                                        } catch (JSONException e) {
                                            e.printStackTrace();
                                        }

                                        String id = configJson.optString(AppConstants.KEY_NODE_ID);
                                        EspNode node = nodeMap.get(id);
                                        boolean isDeviceFound = false;
                                        if (node != null) {
                                            isDeviceFound = true;
                                        }
                                        EspNode localNode = JsonDataParser.setNodeConfig(node, configJson);

                                        if (node != null) {
                                            Log.e(TAG, "Found node " + localNode.getNodeId() + " on local network.");
                                            isDeviceFound = true;
                                            localNode.setAvailableLocally(true);
                                            localNode.setIpAddress(localDevice.getIpAddr());
                                            localNode.setPort(localDevice.getPort());
                                            localNode.setOnline(true);
                                            localDeviceMap.put(localNode.getNodeId(), localDevice);
                                        }

                                        if (!TextUtils.isEmpty(paramsData) && isDeviceFound) {

                                            JSONObject paramsJson = null;
                                            try {
                                                paramsJson = new JSONObject(paramsData);
                                            } catch (JSONException e) {
                                                e.printStackTrace();
                                            }
                                            JsonDataParser.setAllParams(EspApplication.this, localNode, paramsJson);
                                            nodeMap.put(localNode.getNodeId(), localNode);
                                            EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_LOCAL_DEVICE_UPDATE));
                                        }
                                    }
                                }
                            }

                            @Override
                            public void onResponseFailure(Exception exception) {
                                // Nothing to do
                            }

                            @Override
                            public void onNetworkFailure(Exception exception) {
                                // Nothing to do
                            }
                        });
                    }
                }

                @Override
                public void onResponseFailure(Exception exception) {
                    // Nothing to do
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                    // Nothing to do
                }
            });
        }
    };

    private void setupNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            NotificationChannel nodeConnectedChannel = new NotificationChannel(AppConstants.CHANNEL_NODE_ONLINE_ID,
                    getString(R.string.channel_node_connected), NotificationManager.IMPORTANCE_HIGH);

            NotificationChannel nodeDisconnectedChannel = new NotificationChannel(AppConstants.CHANNEL_NODE_OFFLINE_ID,
                    getString(R.string.channel_node_disconnected), NotificationManager.IMPORTANCE_HIGH);

            NotificationChannel nodeAddedChannel = new NotificationChannel(AppConstants.CHANNEL_NODE_ADDED,
                    getString(R.string.channel_node_added), NotificationManager.IMPORTANCE_HIGH);

            NotificationChannel nodeRemovedChannel = new NotificationChannel(AppConstants.CHANNEL_NODE_REMOVED,
                    getString(R.string.channel_node_removed), NotificationManager.IMPORTANCE_HIGH);

            NotificationChannel nodeSharingChannel = new NotificationChannel(AppConstants.CHANNEL_NODE_SHARING,
                    getString(R.string.channel_node_sharing), NotificationManager.IMPORTANCE_HIGH);

            NotificationChannel alertChannel = new NotificationChannel(AppConstants.CHANNEL_ALERT,
                    getString(R.string.channel_node_alert), NotificationManager.IMPORTANCE_HIGH);

            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(nodeConnectedChannel);
            notificationManager.createNotificationChannel(nodeDisconnectedChannel);
            notificationManager.createNotificationChannel(nodeAddedChannel);
            notificationManager.createNotificationChannel(nodeRemovedChannel);
            notificationManager.createNotificationChannel(nodeSharingChannel);
            notificationManager.createNotificationChannel(alertChannel);
        }
    }

    public void removeNodeInformation(String nodeId) {
        nodeMap.remove(nodeId);
        localDeviceMap.remove(nodeId);
    }

    /**
     * Check the device to make sure it has the Google Play Services APK.
     *
     * @return Returns true if Google Api is available.
     */
    private boolean isPlayServicesAvailable() {
        GoogleApiAvailability apiAvailability = GoogleApiAvailability.getInstance();
        int resultCode = apiAvailability.isGooglePlayServicesAvailable(this);
        if (resultCode == ConnectionResult.SUCCESS) {
            return true;
        }
        return false;
    }
}
