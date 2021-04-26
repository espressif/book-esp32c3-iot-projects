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

import android.content.Context;
import android.os.Bundle;
import android.util.Log;

import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.local_control.LocalControlApiManager;
import com.google.gson.JsonObject;

/**
 * This class will decide to call API on local network or on cloud.
 * If device is available on local network then API will be called using local network.
 * And it will call cloud API if device is not available on local network.
 */
public class NetworkApiManager {

    private final String TAG = NetworkApiManager.class.getSimpleName();

    private Context context;
    private EspApplication espApp;
    private ApiManager apiManager;
    private LocalControlApiManager localControlApiManager;

    public NetworkApiManager(Context context) {
        this.context = context;
        espApp = (EspApplication) context.getApplicationContext();
        apiManager = ApiManager.getInstance(context);
        localControlApiManager = new LocalControlApiManager(context);
    }

    /**
     * This method is used to update param values of a device.
     *
     * @param nodeId   Node id.
     * @param body     Json data to be sent in request. It contains new value of a param.
     * @param listener Listener to send success or failure.
     */
    public void updateParamValue(final String nodeId, final JsonObject body, final ApiResponseListener listener) {

        if (espApp.localDeviceMap.containsKey(nodeId)) {

            localControlApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                @Override
                public void onSuccess(Bundle data) {
                    listener.onSuccess(data);
                }

                @Override
                public void onResponseFailure(Exception exception) {
                    Log.e(TAG, "Error : " + exception.getMessage());
                    Log.e(TAG, "Removing Node id : " + nodeId);
                    espApp.localDeviceMap.remove(nodeId);
                    updateParamValue(nodeId, body, listener);
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                    Log.e(TAG, "Error : " + exception.getMessage());
                    Log.e(TAG, "Removing Node id : " + nodeId);
                    espApp.localDeviceMap.remove(nodeId);
                    updateParamValue(nodeId, body, listener);
                }
            });

        } else {
            apiManager.updateParamValue(nodeId, body, listener);
        }
    }

    /**
     * This method is used to get param values for a given node id.
     *
     * @param nodeId   Node id.
     * @param listener Listener to send success or failure.
     */
    public void getParamsValues(final String nodeId, final ApiResponseListener listener) {

        if (espApp.localDeviceMap.containsKey(nodeId)) {

            localControlApiManager.getParamsValues(nodeId, new ApiResponseListener() {

                @Override
                public void onSuccess(Bundle data) {
                    listener.onSuccess(data);
                }

                @Override
                public void onResponseFailure(Exception exception) {
                    Log.e(TAG, "Error : " + exception.getMessage());
                    Log.e(TAG, "Removing Node id : " + nodeId);
                    espApp.localDeviceMap.remove(nodeId);
                    getParamsValues(nodeId, listener);
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                    Log.e(TAG, "Error : " + exception.getMessage());
                    Log.e(TAG, "Removing Node id : " + nodeId);
                    espApp.localDeviceMap.remove(nodeId);
                    getParamsValues(nodeId, listener);
                }
            });

        } else {
            apiManager.getParamsValues(nodeId, listener);
        }
    }

    /**
     * This method is used to get node details for a given node id.
     *
     * @param nodeId   Node id.
     * @param listener Listener to send success or failure.
     */
    public void getNodeDetails(final String nodeId, final ApiResponseListener listener) {

        if (espApp.localDeviceMap.containsKey(nodeId)) {

            localControlApiManager.getNodeDetails(nodeId, new ApiResponseListener() {

                @Override
                public void onSuccess(Bundle data) {
                    listener.onSuccess(data);
                }

                @Override
                public void onResponseFailure(Exception exception) {
                    Log.e(TAG, "Error : " + exception.getMessage());
                    Log.e(TAG, "Removing Node id : " + nodeId);
                    espApp.localDeviceMap.remove(nodeId);
                    getParamsValues(nodeId, listener);
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                    Log.e(TAG, "Error : " + exception.getMessage());
                    Log.e(TAG, "Removing Node id : " + nodeId);
                    espApp.localDeviceMap.remove(nodeId);
                    getParamsValues(nodeId, listener);
                }
            });

        } else {
            apiManager.getNodeDetails(nodeId, listener);
        }
    }
}
