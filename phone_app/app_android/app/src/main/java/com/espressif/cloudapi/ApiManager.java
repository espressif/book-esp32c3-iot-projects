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

package com.espressif.cloudapi;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.text.TextUtils;
import android.util.Log;

import com.auth0.android.jwt.Claim;
import com.auth0.android.jwt.DecodeException;
import com.auth0.android.jwt.JWT;
import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.JsonDataParser;
import com.espressif.db.EspDatabase;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.ui.models.Action;
import com.espressif.ui.models.ApiResponse;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Group;
import com.espressif.ui.models.Param;
import com.espressif.ui.models.Scene;
import com.espressif.ui.models.Schedule;
import com.espressif.ui.models.Service;
import com.espressif.ui.models.SharingRequest;
import com.espressif.ui.models.UpdateEvent;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import org.greenrobot.eventbus.EventBus;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import io.reactivex.Observable;
import io.reactivex.functions.Consumer;
import io.reactivex.functions.Function;
import io.reactivex.schedulers.Schedulers;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ApiManager {

    private static final String TAG = ApiManager.class.getSimpleName();

    private static final int REQ_STATUS_TIME = 5000;

    public static boolean isOAuthLogin;
    public static String userId = "";
    private static String userName = "";
    private static String idToken = "";
    private static String accessToken = "";
    private static String refreshToken = "";
    private static HashMap<String, String> requestIds = new HashMap<>(); // Map of node id and request id.

    private Context context;
    private EspApplication espApp;
    private Handler handler;
    private ApiInterface apiInterface;
    private EspDatabase espDatabase;
    private SharedPreferences sharedPreferences;
    private static ArrayList<String> nodeIds = new ArrayList<>();
    private static ArrayList<String> scheduleIds = new ArrayList<>();
    private static ArrayList<String> sceneIds = new ArrayList<>();

    private static ApiManager apiManager;

    public static ApiManager getInstance(Context context) {

        if (apiManager == null) {
            apiManager = new ApiManager(context);
        }
        return apiManager;
    }

    private ApiManager(Context context) {
        this.context = context;
        handler = new Handler();
        espApp = (EspApplication) context.getApplicationContext();
        espDatabase = EspDatabase.getInstance(context);
        apiInterface = ApiClient.getClient(context).create(ApiInterface.class);
        sharedPreferences = context.getSharedPreferences(AppConstants.ESP_PREFERENCES, Context.MODE_PRIVATE);
        getTokenAndUserId();
    }

    public void login(final String userName, String password, final ApiResponseListener listener) {

        Log.d(TAG, "Login...");
        JsonObject body = new JsonObject();
        body.addProperty(AppConstants.KEY_USER_NAME, userName);
        body.addProperty(AppConstants.KEY_PASSWORD, password);

        apiInterface.login(AppConstants.URL_LOGIN, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Login, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.d(TAG, " -- Auth Success : response : " + jsonResponse);
                        JSONObject jsonObject = new JSONObject(jsonResponse);
                        idToken = jsonObject.getString("idtoken");
                        accessToken = jsonObject.getString("accesstoken");
                        refreshToken = jsonObject.getString("refreshtoken");
                        isOAuthLogin = false;

                        SharedPreferences.Editor editor = sharedPreferences.edit();
                        editor.putString(AppConstants.KEY_EMAIL, userName);
                        editor.putString(AppConstants.KEY_ID_TOKEN, idToken);
                        editor.putString(AppConstants.KEY_ACCESS_TOKEN, accessToken);
                        editor.putString(AppConstants.KEY_REFRESH_TOKEN, refreshToken);
                        editor.putBoolean(AppConstants.KEY_IS_OAUTH_LOGIN, false);
                        editor.apply();

                        getTokenAndUserId();
                        espApp.loginSuccess();
                        listener.onSuccess(null);
                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to login");
                        accessToken = null;
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    accessToken = null;
                    listener.onResponseFailure(new RuntimeException("Failed to login"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                accessToken = null;
                listener.onNetworkFailure(new RuntimeException("Failed to login"));
            }
        });
    }

    public void getOAuthToken(String code, final ApiResponseListener listener) {

        Log.d(TAG, "Get OAuth Token");
        String url = BuildConfig.TOKEN_URL;

        try {
            apiInterface.oauthLogin(url, "application/x-www-form-urlencoded",
                    "authorization_code", BuildConfig.CLIENT_ID, code,
                    BuildConfig.REDIRECT_URI).enqueue(new Callback<ResponseBody>() {

                @Override
                public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                    Log.d(TAG, "Get OAuth Token, Response code  : " + response.code());
                    try {
                        if (response.isSuccessful()) {

                            String jsonResponse = response.body().string();
                            JSONObject jsonObject = new JSONObject(jsonResponse);
                            idToken = jsonObject.getString(AppConstants.KEY_ID_TOKEN);
                            accessToken = jsonObject.getString(AppConstants.KEY_ACCESS_TOKEN);
                            refreshToken = jsonObject.getString(AppConstants.KEY_REFRESH_TOKEN);
                            isOAuthLogin = true;

                            SharedPreferences.Editor editor = sharedPreferences.edit();
                            editor.putString(AppConstants.KEY_ID_TOKEN, idToken);
                            editor.putString(AppConstants.KEY_ACCESS_TOKEN, accessToken);
                            editor.putString(AppConstants.KEY_REFRESH_TOKEN, refreshToken);
                            editor.putBoolean(AppConstants.KEY_IS_OAUTH_LOGIN, true);
                            editor.apply();

                            getTokenAndUserId();
                            listener.onSuccess(null);

                        } else {
                            String jsonErrResponse = response.errorBody().string();
                            processError(jsonErrResponse, listener, "Failed to login");
                        }
                    } catch (IOException e) {
                        e.printStackTrace();
                        listener.onResponseFailure(e);
                    } catch (JSONException e) {
                        e.printStackTrace();
                        listener.onResponseFailure(e);
                    }
                }

                @Override
                public void onFailure(Call<ResponseBody> call, Throwable t) {
                    t.printStackTrace();
                    listener.onNetworkFailure(new Exception(t));
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            listener.onNetworkFailure(e);
        }
    }

    public void createUser(String email, String password, final ApiResponseListener listener) {

        Log.d(TAG, "Create user...");
        JsonObject body = new JsonObject();
        body.addProperty(AppConstants.KEY_USER_NAME, email);
        body.addProperty(AppConstants.KEY_PASSWORD, password);

        apiInterface.createUser(AppConstants.URL_USER, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Create user, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to create user");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to create user"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to create user"));
            }
        });
    }

    public void confirmUser(String email, String verificationCode, final ApiResponseListener listener) {

        Log.d(TAG, "Confirm user...");
        JsonObject body = new JsonObject();
        body.addProperty(AppConstants.KEY_USER_NAME, email);
        body.addProperty(AppConstants.KEY_VERIFICATION_CODE, verificationCode);

        apiInterface.confirmUser(AppConstants.URL_USER, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Confirm user, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to confirm user");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to confirm user"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to confirm user"));
            }
        });
    }

    public void deleteUserRequest(boolean request, final ApiResponseListener listener) {

        Log.d(TAG, "Delete user request...");

        apiInterface.deleteUserRequest(AppConstants.URL_USER, accessToken, request).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Delete user request, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to request for delete user");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to request for delete user"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to request for delete user"));
            }
        });
    }

    public void deleteUserConfirm(String verificationCode, final ApiResponseListener listener) {

        Log.d(TAG, "Delete user confirm...");

        apiInterface.deleteUserConfirm(AppConstants.URL_USER, accessToken, verificationCode).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Delete user confirm, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to delete user");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to delete user"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to delete user"));
            }
        });
    }

    public void forgotPassword(String email, final ApiResponseListener listener) {

        Log.d(TAG, "Forgot password...");
        JsonObject body = new JsonObject();
        body.addProperty(AppConstants.KEY_USER_NAME, email);

        apiInterface.forgotPassword(AppConstants.URL_FORGOT_PASSWORD, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Forgot password, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to send forgot password request");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to send forgot password request"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to send forgot password request"));
            }
        });
    }

    public void resetPassword(String email, String newPassword, String verificationCode, final ApiResponseListener listener) {

        Log.d(TAG, "Reset password...");
        JsonObject body = new JsonObject();
        body.addProperty(AppConstants.KEY_USER_NAME, email);
        body.addProperty(AppConstants.KEY_PASSWORD, newPassword);
        body.addProperty(AppConstants.KEY_VERIFICATION_CODE, verificationCode);

        apiInterface.forgotPassword(AppConstants.URL_FORGOT_PASSWORD, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Reset password, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to reset password request");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to reset password request"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to reset password request"));
            }
        });
    }

    public void changePassword(String oldPassword, String newPassword, final ApiResponseListener listener) {

        Log.d(TAG, "Change password...");
        JsonObject body = new JsonObject();
        body.addProperty(AppConstants.KEY_PASSWORD, oldPassword);
        body.addProperty(AppConstants.KEY_NEW_PASSWORD, newPassword);

        apiInterface.changePassword(AppConstants.URL_CHANGE_PASSWORD, accessToken, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Change password, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to change password");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to change password"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to change password"));
            }
        });
    }

    public void getTokenAndUserId() {

        userName = sharedPreferences.getString(AppConstants.KEY_EMAIL, "");
        idToken = sharedPreferences.getString(AppConstants.KEY_ID_TOKEN, "");
        accessToken = sharedPreferences.getString(AppConstants.KEY_ACCESS_TOKEN, "");
        refreshToken = sharedPreferences.getString(AppConstants.KEY_REFRESH_TOKEN, "");
        isOAuthLogin = sharedPreferences.getBoolean(AppConstants.KEY_IS_OAUTH_LOGIN, false);

        if (!TextUtils.isEmpty(idToken)) {

            JWT jwt = null;
            SharedPreferences.Editor editor = sharedPreferences.edit();

            try {
                jwt = new JWT(idToken);
            } catch (DecodeException e) {
                e.printStackTrace();
            }

            Claim claimUserId = jwt.getClaim("custom:user_id");
            userId = claimUserId.asString();
            editor.putString(AppConstants.KEY_USER_ID, userId);

            if (isOAuthLogin) {

                Claim claimEmail = jwt.getClaim(AppConstants.KEY_EMAIL);
                String email = claimEmail.asString();
                userName = email;
                editor.putString(AppConstants.KEY_EMAIL, email);
            }
            editor.apply();

            try {
                jwt = new JWT(accessToken);
            } catch (DecodeException e) {
                e.printStackTrace();
            }
            Date expiresAt = jwt.getExpiresAt();
            Log.e(TAG, "==============>>>>>>>>>>> USER ID : " + userId);
            Log.e(TAG, "Token expires At : " + expiresAt);
        }
    }

    public String getNewToken() {
        String newAccToken = "";
        Log.d(TAG, "Getting new access token ");
        if (isOAuthLogin) {
            newAccToken = getNewTokenForOAuthUser();
        } else {
            newAccToken = getNewTokenForCognitoUser();
        }
        return newAccToken;
    }

    public String getNewTokenForCognitoUser() {

        Log.d(TAG, "Get New Token For Cognito user");
        Log.d(TAG, "Login...");
        JsonObject body = new JsonObject();
        body.addProperty(AppConstants.KEY_USER_NAME, userName);
        body.addProperty("refreshtoken", refreshToken);

        try {
            Response<ResponseBody> response = apiInterface.login(AppConstants.URL_LOGIN, body).execute();

            if (response.isSuccessful()) {

                String jsonResponse = response.body().string();
                Log.d(TAG, " -- Auth Success : response : " + jsonResponse);
                JSONObject jsonObject = null;

                try {
                    jsonObject = new JSONObject(jsonResponse);
                    idToken = jsonObject.getString("idtoken");
                    accessToken = jsonObject.getString("accesstoken");
                } catch (JSONException e) {
                    e.printStackTrace();
                    accessToken = null;
                }

                isOAuthLogin = false;
                SharedPreferences.Editor editor = sharedPreferences.edit();
                editor.putString(AppConstants.KEY_EMAIL, userName);
                editor.putString(AppConstants.KEY_ID_TOKEN, idToken);
                editor.putString(AppConstants.KEY_ACCESS_TOKEN, accessToken);
                editor.putString(AppConstants.KEY_REFRESH_TOKEN, refreshToken);
                editor.putBoolean(AppConstants.KEY_IS_OAUTH_LOGIN, false);
                editor.apply();
                getTokenAndUserId();

            } else {
                accessToken = null;
            }
        } catch (IOException e) {
            e.printStackTrace();
            accessToken = null;
        }
        return accessToken;
    }

    public String getNewTokenForOAuthUser() {

        Log.d(TAG, "Get New Token For OAuth User");
        HashMap<String, String> body = new HashMap<>();
        body.put("user_name", userId);
        body.put("refreshtoken", refreshToken);

        try {
            Response<ResponseBody> response = apiInterface.getOAuthLoginToken(AppConstants.URL_OAUTH_LOGIN, body).execute();

            if (response.isSuccessful()) {
                ResponseBody responseBody = response.body();
                String jsonResponse = responseBody.string();
                Log.e(TAG, "Response Body : " + jsonResponse);
                JSONObject jsonObject = null;
                try {
                    jsonObject = new JSONObject(jsonResponse);
                    idToken = jsonObject.getString("idtoken");
                    accessToken = jsonObject.getString("accesstoken");
                    isOAuthLogin = true;
                } catch (JSONException e) {
                    e.printStackTrace();
                    return null;
                }

                SharedPreferences.Editor editor = sharedPreferences.edit();
                editor.putString(AppConstants.KEY_ID_TOKEN, idToken);
                editor.putString(AppConstants.KEY_ACCESS_TOKEN, accessToken);
                editor.putBoolean(AppConstants.KEY_IS_OAUTH_LOGIN, true);
                editor.apply();
                getTokenAndUserId();
                return accessToken;
            } else {
                return null;
            }
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    public void logout(final ApiResponseListener listener) {

        Log.d(TAG, "Logout...");
        apiInterface.logout(AppConstants.URL_LOGOUT).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Logout, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.d(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);
                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to logout user");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to logout user"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to logout user"));
            }
        });
    }

    /**
     * This method is used to get user id from user name.
     *
     * @param listener Listener to send success or failure.
     */
    public void getSupportedVersions(final ApiResponseListener listener) {

        Log.d(TAG, "Get Supported Versions");

        apiInterface.getSupportedVersions(AppConstants.URL_SUPPORTED_VERSIONS)

                .enqueue(new Callback<ResponseBody>() {

                    @Override
                    public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                        Log.d(TAG, "Get Supported Versions, Response code  : " + response.code());

                        try {

                            if (response.isSuccessful()) {

                                if (response.body() != null) {

                                    String jsonResponse = response.body().string();
                                    Log.e(TAG, "onResponse Success : " + jsonResponse);
                                    JSONObject jsonObject = new JSONObject(jsonResponse);
                                    JSONArray jsonArray = jsonObject.optJSONArray(AppConstants.KEY_SUPPORTED_VERSIONS);
                                    ArrayList<String> supportedVersions = new ArrayList<>();

                                    for (int i = 0; i < jsonArray.length(); i++) {

                                        String version = jsonArray.optString(i);
                                        Log.d(TAG, "Supported Version : " + version);
                                        supportedVersions.add(version);
                                    }

                                    String additionalInfoMsg = jsonObject.optString(AppConstants.KEY_ADDITIONAL_INFO);
                                    Bundle bundle = new Bundle();
                                    bundle.putString(AppConstants.KEY_ADDITIONAL_INFO, additionalInfoMsg);
                                    bundle.putStringArrayList(AppConstants.KEY_SUPPORTED_VERSIONS, supportedVersions);
                                    listener.onSuccess(bundle);

                                } else {
                                    Log.e(TAG, "Response received : null");
                                    listener.onResponseFailure(new RuntimeException("Failed to get Supported Versions"));
                                }

                            } else {
                                String jsonErrResponse = response.errorBody().string();
                                processError(jsonErrResponse, listener, "Failed to get Supported Versions");
                            }
                        } catch (JSONException e) {
                            e.printStackTrace();
                            listener.onResponseFailure(e);
                        } catch (IOException e) {
                            e.printStackTrace();
                            listener.onResponseFailure(e);
                        }
                    }

                    @Override
                    public void onFailure(Call<ResponseBody> call, Throwable t) {
                        Log.e(TAG, "Error in receiving Supported Versions");
                        t.printStackTrace();
                        listener.onNetworkFailure(new Exception(t));
                    }
                });
    }

    /**
     * This method is used to get all nodes for the user.
     *
     * @param listener Listener to send success or failure.
     */
    public void getNodes(final ApiResponseListener listener) {

        Log.d(TAG, "Get Nodes");
        nodeIds.clear();
        scheduleIds.clear();
        sceneIds.clear();
        getNodesFromCloud("", listener);
    }

    private void getNodesFromCloud(final String startId, final ApiResponseListener listener) {

        Log.d(TAG, "Get Nodes from cloud with start id : " + startId);
        apiInterface.getNodes(AppConstants.URL_USER_NODES_DETAILS, accessToken, startId).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Get Nodes, Response code : " + response.code());

                try {

                    if (response.isSuccessful()) {

                        if (response.body() != null) {

                            if (TextUtils.isEmpty(startId)) {
                                espDatabase.getNodeDao().deleteAll();
                                Log.d(TAG, "Delete all nodes from local storage.");
                            }

                            String jsonResponse = response.body().string();
                            Log.e(TAG, "onResponse Success : " + jsonResponse);
                            JSONObject jsonObject = new JSONObject(jsonResponse);
                            JSONArray nodeJsonArray = jsonObject.optJSONArray(AppConstants.KEY_NODE_DETAILS);
                            HashMap<String, Schedule> scheduleMap = new HashMap<>();
                            HashMap<String, Scene> sceneMap = new HashMap<>();

                            if (nodeJsonArray != null) {

                                for (int nodeIndex = 0; nodeIndex < nodeJsonArray.length(); nodeIndex++) {

                                    JSONObject nodeJson = nodeJsonArray.optJSONObject(nodeIndex);

                                    if (nodeJson != null) {

                                        // Node ID
                                        String nodeId = nodeJson.optString(AppConstants.KEY_ID);
                                        Log.d(TAG, "Node id : " + nodeId);
                                        nodeIds.add(nodeId);
                                        EspNode espNode;

                                        if (espApp.nodeMap.get(nodeId) != null) {
                                            espNode = espApp.nodeMap.get(nodeId);
                                        } else {
                                            espNode = new EspNode(nodeId);
                                        }

                                        // User role
                                        String role = nodeJson.optString(AppConstants.KEY_ROLE);
                                        espNode.setUserRole(role);

                                        // Node Config
                                        JSONObject configJson = nodeJson.optJSONObject(AppConstants.KEY_CONFIG);
                                        if (configJson != null) {

                                            // If node is available on local network then ignore configuration received from cloud.
                                            if (!espApp.localDeviceMap.containsKey(nodeId)) {
                                                espNode = JsonDataParser.setNodeConfig(espNode, configJson);
                                            } else {
                                                Log.d(TAG, "Ignore config values for local node :" + nodeId);
                                            }

                                            espNode.setOnline(true);
                                            espNode.setConfigData(configJson.toString());
                                            espApp.nodeMap.put(nodeId, espNode);
                                        }

                                        // Node Params values
                                        JSONObject paramsJson = nodeJson.optJSONObject(AppConstants.KEY_PARAMS);
                                        if (paramsJson != null) {

                                            espNode.setParamData(paramsJson.toString());
                                            espDatabase.getNodeDao().insertOrUpdate(espNode);

                                            ArrayList<Device> devices = espNode.getDevices();
                                            ArrayList<Service> services = espNode.getServices();
                                            JSONObject scheduleJson = paramsJson.optJSONObject(AppConstants.KEY_SCHEDULE);
                                            JSONObject sceneJson = paramsJson.optJSONObject(AppConstants.KEY_SCENES);
                                            JSONObject timeJson = paramsJson.optJSONObject(AppConstants.KEY_TIME);
                                            JSONObject localControlJson = paramsJson.optJSONObject(AppConstants.KEY_LOCAL_CONTROL);

                                            // If node is available on local network then ignore param values received from cloud.
                                            if (!espApp.localDeviceMap.containsKey(nodeId) && devices != null) {

                                                for (int i = 0; i < devices.size(); i++) {

                                                    ArrayList<Param> params = devices.get(i).getParams();
                                                    String deviceName = devices.get(i).getDeviceName();
                                                    JSONObject deviceJson = paramsJson.optJSONObject(deviceName);

                                                    if (deviceJson != null) {

                                                        for (int j = 0; j < params.size(); j++) {

                                                            Param param = params.get(j);
                                                            String key = param.getName();

                                                            if (!param.isDynamicParam()) {
                                                                continue;
                                                            }

                                                            if (deviceJson.has(key)) {
                                                                JsonDataParser.setDeviceParamValue(deviceJson, devices.get(i), param);
                                                            }
                                                        }
                                                    } else {
                                                        Log.e(TAG, "Device JSON is null");
                                                    }
                                                }
                                            } else {
                                                Log.d(TAG, "Ignore param values for local node :" + nodeId);
                                            }

                                            // Schedules
                                            if (scheduleJson != null) {

                                                JSONArray scheduleArrayJson = scheduleJson.optJSONArray(AppConstants.KEY_SCHEDULES);

                                                if (scheduleArrayJson != null) {

                                                    for (int index = 0; index < scheduleArrayJson.length(); index++) {

                                                        JSONObject schJson = scheduleArrayJson.getJSONObject(index);
                                                        String scheduleId = schJson.optString(AppConstants.KEY_ID);
                                                        String key = scheduleId;

                                                        if (!TextUtils.isEmpty(scheduleId)) {

                                                            String name = schJson.optString(AppConstants.KEY_NAME);
                                                            key = key + "_" + name + "_" + schJson.optBoolean(AppConstants.KEY_ENABLED);

                                                            HashMap<String, Integer> triggers = new HashMap<>();
                                                            JSONArray triggerArray = schJson.optJSONArray(AppConstants.KEY_TRIGGERS);
                                                            for (int t = 0; t < triggerArray.length(); t++) {
                                                                JSONObject triggerJson = triggerArray.optJSONObject(t);
                                                                int days = triggerJson.optInt(AppConstants.KEY_DAYS);
                                                                int mins = triggerJson.optInt(AppConstants.KEY_MINUTES);
                                                                triggers.put(AppConstants.KEY_DAYS, days);
                                                                triggers.put(AppConstants.KEY_MINUTES, mins);
                                                                key = key + "_" + days + "_" + mins;
                                                            }

                                                            Schedule schedule = scheduleMap.get(key);
                                                            if (schedule == null) {
                                                                schedule = new Schedule();
                                                            }

                                                            schedule.setId(scheduleId);
                                                            schedule.setName(schJson.optString(AppConstants.KEY_NAME));
                                                            schedule.setEnabled(schJson.optBoolean(AppConstants.KEY_ENABLED));

                                                            scheduleIds.add(key);
                                                            schedule.setTriggers(triggers);
                                                            Log.d(TAG, "=============== Schedule : " + schedule.getName() + " ===============");

                                                            // Actions
                                                            JSONObject actionsSchJson = schJson.optJSONObject(AppConstants.KEY_ACTION);

                                                            if (actionsSchJson != null) {

                                                                ArrayList<Action> actions = schedule.getActions();
                                                                if (actions == null) {
                                                                    actions = new ArrayList<>();
                                                                    schedule.setActions(actions);
                                                                }

                                                                for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {

                                                                    Device d = new Device(devices.get(deviceIndex));
                                                                    ArrayList<Param> params = d.getParams();
                                                                    String deviceName = d.getDeviceName();
                                                                    JSONObject deviceAction = actionsSchJson.optJSONObject(deviceName);

                                                                    if (deviceAction != null) {

                                                                        Action action = null;
                                                                        Device actionDevice = null;
                                                                        int actionIndex = -1;

                                                                        for (int aIndex = 0; aIndex < actions.size(); aIndex++) {

                                                                            Action a = actions.get(aIndex);
                                                                            if (a.getDevice().getNodeId().equals(nodeId) && deviceName.equals(a.getDevice().getDeviceName())) {
                                                                                action = actions.get(aIndex);
                                                                                actionIndex = aIndex;
                                                                            }
                                                                        }

                                                                        if (action == null) {
                                                                            action = new Action();
                                                                            action.setNodeId(nodeId);

                                                                            for (int k = 0; k < devices.size(); k++) {

                                                                                if (devices.get(k).getNodeId().equals(nodeId) && devices.get(k).getDeviceName().equals(deviceName)) {
                                                                                    actionDevice = new Device(devices.get(k));
                                                                                    actionDevice.setSelectedState(1);
                                                                                    break;
                                                                                }
                                                                            }

                                                                            if (actionDevice == null) {
                                                                                actionDevice = new Device(nodeId);
                                                                            }
                                                                            action.setDevice(actionDevice);
                                                                        } else {
                                                                            actionDevice = action.getDevice();
                                                                        }

                                                                        ArrayList<Param> actionParams = new ArrayList<>();
                                                                        if (params != null) {

                                                                            Iterator<Param> iterator = params.iterator();
                                                                            while (iterator.hasNext()) {
                                                                                Param p = iterator.next();
                                                                                actionParams.add(new Param(p));
                                                                            }

                                                                            Iterator itr = actionParams.iterator();

                                                                            while (itr.hasNext()) {

                                                                                Param p = (Param) itr.next();

                                                                                if (!p.isDynamicParam()) {
                                                                                    itr.remove();
                                                                                } else if (p.getParamType() != null && p.getParamType().equals(AppConstants.PARAM_TYPE_NAME)) {
                                                                                    itr.remove();
                                                                                } else if (!p.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {
                                                                                    itr.remove();
                                                                                }
                                                                            }
                                                                        }
                                                                        actionDevice.setParams(actionParams);

                                                                        for (int paramIndex = 0; paramIndex < actionParams.size(); paramIndex++) {

                                                                            Param p = actionParams.get(paramIndex);
                                                                            String paramName = p.getName();

                                                                            if (deviceAction.has(paramName)) {

                                                                                p.setSelected(true);
                                                                                JsonDataParser.setDeviceParamValue(deviceAction, devices.get(deviceIndex), p);
                                                                            }
                                                                        }

                                                                        for (int paramIndex = 0; paramIndex < actionParams.size(); paramIndex++) {

                                                                            if (!actionParams.get(paramIndex).isSelected()) {
                                                                                actionDevice.setSelectedState(2); // Partially selected
                                                                            }
                                                                        }

                                                                        if (actionIndex == -1) {
                                                                            actions.add(action);
                                                                        } else {
                                                                            actions.set(actionIndex, action);
                                                                        }
                                                                        schedule.setActions(actions);

                                                                    }
                                                                }
                                                            }
                                                            scheduleMap.put(key, schedule);
                                                        }
                                                    }
                                                }
                                            } else {
                                                Log.e(TAG, "Schedule JSON is null");
                                            }

                                            // Scenes
                                            if (sceneJson != null) {

                                                JSONArray sceneArrayJson = sceneJson.optJSONArray(AppConstants.KEY_SCENES);

                                                if (sceneArrayJson != null) {

                                                    for (int index = 0; index < sceneArrayJson.length(); index++) {

                                                        JSONObject scJson = sceneArrayJson.getJSONObject(index);
                                                        String sceneId = scJson.optString(AppConstants.KEY_ID);
                                                        String key = sceneId;

                                                        if (!TextUtils.isEmpty(sceneId)) {

                                                            String name = scJson.optString(AppConstants.KEY_NAME);
                                                            String info = scJson.optString(AppConstants.KEY_INFO);
                                                            key = key + "_" + name + "_" + info;

                                                            Scene scene = sceneMap.get(key);
                                                            if (scene == null) {
                                                                scene = new Scene();
                                                            }

                                                            scene.setId(sceneId);
                                                            scene.setName(name);
                                                            scene.setInfo(info);
                                                            sceneIds.add(key);

                                                            Log.d(TAG, "=============== Scene : " + scene.getName() + " ===============");

                                                            // Actions
                                                            JSONObject actionsSceneJson = scJson.optJSONObject(AppConstants.KEY_ACTION);

                                                            if (actionsSceneJson != null) {

                                                                ArrayList<Action> actions = scene.getActions();
                                                                if (actions == null) {
                                                                    actions = new ArrayList<>();
                                                                    scene.setActions(actions);
                                                                }

                                                                for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {

                                                                    Device d = new Device(devices.get(deviceIndex));
                                                                    ArrayList<Param> params = d.getParams();
                                                                    String deviceName = d.getDeviceName();
                                                                    JSONObject deviceAction = actionsSceneJson.optJSONObject(deviceName);

                                                                    if (deviceAction != null) {

                                                                        Action action = null;
                                                                        Device actionDevice = null;
                                                                        int actionIndex = -1;

                                                                        for (int aIndex = 0; aIndex < actions.size(); aIndex++) {

                                                                            Action a = actions.get(aIndex);
                                                                            if (a.getDevice().getNodeId().equals(nodeId) && deviceName.equals(a.getDevice().getDeviceName())) {
                                                                                action = actions.get(aIndex);
                                                                                actionIndex = aIndex;
                                                                            }
                                                                        }

                                                                        if (action == null) {
                                                                            action = new Action();
                                                                            action.setNodeId(nodeId);

                                                                            for (int k = 0; k < devices.size(); k++) {

                                                                                if (devices.get(k).getNodeId().equals(nodeId) && devices.get(k).getDeviceName().equals(deviceName)) {
                                                                                    actionDevice = new Device(devices.get(k));
                                                                                    actionDevice.setSelectedState(1);
                                                                                    break;
                                                                                }
                                                                            }

                                                                            if (actionDevice == null) {
                                                                                actionDevice = new Device(nodeId);
                                                                            }
                                                                            action.setDevice(actionDevice);
                                                                        } else {
                                                                            actionDevice = action.getDevice();
                                                                        }

                                                                        ArrayList<Param> actionParams = new ArrayList<>();
                                                                        if (params != null) {

                                                                            Iterator<Param> iterator = params.iterator();
                                                                            while (iterator.hasNext()) {
                                                                                Param p = iterator.next();
                                                                                actionParams.add(new Param(p));
                                                                            }

                                                                            Iterator itr = actionParams.iterator();

                                                                            while (itr.hasNext()) {

                                                                                Param p = (Param) itr.next();

                                                                                if (!p.isDynamicParam()) {
                                                                                    itr.remove();
                                                                                } else if (p.getParamType() != null && p.getParamType().equals(AppConstants.PARAM_TYPE_NAME)) {
                                                                                    itr.remove();
                                                                                } else if (!p.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {
                                                                                    itr.remove();
                                                                                }
                                                                            }
                                                                        }
                                                                        actionDevice.setParams(actionParams);

                                                                        for (int paramIndex = 0; paramIndex < actionParams.size(); paramIndex++) {

                                                                            Param p = actionParams.get(paramIndex);
                                                                            String paramName = p.getName();

                                                                            if (deviceAction.has(paramName)) {

                                                                                p.setSelected(true);
                                                                                JsonDataParser.setDeviceParamValue(deviceAction, devices.get(deviceIndex), p);
                                                                            }
                                                                        }

                                                                        for (int paramIndex = 0; paramIndex < actionParams.size(); paramIndex++) {

                                                                            if (!actionParams.get(paramIndex).isSelected()) {
                                                                                actionDevice.setSelectedState(2); // Partially selected
                                                                            }
                                                                        }

                                                                        if (actionIndex == -1) {
                                                                            actions.add(action);
                                                                        } else {
                                                                            actions.set(actionIndex, action);
                                                                        }
                                                                        scene.setActions(actions);
                                                                    }
                                                                }
                                                            }
                                                            sceneMap.put(key, scene);
                                                        }
                                                    }
                                                }
                                            } else {
                                                Log.e(TAG, "Scene JSON is null");
                                            }

                                            // Timezone
                                            if (timeJson != null && services != null) {
                                                for (int serviceIdx = 0; serviceIdx < services.size(); serviceIdx++) {
                                                    Service service = services.get(serviceIdx);
                                                    if (AppConstants.SERVICE_TYPE_TIME.equals(service.getType())) {
                                                        ArrayList<Param> timeParams = service.getParams();
                                                        if (timeParams != null) {
                                                            for (int paramIdx = 0; paramIdx < timeParams.size(); paramIdx++) {
                                                                Param timeParam = timeParams.get(paramIdx);
                                                                String dataType = timeParam.getDataType();
                                                                if (!TextUtils.isEmpty(dataType)) {
                                                                    if (dataType.equalsIgnoreCase("string")) {
                                                                        timeParam.setLabelValue(timeJson.optString(timeParam.getName()));
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            } else {
                                                Log.e(TAG, "Time JSON is not available");
                                            }

                                            // Local control
                                            if (localControlJson != null && services != null) {
                                                for (int serviceIdx = 0; serviceIdx < services.size(); serviceIdx++) {
                                                    Service service = services.get(serviceIdx);
                                                    if (AppConstants.SERVICE_TYPE_LOCAL_CONTROL.equals(service.getType())) {
                                                        ArrayList<Param> localParams = service.getParams();
                                                        if (localParams != null) {
                                                            for (int paramIdx = 0; paramIdx < localParams.size(); paramIdx++) {
                                                                Param localParam = localParams.get(paramIdx);
                                                                String dataType = localParam.getDataType();
                                                                if (!TextUtils.isEmpty(dataType)) {
                                                                    if (dataType.equalsIgnoreCase("string")) {
                                                                        localParam.setLabelValue(localControlJson.optString(localParam.getName()));
                                                                    }
                                                                    if (dataType.equalsIgnoreCase("int") || dataType.equalsIgnoreCase("integer")) {
                                                                        localParam.setValue(localControlJson.optInt(localParam.getName()));
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            } else {
                                                Log.e(TAG, "Local control JSON is not available");
                                            }
                                        }

                                        // Node Status
                                        JSONObject statusJson = nodeJson.optJSONObject(AppConstants.KEY_STATUS);

                                        if (statusJson != null && !espApp.localDeviceMap.containsKey(nodeId)) {

                                            JSONObject connectivityObject = statusJson.optJSONObject(AppConstants.KEY_CONNECTIVITY);

                                            if (connectivityObject != null) {

                                                boolean nodeStatus = connectivityObject.optBoolean(AppConstants.KEY_CONNECTED);
                                                long timestamp = connectivityObject.optLong(AppConstants.KEY_TIMESTAMP);
                                                espNode.setTimeStampOfStatus(timestamp);

                                                if (espNode.isOnline() != nodeStatus) {
                                                    espNode.setOnline(nodeStatus);
                                                }
                                            } else {
                                                Log.e(TAG, "Connectivity object is null");
                                            }
                                        }
                                    }
                                }
                            }

                            espApp.scheduleMap = scheduleMap;
                            String nextId = jsonObject.optString(AppConstants.KEY_NEXT_ID);
                            Log.d(TAG, "Start next id : " + nextId);

                            if (!TextUtils.isEmpty(nextId)) {
                                getNodesFromCloud(nextId, listener);
                            } else {
                                Iterator<Map.Entry<String, EspNode>> itr = espApp.nodeMap.entrySet().iterator();

                                // iterate and remove items simultaneously
                                while (itr.hasNext()) {

                                    Map.Entry<String, EspNode> entry = itr.next();
                                    String key = entry.getKey();

                                    if (!nodeIds.contains(key)) {
                                        itr.remove();
                                    }
                                }

                                Iterator<Map.Entry<String, Schedule>> schItr = espApp.scheduleMap.entrySet().iterator();

                                // iterate and remove items simultaneously
                                while (schItr.hasNext()) {

                                    Map.Entry<String, Schedule> entry = schItr.next();
                                    String key = entry.getKey();

                                    if (!scheduleIds.contains(key)) {
                                        schItr.remove();
                                        Log.e(TAG, "Remove schedule for key : " + key + " and Size : " + espApp.scheduleMap.size());
                                    }
                                }

                                listener.onSuccess(null);
                            }

                            espApp.sceneMap = sceneMap;
                            String nextSceneId = jsonObject.optString(AppConstants.KEY_NEXT_ID);
                            Log.d(TAG, "Start scene next id : " + nextSceneId);

                            if (!TextUtils.isEmpty(nextSceneId)) {
                                getNodesFromCloud(nextId, listener);
                            } else {
                                Iterator<Map.Entry<String, EspNode>> itr = espApp.nodeMap.entrySet().iterator();

                                // iterate and remove items simultaneously
                                while (itr.hasNext()) {

                                    Map.Entry<String, EspNode> entry = itr.next();
                                    String key = entry.getKey();

                                    if (!nodeIds.contains(key)) {
                                        itr.remove();
                                    }
                                }

                                Iterator<Map.Entry<String, Scene>> sceneItr = espApp.sceneMap.entrySet().iterator();

                                // iterate and remove items simultaneously
                                while (sceneItr.hasNext()) {

                                    Map.Entry<String, Scene> entry = sceneItr.next();
                                    String key = entry.getKey();

                                    if (!sceneIds.contains(key)) {
                                        sceneItr.remove();
                                        Log.e(TAG, "Remove scene for key : " + key + " and Size : " + espApp.sceneMap.size());
                                    }
                                }
                                listener.onSuccess(null);
                            }

                        } else {
                            Log.e(TAG, "Response received : null");
                            listener.onResponseFailure(new RuntimeException("Failed to get User device mapping"));
                        }

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to get User device mapping");
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                } catch (IOException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new Exception(t));
            }
        });
    }

    /**
     * This method is used to get node details. This is a blocking call.
     *
     * @param nodeId Node id.
     */
    public void getNodeDetails(String nodeId) {

        Log.d(TAG, "Get Node Details for id : " + nodeId);

        try {
            Response<ResponseBody> response = apiInterface.getNode(AppConstants.URL_USER_NODES, accessToken, nodeId).execute();
            Log.d(TAG, "Get Node Details, Response code : " + response.code());

            try {
                if (response.isSuccessful()) {

                    if (response.body() != null) {

                        String jsonResponse = response.body().string();
                        Log.e(TAG, "onResponse Success : " + jsonResponse);
                        JSONObject jsonObject = new JSONObject(jsonResponse);
                        JSONArray nodeJsonArray = jsonObject.optJSONArray(AppConstants.KEY_NODE_DETAILS);

                        if (nodeJsonArray != null) {

                            for (int nodeIndex = 0; nodeIndex < nodeJsonArray.length(); nodeIndex++) {

                                JSONObject nodeJson = nodeJsonArray.optJSONObject(nodeIndex);

                                if (nodeJson != null) {

                                    // Node ID
                                    String id = nodeJson.optString(AppConstants.KEY_ID);
                                    Log.d(TAG, "Node id : " + id);
                                    EspNode espNode;

                                    if (espApp.nodeMap.get(id) != null) {
                                        espNode = espApp.nodeMap.get(id);
                                    } else {
                                        espNode = new EspNode(id);
                                    }

                                    // User role
                                    String role = nodeJson.optString(AppConstants.KEY_ROLE);
                                    espNode.setUserRole(role);

                                    // Node Config
                                    JSONObject configJson = nodeJson.optJSONObject(AppConstants.KEY_CONFIG);
                                    if (configJson != null) {

                                        espNode = JsonDataParser.setNodeConfig(espNode, configJson);
                                        espNode.setConfigData(configJson.toString());
                                        espApp.nodeMap.put(nodeId, espNode);
                                    }

                                    // Node Params
                                    JSONObject paramsJson = nodeJson.optJSONObject(AppConstants.KEY_PARAMS);
                                    if (paramsJson != null) {
                                        JsonDataParser.setAllParams(espApp, espNode, paramsJson);
                                        espNode.setParamData(paramsJson.toString());
                                        espDatabase.getNodeDao().insertOrUpdate(espNode);
                                    }

                                    // Node Status
                                    JSONObject statusJson = nodeJson.optJSONObject(AppConstants.KEY_STATUS);

                                    if (statusJson != null) {

                                        JSONObject connectivityObject = statusJson.optJSONObject(AppConstants.KEY_CONNECTIVITY);

                                        if (connectivityObject != null) {

                                            boolean nodeStatus = connectivityObject.optBoolean(AppConstants.KEY_CONNECTED);
                                            long timestamp = connectivityObject.optLong(AppConstants.KEY_TIMESTAMP);
                                            espNode.setTimeStampOfStatus(timestamp);

                                            if (espNode.isOnline() != nodeStatus) {
                                                espNode.setOnline(nodeStatus);
                                                EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));
                                            }
                                        } else {
                                            Log.e(TAG, "Connectivity object is null");
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Log.e(TAG, "Failed to get Node Details. Response received : null");
                    }
                } else {
                    String jsonErrResponse = response.errorBody().string();
                    Log.e(TAG, "Failed to get Node Details.");
                }
            } catch (JSONException e) {
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void getNodeDetails(String nodeId, final ApiResponseListener listener) {

        Log.d(TAG, "Get Node Details for id : " + nodeId);

        apiInterface.getNode(AppConstants.URL_USER_NODES, accessToken, nodeId).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Get Node Details, Response code : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        if (response.body() != null) {

                            String jsonResponse = response.body().string();
                            Log.e(TAG, "onResponse Success : " + jsonResponse);
                            JSONObject jsonObject = new JSONObject(jsonResponse);
                            JSONArray nodeJsonArray = jsonObject.optJSONArray(AppConstants.KEY_NODE_DETAILS);

                            if (nodeJsonArray != null) {

                                for (int nodeIndex = 0; nodeIndex < nodeJsonArray.length(); nodeIndex++) {

                                    JSONObject nodeJson = nodeJsonArray.optJSONObject(nodeIndex);

                                    if (nodeJson != null) {

                                        // Node ID
                                        String nodeId = nodeJson.optString(AppConstants.KEY_ID);
                                        Log.d(TAG, "Node id : " + nodeId);
                                        EspNode espNode;

                                        if (espApp.nodeMap.get(nodeId) != null) {
                                            espNode = espApp.nodeMap.get(nodeId);
                                        } else {
                                            espNode = new EspNode(nodeId);
                                        }

                                        // User role
                                        String role = nodeJson.optString(AppConstants.KEY_ROLE);
                                        espNode.setUserRole(role);

                                        // Node Config
                                        JSONObject configJson = nodeJson.optJSONObject(AppConstants.KEY_CONFIG);
                                        if (configJson != null) {

                                            espNode = JsonDataParser.setNodeConfig(espNode, configJson);
                                            espNode.setConfigData(configJson.toString());
                                            espApp.nodeMap.put(nodeId, espNode);
                                        }

                                        // Node Params
                                        JSONObject paramsJson = nodeJson.optJSONObject(AppConstants.KEY_PARAMS);
                                        if (paramsJson != null) {
                                            JsonDataParser.setAllParams(espApp, espNode, paramsJson);
                                            espNode.setParamData(paramsJson.toString());
                                            espDatabase.getNodeDao().insertOrUpdate(espNode);
                                        }

                                        // Node Status
                                        JSONObject statusJson = nodeJson.optJSONObject(AppConstants.KEY_STATUS);

                                        if (statusJson != null) {

                                            JSONObject connectivityObject = statusJson.optJSONObject(AppConstants.KEY_CONNECTIVITY);

                                            if (connectivityObject != null) {

                                                boolean nodeStatus = connectivityObject.optBoolean(AppConstants.KEY_CONNECTED);
                                                long timestamp = connectivityObject.optLong(AppConstants.KEY_TIMESTAMP);
                                                espNode.setTimeStampOfStatus(timestamp);

                                                if (espNode.isOnline() != nodeStatus) {
                                                    espNode.setOnline(nodeStatus);
                                                    EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));
                                                }
                                            } else {
                                                Log.e(TAG, "Connectivity object is null");
                                            }
                                        }
                                    }
                                }
                            }

                            listener.onSuccess(null);

                        } else {
                            Log.e(TAG, "Response received : null");
                            listener.onResponseFailure(new RuntimeException("Failed to get Node Details"));
                        }
                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to get Node Details");
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                } catch (IOException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new Exception(t));
            }
        });
    }

    public void getNodeStatus(final String nodeId, final ApiResponseListener listener) {

        Log.d(TAG, "Get Node connectivity status for id : " + nodeId);

        apiInterface.getNodeStatus(AppConstants.URL_USER_NODE_STATUS, accessToken, nodeId).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Get Node status, Response code : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        if (response.body() != null) {

                            String jsonResponse = response.body().string();
                            Log.d(TAG, "onResponse Success : " + jsonResponse);
                            JSONObject nodeStatusJson = new JSONObject(jsonResponse);
                            EspNode espNode = espApp.nodeMap.get(nodeId);

                            if (espNode != null) {

                                // Node Status
                                JSONObject connectivityObject = nodeStatusJson.optJSONObject(AppConstants.KEY_CONNECTIVITY);

                                if (connectivityObject != null) {

                                    boolean nodeStatus = connectivityObject.optBoolean(AppConstants.KEY_CONNECTED);
                                    long timestamp = connectivityObject.optLong(AppConstants.KEY_TIMESTAMP);
                                    espNode.setTimeStampOfStatus(timestamp);

                                    if (espNode.isOnline() != nodeStatus) {
                                        espNode.setOnline(nodeStatus);
                                        EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));
                                    }
                                } else {
                                    Log.e(TAG, "Connectivity object is null");
                                }
                            }

                            listener.onSuccess(null);

                        } else {
                            Log.e(TAG, "Response received : null");
                            listener.onResponseFailure(new RuntimeException("Failed to get Node status"));
                        }
                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to get Node status");
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                } catch (IOException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new Exception(t));
            }
        });
    }

    /**
     * This method is used to send request for add device (Associate device with user).
     *
     * @param nodeId    Device Id.
     * @param secretKey Generated Secret Key.
     * @param listener  Listener to send success or failure.
     */
    public void addNode(final String nodeId, String secretKey,
                        final ApiResponseListener listener) {

        Log.d(TAG, "Add Node, nodeId : " + nodeId);

        DeviceOperationRequest req = new DeviceOperationRequest();
        req.setNodeId(nodeId);
        req.setSecretKey(secretKey);
        req.setOperation(AppConstants.KEY_OPERATION_ADD);

        apiInterface.addNode(AppConstants.URL_USER_NODE_MAPPING, accessToken, req).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Add Node, Response code : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        if (response.body() != null) {

                            String jsonResponse = response.body().string();
                            Log.e(TAG, "onResponse Success : " + jsonResponse);
                            JSONObject jsonObject = new JSONObject(jsonResponse);
                            String reqId = jsonObject.optString(AppConstants.KEY_REQ_ID);
                            requestIds.put(nodeId, reqId);
                            handler.post(getUserNodeMappingStatusTask);
                            Bundle data = new Bundle();
                            data.putString(AppConstants.KEY_REQ_ID, reqId);
                            listener.onSuccess(data);

                        } else {
                            listener.onResponseFailure(new RuntimeException("Failed to add device"));
                        }

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to add device");
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                } catch (IOException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new Exception(t));
            }
        });
    }

    /**
     * This method is used to send request for remove device.
     *
     * @param nodeId   Device Id.
     * @param listener Listener to send success or failure.
     */
    public void removeNode(final String nodeId, final ApiResponseListener listener) {

        Log.d(TAG, "Remove Node, nodeId : " + nodeId);

        DeviceOperationRequest req = new DeviceOperationRequest();
        req.setNodeId(nodeId);
        req.setOperation(AppConstants.KEY_OPERATION_REMOVE);

        apiInterface.removeNode(AppConstants.URL_USER_NODE_MAPPING, accessToken, req).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Remove Node, response code : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        if (response.body() != null) {

                            String jsonResponse = response.body().string();
                            Log.e(TAG, "onResponse Success : " + jsonResponse);
                            listener.onSuccess(null);

                        } else {
                            listener.onResponseFailure(new RuntimeException("Failed to delete this node."));
                        }

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to delete this node.");
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new Exception(t));
            }
        });
    }

    public void getParamsValues(final String nodeId, final ApiResponseListener listener) {

        Log.d(TAG, "Get Param values for node : " + nodeId);

        apiInterface.getParamValue(AppConstants.URL_USER_NODES_PARAMS, accessToken, nodeId).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Get Params Values, Response code : " + response.code());

                try {

                    if (response.isSuccessful()) {

                        if (response.body() != null) {

                            String jsonResponse = response.body().string();
                            Log.e(TAG, "onResponse Success : " + jsonResponse);
                            JSONObject jsonObject = new JSONObject(jsonResponse);
                            JSONObject scheduleJson = jsonObject.optJSONObject(AppConstants.KEY_SCHEDULE);
                            JSONObject sceneJson = jsonObject.optJSONObject(AppConstants.KEY_SCENES);

                            EspNode node = espApp.nodeMap.get(nodeId);

                            if (node != null) {

                                ArrayList<Device> devices = node.getDevices();

                                // Node Params
                                if (devices != null) {
                                    for (int i = 0; i < devices.size(); i++) {

                                        ArrayList<Param> params = devices.get(i).getParams();
                                        String deviceName = devices.get(i).getDeviceName();
                                        JSONObject deviceJson = jsonObject.optJSONObject(deviceName);

                                        if (deviceJson != null) {

                                            for (int j = 0; j < params.size(); j++) {

                                                Param param = params.get(j);
                                                String key = param.getName();

                                                if (deviceJson.has(key)) {
                                                    JsonDataParser.setDeviceParamValue(deviceJson, devices.get(i), param);
                                                }
                                            }
                                        } else {
                                            Log.e(TAG, "Device JSON is null");
                                        }
                                    }
                                }

                                // Schedules
                                if (scheduleJson != null) {

                                    JSONArray scheduleArrayJson = scheduleJson.optJSONArray(AppConstants.KEY_SCHEDULES);

                                    if (scheduleArrayJson != null) {

                                        if (espApp.scheduleMap == null) {
                                            espApp.scheduleMap = new HashMap<>();
                                        }

                                        for (int index = 0; index < scheduleArrayJson.length(); index++) {

                                            JSONObject schJson = scheduleArrayJson.getJSONObject(index);
                                            String scheduleId = schJson.optString(AppConstants.KEY_ID);
                                            String key = scheduleId;

                                            if (!TextUtils.isEmpty(scheduleId)) {

                                                String name = schJson.optString(AppConstants.KEY_NAME);
                                                key = key + "_" + name + "_" + schJson.optBoolean(AppConstants.KEY_ENABLED);

                                                HashMap<String, Integer> triggers = new HashMap<>();
                                                JSONArray triggerArray = schJson.optJSONArray(AppConstants.KEY_TRIGGERS);
                                                for (int t = 0; t < triggerArray.length(); t++) {
                                                    JSONObject triggerJson = triggerArray.optJSONObject(t);
                                                    int days = triggerJson.optInt(AppConstants.KEY_DAYS);
                                                    int mins = triggerJson.optInt(AppConstants.KEY_MINUTES);
                                                    triggers.put(AppConstants.KEY_DAYS, days);
                                                    triggers.put(AppConstants.KEY_MINUTES, mins);
                                                    key = key + "_" + days + "_" + mins;
                                                }

                                                Schedule schedule = espApp.scheduleMap.get(key);
                                                if (schedule == null) {
                                                    schedule = new Schedule();
                                                }

                                                schedule.setId(scheduleId);
                                                schedule.setName(schJson.optString(AppConstants.KEY_NAME));
                                                schedule.setEnabled(schJson.optBoolean(AppConstants.KEY_ENABLED));
                                                schedule.setTriggers(triggers);

                                                // Actions
                                                JSONObject actionsSchJson = schJson.optJSONObject(AppConstants.KEY_ACTION);

                                                if (actionsSchJson != null) {

                                                    ArrayList<Action> actions = schedule.getActions();
                                                    if (actions == null) {
                                                        actions = new ArrayList<>();
                                                        schedule.setActions(actions);
                                                    }

                                                    for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {

                                                        Device d = new Device(devices.get(deviceIndex));
                                                        ArrayList<Param> params = d.getParams();
                                                        String deviceName = d.getDeviceName();
                                                        JSONObject deviceAction = actionsSchJson.optJSONObject(deviceName);

                                                        if (deviceAction != null) {

                                                            Action action = null;
                                                            Device actionDevice = null;
                                                            int actionIndex = -1;

                                                            for (int aIndex = 0; aIndex < actions.size(); aIndex++) {

                                                                Action a = actions.get(aIndex);
                                                                if (a.getDevice().getNodeId().equals(nodeId) && deviceName.equals(a.getDevice().getDeviceName())) {
                                                                    action = actions.get(aIndex);
                                                                    actionIndex = aIndex;
                                                                }
                                                            }

                                                            if (action == null) {
                                                                action = new Action();
                                                                action.setNodeId(nodeId);

                                                                for (int k = 0; k < devices.size(); k++) {

                                                                    if (devices.get(k).getNodeId().equals(nodeId) && devices.get(k).getDeviceName().equals(deviceName)) {
                                                                        actionDevice = new Device(devices.get(k));
                                                                        actionDevice.setSelectedState(1);
                                                                        break;
                                                                    }
                                                                }

                                                                if (actionDevice == null) {
                                                                    actionDevice = new Device(nodeId);
                                                                }
                                                                action.setDevice(actionDevice);
                                                            } else {
                                                                actionDevice = action.getDevice();
                                                            }

                                                            ArrayList<Param> actionParams = new ArrayList<>();
                                                            if (params != null) {

                                                                Iterator<Param> iterator = params.iterator();
                                                                while (iterator.hasNext()) {
                                                                    Param p = iterator.next();
                                                                    actionParams.add(new Param(p));
                                                                }

                                                                Iterator itr = actionParams.iterator();

                                                                while (itr.hasNext()) {

                                                                    Param p = (Param) itr.next();

                                                                    if (!p.isDynamicParam()) {
                                                                        itr.remove();
                                                                    } else if (p.getParamType() != null && p.getParamType().equals(AppConstants.PARAM_TYPE_NAME)) {
                                                                        itr.remove();
                                                                    } else if (!p.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {
                                                                        itr.remove();
                                                                    }
                                                                }
                                                            }
                                                            actionDevice.setParams(actionParams);

                                                            for (int paramIndex = 0; paramIndex < actionParams.size(); paramIndex++) {

                                                                Param p = actionParams.get(paramIndex);
                                                                String paramName = p.getName();

                                                                if (deviceAction.has(paramName)) {

                                                                    p.setSelected(true);
                                                                    JsonDataParser.setDeviceParamValue(deviceAction, devices.get(deviceIndex), p);
                                                                }
                                                            }

                                                            for (int paramIndex = 0; paramIndex < actionParams.size(); paramIndex++) {

                                                                if (!actionParams.get(paramIndex).isSelected()) {
                                                                    actionDevice.setSelectedState(2); // Partially selected
                                                                }
                                                            }

                                                            if (actionIndex == -1) {
                                                                actions.add(action);
                                                            } else {
                                                                actions.set(actionIndex, action);
                                                            }
                                                            schedule.setActions(actions);

                                                        }
                                                    }
                                                }
                                                espApp.scheduleMap.put(key, schedule);
                                            }
                                        }
                                    }
                                } else {
                                    Log.d(TAG, "Schedule JSON is null");
                                }

                                // Scenes
                                if (sceneJson != null) {

                                    JSONArray sceneArrayJson = sceneJson.optJSONArray(AppConstants.KEY_SCENES);

                                    if (sceneArrayJson != null) {

                                        if (espApp.sceneMap == null) {
                                            espApp.sceneMap = new HashMap<>();
                                        }

                                        for (int index = 0; index < sceneArrayJson.length(); index++) {

                                            JSONObject scJson = sceneArrayJson.getJSONObject(index);
                                            String sceneId = scJson.optString(AppConstants.KEY_ID);
                                            String key = sceneId;

                                            if (!TextUtils.isEmpty(sceneId)) {

                                                String name = scJson.optString(AppConstants.KEY_NAME);
                                                String info = scJson.optString(AppConstants.KEY_INFO);
                                                key = key + "_" + name + "_" + info;

                                                Scene scene = espApp.sceneMap.get(key);
                                                if (scene == null) {
                                                    scene = new Scene();
                                                }

                                                scene.setId(sceneId);
                                                scene.setName(name);
                                                scene.setInfo(info);

                                                // Actions
                                                JSONObject actionsSceneJson = scJson.optJSONObject(AppConstants.KEY_ACTION);

                                                if (actionsSceneJson != null) {

                                                    ArrayList<Action> actions = scene.getActions();
                                                    if (actions == null) {
                                                        actions = new ArrayList<>();
                                                        scene.setActions(actions);
                                                    }

                                                    for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {

                                                        Device d = new Device(devices.get(deviceIndex));
                                                        ArrayList<Param> params = d.getParams();
                                                        String deviceName = d.getDeviceName();
                                                        JSONObject deviceAction = actionsSceneJson.optJSONObject(deviceName);

                                                        if (deviceAction != null) {

                                                            Action action = null;
                                                            Device actionDevice = null;
                                                            int actionIndex = -1;

                                                            for (int aIndex = 0; aIndex < actions.size(); aIndex++) {

                                                                Action a = actions.get(aIndex);
                                                                if (a.getDevice().getNodeId().equals(nodeId) && deviceName.equals(a.getDevice().getDeviceName())) {
                                                                    action = actions.get(aIndex);
                                                                    actionIndex = aIndex;
                                                                }
                                                            }

                                                            if (action == null) {
                                                                action = new Action();
                                                                action.setNodeId(nodeId);

                                                                for (int k = 0; k < devices.size(); k++) {

                                                                    if (devices.get(k).getNodeId().equals(nodeId) && devices.get(k).getDeviceName().equals(deviceName)) {
                                                                        actionDevice = new Device(devices.get(k));
                                                                        actionDevice.setSelectedState(1);
                                                                        break;
                                                                    }
                                                                }

                                                                if (actionDevice == null) {
                                                                    actionDevice = new Device(nodeId);
                                                                }
                                                                action.setDevice(actionDevice);
                                                            } else {
                                                                actionDevice = action.getDevice();
                                                            }

                                                            ArrayList<Param> actionParams = new ArrayList<>();
                                                            if (params != null) {

                                                                Iterator<Param> iterator = params.iterator();
                                                                while (iterator.hasNext()) {
                                                                    Param p = iterator.next();
                                                                    actionParams.add(new Param(p));
                                                                }

                                                                Iterator itr = actionParams.iterator();

                                                                while (itr.hasNext()) {

                                                                    Param p = (Param) itr.next();

                                                                    if (!p.isDynamicParam()) {
                                                                        itr.remove();
                                                                    } else if (p.getParamType() != null && p.getParamType().equals(AppConstants.PARAM_TYPE_NAME)) {
                                                                        itr.remove();
                                                                    } else if (!p.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {
                                                                        itr.remove();
                                                                    }
                                                                }
                                                            }
                                                            actionDevice.setParams(actionParams);

                                                            for (int paramIndex = 0; paramIndex < actionParams.size(); paramIndex++) {

                                                                Param p = actionParams.get(paramIndex);
                                                                String paramName = p.getName();

                                                                if (deviceAction.has(paramName)) {

                                                                    p.setSelected(true);
                                                                    JsonDataParser.setDeviceParamValue(deviceAction, devices.get(deviceIndex), p);
                                                                }
                                                            }

                                                            for (int paramIndex = 0; paramIndex < actionParams.size(); paramIndex++) {

                                                                if (!actionParams.get(paramIndex).isSelected()) {
                                                                    actionDevice.setSelectedState(2); // Partially selected
                                                                }
                                                            }

                                                            if (actionIndex == -1) {
                                                                actions.add(action);
                                                            } else {
                                                                actions.set(actionIndex, action);
                                                            }
                                                            scene.setActions(actions);
                                                        }
                                                    }
                                                }
                                                espApp.sceneMap.put(key, scene);
                                            }
                                        }
                                    }
                                } else {
                                    Log.d(TAG, "Scene JSON is null");
                                }
                            }
                            listener.onSuccess(null);

                        } else {
                            listener.onResponseFailure(new RuntimeException("Failed to get param values"));
                        }

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to get param values");
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                } catch (IOException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new Exception(t));
            }
        });
    }

    public void updateParamValue(final String nodeId, JsonObject body, final ApiResponseListener listener) {

        Log.d(TAG, "Updating param value");

        apiInterface.updateParamValue(AppConstants.URL_USER_NODES_PARAMS, accessToken, nodeId, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Update Params Value, Response code : " + response.code());

                try {

                    if (response.isSuccessful()) {

                        if (response.body() != null) {

                            String jsonResponse = response.body().string();
                            Log.d(TAG, "onResponse Success : " + jsonResponse);
                            listener.onSuccess(null);

                        } else {
                            listener.onResponseFailure(new RuntimeException("Failed to update param value"));
                        }

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to update param value");
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new Exception(t));
            }
        });
    }

    /**
     * This method is used to add , update or remove schedule.
     *
     * @param map      Map of node id and its schedule JSON data.
     * @param listener Listener to send success or failure.
     */
    @SuppressLint("CheckResult")
    public void updateSchedules(final HashMap<String, JsonObject> map,
                                final ApiResponseListener listener) {

        Log.d(TAG, "Updating Schedule");
        List<Observable<ApiResponse>> requests = new ArrayList<>();
        final ArrayList<ApiResponse> responses = new ArrayList<>();

        for (Map.Entry<String, JsonObject> entry : map.entrySet()) {

            final String nodeId = entry.getKey();
            JsonObject jsonBody = entry.getValue();

            requests.add(
                    apiInterface.updateSchedules(AppConstants.URL_USER_NODES_PARAMS, accessToken, nodeId, jsonBody)

                            .map(new Function<ResponseBody, ApiResponse>() {

                                @Override
                                public ApiResponse apply(ResponseBody responseBody) throws Exception {

                                    ApiResponse apiResponse = new ApiResponse();
                                    apiResponse.responseBody = responseBody;
                                    apiResponse.isSuccessful = true;
                                    apiResponse.nodeId = nodeId;
                                    return apiResponse;
                                }
                            })
                            .onErrorReturn(new Function<Throwable, ApiResponse>() {

                                @Override
                                public ApiResponse apply(Throwable throwable) throws Exception {

                                    ApiResponse apiResponse = new ApiResponse();
                                    apiResponse.isSuccessful = false;
                                    apiResponse.throwable = throwable;
                                    apiResponse.nodeId = nodeId;
                                    return apiResponse;
                                }
                            }));
        }

        Observable.merge(requests)
                .take(requests.size())
                .doFinally(new io.reactivex.functions.Action() {

                    @Override
                    public void run() throws Exception {

                        Log.d(TAG, "Update schedule requests completed.");
                        boolean isAllReqSuccessful = true;

                        for (int i = 0; i < responses.size(); i++) {

                            if (!responses.get(i).isSuccessful) {
                                isAllReqSuccessful = false;
                                break;
                            }
                        }

                        if (isAllReqSuccessful) {
                            listener.onSuccess(null);
                        } else {
                            listener.onResponseFailure(new RuntimeException("Failed to update schedule for few devices"));
                        }
                    }
                })
                .subscribeOn(Schedulers.io())
                .subscribe(new Consumer<ApiResponse>() {

                    @Override
                    public void accept(ApiResponse apiResponse) throws Exception {

                        Log.d(TAG, "Response : " + apiResponse.nodeId);
                        Log.d(TAG, "Response : " + apiResponse.isSuccessful);
                        responses.add(apiResponse);
                    }
                }, new Consumer<Throwable>() {
                    @Override
                    public void accept(Throwable throwable) throws Exception {
                        Log.e("onSubscribe", "Throwable: " + throwable);
                    }
                });
    }

    public void updateScenes(final HashMap<String, JsonObject> map,
                             final ApiResponseListener listener) {

        Log.e(TAG, "Updating Scenes");
        JsonArray finalArray = new JsonArray();

        for (Map.Entry<String, JsonObject> entry : map.entrySet()) {

            final String nodeId = entry.getKey();
            JsonObject jsonBody = entry.getValue();

            JsonObject nodeObj = new JsonObject();
            nodeObj.addProperty(AppConstants.KEY_NODE_ID, nodeId);
            nodeObj.add(AppConstants.KEY_PAYLOAD, jsonBody);

            finalArray.add(nodeObj);
        }

        apiInterface.updateScenes(AppConstants.URL_USER_NODES_PARAMS, accessToken, finalArray).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                Log.d(TAG, "Get Node mapping status, Response code : " + response.code());
                try {
                    if (response.isSuccessful()) {
                        if (response.body() != null) {
                            String jsonResponse = response.body().string();
                            Log.e(TAG, "onResponse Success : " + jsonResponse);
                            Bundle data = new Bundle();
                            data.putString(AppConstants.KEY_RESPONSE, jsonResponse);
                            listener.onSuccess(data);
                        }
                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to update scene");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new Exception(t));
            }
        });
    }

    private void getAddNodeRequestStatus(final String nodeId, String requestId) {

        Log.d(TAG, "Get Node mapping status");

        apiInterface.getAddNodeRequestStatus(AppConstants.URL_USER_NODE_MAPPING, accessToken, requestId, true).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Get Node mapping status, Response code : " + response.code());

                if (response.isSuccessful()) {

                    if (response.body() != null) {
                        try {

                            String jsonResponse = response.body().string();
                            Log.e(TAG, "onResponse Success : " + jsonResponse);
                            JSONObject jsonObject = new JSONObject(jsonResponse);
                            String reqStatus = jsonObject.optString(AppConstants.KEY_REQ_STATUS);

                            if (!TextUtils.isEmpty(reqStatus) && reqStatus.equals(AppConstants.KEY_REQ_CONFIRMED)) {

                                requestIds.remove(nodeId);

                                // Send event for update UI
                                EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_ADDED));

                            } else if (!TextUtils.isEmpty(reqStatus) && reqStatus.equals(AppConstants.KEY_REQ_TIMEDOUT)) {

                                requestIds.remove(nodeId);

                                // Send event for update UI
                                EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_ADD_DEVICE_TIME_OUT));
                            }

                        } catch (IOException e) {
                            e.printStackTrace();
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    } else {
                        Log.e(TAG, "Get node mapping status failed");
                    }

                } else {
                    Log.e(TAG, "Get node mapping status failed");
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
            }
        });
    }

    private void getUserNodeMappingStatus() {

        handler.postDelayed(getUserNodeMappingStatusTask, REQ_STATUS_TIME);
    }

    private Runnable getUserNodeMappingStatusTask = new Runnable() {

        @Override
        public void run() {

            if (requestIds.size() > 0) {

                for (String key : requestIds.keySet()) {

                    String nodeId = key;
                    String requestId = requestIds.get(nodeId);
                    getAddNodeRequestStatus(nodeId, requestId);
                }
                getUserNodeMappingStatus();
            } else {
                Log.i(TAG, "No request id is available to check status");
                handler.removeCallbacks(getUserNodeMappingStatusTask);
            }
        }
    };

    public void initiateClaim(JsonObject body, final ApiResponseListener listener) {

        Log.d(TAG, "Initiate Claiming...");

        apiInterface.initiateClaiming(AppConstants.URL_CLAIM_INITIATE, accessToken, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "onResponse code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Bundle data = new Bundle();
                        data.putString(AppConstants.KEY_CLAIM_INIT_RESPONSE, jsonResponse);
                        listener.onSuccess(data);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Claim init failed");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Claim init failed"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Claim init failed"));
            }
        });
    }

    public void verifyClaiming(JsonObject body, final ApiResponseListener listener) {

        Log.d(TAG, "Verifying Claiming...");

        apiInterface.verifyClaiming(AppConstants.URL_CLAIM_VERIFY, accessToken, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Verify Claiming, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Bundle data = new Bundle();
                        data.putString(AppConstants.KEY_CLAIM_VERIFY_RESPONSE, jsonResponse);
                        listener.onSuccess(data);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Claim verify failed");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Claim verify failed"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Claim verify failed"));
            }
        });
    }

    public void createGroup(JsonObject body, final ApiResponseListener listener) {

        Log.d(TAG, "Create Group...");

        apiInterface.createGroup(AppConstants.URL_USER_NODE_GROUP, accessToken, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Create Group, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to create group");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to create group"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to create group"));
            }
        });
    }

    public void updateGroup(final String groupId, JsonObject body, final ApiResponseListener listener) {

        Log.d(TAG, "Update Group for group id : " + groupId);

        apiInterface.updateGroup(AppConstants.URL_USER_NODE_GROUP, accessToken, groupId, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Update Group, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        getUserGroups(groupId, listener);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to update group");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to update group"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to update group"));
            }
        });
    }

    public void removeGroup(final String groupId, final ApiResponseListener listener) {

        Log.d(TAG, "Remove Group, group id : " + groupId);

        apiInterface.removeGroup(AppConstants.URL_USER_NODE_GROUP, accessToken, groupId).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Remove Group, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        espDatabase.getGroupDao().delete(espApp.groupMap.get(groupId));
                        espApp.groupMap.remove(groupId);
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to remove group");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to remove group"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                Log.e(TAG, "ON FAILURE");
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to remove group"));
            }
        });
    }

    public void getUserGroups(final String groupId, final ApiResponseListener listener) {

        Log.d(TAG, "Get user groups...");

        apiInterface.getUserGroups(AppConstants.URL_USER_NODE_GROUP, accessToken, groupId, true).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Get Groups, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        JSONObject jsonObject = new JSONObject(jsonResponse);
                        JSONArray groupJsonArray = jsonObject.optJSONArray(AppConstants.KEY_GROUPS);

                        if (TextUtils.isEmpty(groupId)) {
                            espDatabase.getGroupDao().deleteAll();
                        }

                        if (groupJsonArray != null) {

                            for (int groupIndex = 0; groupIndex < groupJsonArray.length(); groupIndex++) {

                                JSONObject groupJson = groupJsonArray.optJSONObject(groupIndex);

                                if (groupJson != null) {

                                    // Node ID
                                    String gId = groupJson.optString(AppConstants.KEY_GROUP_ID);
                                    String groupName = groupJson.optString(AppConstants.KEY_GROUP_NAME);
                                    JSONArray nodesArray = groupJson.optJSONArray(AppConstants.KEY_NODES);
                                    ArrayList<String> nodesOfGroup = new ArrayList<>();

                                    if (nodesArray != null) {
                                        for (int nodeIndex = 0; nodeIndex < nodesArray.length(); nodeIndex++) {
                                            nodesOfGroup.add(nodesArray.optString(nodeIndex));
                                        }
                                    }

                                    Group group = new Group(groupName);
                                    group.setGroupId(gId);
                                    group.setNodeList(nodesOfGroup);
                                    espApp.groupMap.put(gId, group);
                                    espDatabase.getGroupDao().insertOrUpdate(group);
                                }
                            }
                        }
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to get user groups");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to get user groups"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to get user groups"));
            }
        });
    }

    public void getSharingRequests(boolean isPrimaryUser, final ApiResponseListener listener) {

        Log.d(TAG, "Get sharing requests");
        ArrayList<SharingRequest> sharingRequests = new ArrayList<>();
        getSharingRequests("", "", isPrimaryUser, sharingRequests, listener);
    }

    private void getSharingRequests(final String startReqId, final String startUserName, final boolean isPrimaryUser,
                                    final ArrayList<SharingRequest> sharingRequests, final ApiResponseListener listener) {

        Log.d(TAG, "Get sharing request, start request id : " + startReqId);
        apiInterface.getSharingRequests(AppConstants.URL_USER_NODES_SHARING_REQUESTS, accessToken, isPrimaryUser,
                startReqId, startUserName).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Get sharing requests, Response code : " + response.code());

                try {
                    if (response.isSuccessful()) {
                        if (response.body() != null) {
                            String jsonResponse = response.body().string();
                            Log.d(TAG, "Response : " + jsonResponse);
                            JSONObject jsonObject = new JSONObject(jsonResponse);
                            JSONArray nodeJsonArray = jsonObject.optJSONArray(AppConstants.KEY_SHARING_REQUESTS);

                            if (nodeJsonArray != null) {

                                for (int nodeIndex = 0; nodeIndex < nodeJsonArray.length(); nodeIndex++) {

                                    JSONObject nodeJson = nodeJsonArray.optJSONObject(nodeIndex);

                                    if (nodeJson != null) {

                                        String reqId = nodeJson.optString(AppConstants.KEY_REQ_ID);
                                        if (TextUtils.isEmpty(reqId)) {
                                            continue;
                                        }
                                        SharingRequest sharingReq = new SharingRequest(reqId);
                                        sharingReq.setReqStatus(nodeJson.optString(AppConstants.KEY_REQ_STATUS));
                                        sharingReq.setReqTime(nodeJson.optLong(AppConstants.KEY_REQ_TIME, 0));
                                        sharingReq.setUserName(nodeJson.optString(AppConstants.KEY_USER_NAME));
                                        sharingReq.setPrimaryUserName(nodeJson.optString(AppConstants.KEY_PRIMARY_USER_NAME));
                                        sharingReq.setReqTime(nodeJson.optLong(AppConstants.KEY_REQ_TIMESTAMP));
                                        JSONObject metadataJson = nodeJson.optJSONObject(AppConstants.KEY_METADATA);
                                        if (metadataJson != null) {
                                            sharingReq.setMetadata(metadataJson.toString());
                                        }

                                        JSONArray nodeIdListJson = nodeJson.optJSONArray(AppConstants.KEY_NODE_IDS);
                                        ArrayList<String> nodeIds = new ArrayList<>();

                                        if (nodeIdListJson != null) {
                                            for (int k = 0; k < nodeIdListJson.length(); k++) {
                                                nodeIds.add(nodeIdListJson.optString(k));
                                            }
                                        }
                                        sharingReq.setNodeIds(nodeIds);
                                        sharingRequests.add(sharingReq);
                                    }
                                }
                            }

                            String nextId = jsonObject.optString(AppConstants.KEY_NEXT_REQ_ID);
                            String nextUserName = jsonObject.optString(AppConstants.KEY_NEXT_USER_NAME);

                            if (!TextUtils.isEmpty(nextId)) {
                                getSharingRequests(nextId, nextUserName, isPrimaryUser, sharingRequests, listener);
                            } else {
                                Bundle data = new Bundle();
                                Log.d(TAG, "Number of sharing request : " + sharingRequests.size());
                                data.putParcelableArrayList(AppConstants.KEY_SHARING_REQUESTS, sharingRequests);
                                listener.onSuccess(data);
                            }

                        } else {
                            Log.e(TAG, "Response received : null");
                            listener.onResponseFailure(new RuntimeException("Failed to get sharing requests"));
                        }

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to get sharing requests");
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                } catch (IOException e) {
                    e.printStackTrace();
                    listener.onResponseFailure(e);
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new Exception(t));
            }
        });
    }

    public void updateSharingRequest(final String requestId, final boolean requestAccepted, final ApiResponseListener listener) {

        Log.d(TAG, "Update sharing request status with : " + requestAccepted + " for request id : " + requestId);

        JsonObject body = new JsonObject();
        body.addProperty(AppConstants.KEY_REQ_ACCEPT, requestAccepted);
        body.addProperty(AppConstants.KEY_REQ_ID, requestId);

        apiInterface.updateSharingRequest(AppConstants.URL_USER_NODES_SHARING_REQUESTS, accessToken, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Update Sharing request, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {
                        String jsonResponse = response.body().string();
                        Log.e(TAG, "onResponse Success : " + jsonResponse);
                        listener.onSuccess(null);
                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to update sharing request");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to update sharing request"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to update sharing request"));
            }
        });
    }

    public void removeSharingRequest(final String requestId, final ApiResponseListener listener) {

        Log.d(TAG, "Remove sharing request : " + requestId);

        apiInterface.removeSharingRequest(AppConstants.URL_USER_NODES_SHARING_REQUESTS, accessToken, requestId).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Remove Sharing request, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {
                        String jsonResponse = response.body().string();
                        listener.onSuccess(null);
                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to remove sharing request");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to remove sharing request"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to remove sharing request"));
            }
        });
    }

    public void shareNodeWithUser(final String nodeId, final String email, final ApiResponseListener listener) {

        Log.d(TAG, "Share Node " + nodeId + " with + User " + email);

        JsonObject body = new JsonObject();
        JsonArray nodes = new JsonArray();
        nodes.add(nodeId);
        body.add(AppConstants.KEY_NODES, nodes);
        body.addProperty(AppConstants.KEY_USER_NAME, email);

        ArrayList<Device> devices = espApp.nodeMap.get(nodeId).getDevices();
        JsonArray devicesJsonArr = new JsonArray();

        if (devices != null) {
            for (int i = 0; i < devices.size(); i++) {
                JsonObject deviceJson = new JsonObject();
                deviceJson.addProperty(AppConstants.KEY_NAME, devices.get(i).getUserVisibleName());
                devicesJsonArr.add(deviceJson);
            }
        }

        JsonObject metadataJson = new JsonObject();
        metadataJson.add(AppConstants.KEY_DEVICES, devicesJsonArr);
        body.add(AppConstants.KEY_METADATA, metadataJson);

        apiInterface.shareNodeWithUser(AppConstants.URL_USER_NODES_SHARING, accessToken, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Share node, Response code  : " + response.code());
                try {
                    if (response.isSuccessful()) {
                        String jsonResponse = response.body().string();
                        JSONObject jsonObject = new JSONObject(jsonResponse);
                        String requestId = jsonObject.optString(AppConstants.KEY_REQ_ID);
                        Bundle bundle = new Bundle();
                        bundle.putString(AppConstants.KEY_REQ_ID, requestId);
                        bundle.putString(AppConstants.KEY_EMAIL, email);
                        listener.onSuccess(bundle);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Node sharing failed");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Node sharing failed"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Node sharing failed"));
            }
        });
    }

    public void getNodeSharing(final String nodeId, final ApiResponseListener listener) {

        Log.d(TAG, "Get Node Sharing information for node : " + nodeId);

        apiInterface.getNodeSharing(AppConstants.URL_USER_NODES_SHARING, accessToken, nodeId).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Get node sharing info, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Sharing response : " + jsonResponse);
                        JSONObject jsonObject = new JSONObject(jsonResponse);
                        JSONArray nodeSharingJsonArray = jsonObject.optJSONArray(AppConstants.KEY_NODE_SHARING);

                        ArrayList<String> primaryUsers = new ArrayList<>();
                        ArrayList<String> secondaryUsers = new ArrayList<>();

                        if (nodeSharingJsonArray != null && nodeSharingJsonArray.length() > 0) {

                            JSONObject nodeSharingJson = nodeSharingJsonArray.optJSONObject(0);

                            if (nodeSharingJson != null) {

                                JSONObject usersJson = nodeSharingJson.optJSONObject(AppConstants.KEY_USERS);

                                if (usersJson != null) {

                                    JSONArray primaryJsonArray = usersJson.optJSONArray(AppConstants.KEY_USER_ROLE_PRIMARY);
                                    JSONArray secondaryJsonArray = usersJson.optJSONArray(AppConstants.KEY_USER_ROLE_SECONDARY);

                                    if (primaryJsonArray != null && primaryJsonArray.length() > 0) {
                                        for (int i = 0; i < primaryJsonArray.length(); i++) {
                                            String email = primaryJsonArray.optString(i);
                                            primaryUsers.add(email);
                                        }
                                    }

                                    if (secondaryJsonArray != null && secondaryJsonArray.length() > 0) {
                                        for (int i = 0; i < secondaryJsonArray.length(); i++) {
                                            String email = secondaryJsonArray.optString(i);
                                            secondaryUsers.add(email);
                                        }
                                    }

                                    EspNode node = espApp.nodeMap.get(nodeId);
                                    if (node != null) {
                                        node.setPrimaryUsers(primaryUsers);
                                        node.setSecondaryUsers(secondaryUsers);
                                    }
                                }
                            }
                        }

                        Bundle data = new Bundle();
                        data.putStringArrayList(AppConstants.KEY_PRIMARY_USERS, primaryUsers);
                        data.putStringArrayList(AppConstants.KEY_SECONDARY_USERS, secondaryUsers);
                        listener.onSuccess(data);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to get node sharing info");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to get node sharing info"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to get node sharing info"));
            }
        });
    }

    public void removeSharing(final String nodeId, final String email, final ApiResponseListener listener) {

        Log.d(TAG, "Remove user : " + email + " from sharing, for nodes : " + nodeId);

        apiInterface.removeSharing(AppConstants.URL_USER_NODES_SHARING, accessToken, nodeId, email).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.d(TAG, "Remove Sharing, Response code  : " + response.code());
                try {
                    if (response.isSuccessful()) {

                        String jsonResponse = response.body().string();
                        espApp.nodeMap.get(nodeId).getSecondaryUsers().remove(email);
                        listener.onSuccess(null);

                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to remove sharing");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to remove sharing"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to remove sharing"));
            }
        });
    }

    public void registerDeviceToken(final String deviceToken, final ApiResponseListener listener) {

        Log.d(TAG, "Register device token : " + deviceToken);
        String url = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
                + AppConstants.CURRENT_VERSION + "/user/push_notification/mobile_platform_endpoint";

        JsonObject body = new JsonObject();
        body.addProperty(AppConstants.KEY_PLATFORM, AppConstants.KEY_GCM);
        body.addProperty(AppConstants.KEY_MOBILE_DEVICE_TOKEN, deviceToken);

        apiInterface.registerDeviceToken(url, accessToken, body).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.e(TAG, "Register FCM token, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {
                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);
                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to register fcm token");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to register fcm token"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to register fcm token"));
            }
        });
    }

    public void unregisterDeviceToken(final String deviceToken, final ApiResponseListener listener) {

        Log.d(TAG, "Unregister FCM token...");
        String url = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
                + AppConstants.CURRENT_VERSION + "/user/push_notification/mobile_platform_endpoint";

        apiInterface.unregisterDeviceToken(url, accessToken, deviceToken).enqueue(new Callback<ResponseBody>() {

            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                Log.e(TAG, "Unregister FCM token, Response code  : " + response.code());

                try {
                    if (response.isSuccessful()) {
                        String jsonResponse = response.body().string();
                        Log.e(TAG, "Response : " + jsonResponse);
                        listener.onSuccess(null);
                    } else {
                        String jsonErrResponse = response.errorBody().string();
                        processError(jsonErrResponse, listener, "Failed to unregister fcm token");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    listener.onResponseFailure(new RuntimeException("Failed to unregister fcm token"));
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                t.printStackTrace();
                listener.onNetworkFailure(new RuntimeException("Failed to unregister fcm token"));
            }
        });
    }

    private void processError(String jsonErrResponse, ApiResponseListener listener, String errMsg) {

        Log.e(TAG, "Error Response : " + jsonErrResponse);
        try {
            if (jsonErrResponse.contains(AppConstants.KEY_FAILURE_RESPONSE)) {

                JSONObject jsonObject = new JSONObject(jsonErrResponse);
                String err = jsonObject.optString(AppConstants.KEY_DESCRIPTION);

                if (!TextUtils.isEmpty(err)) {
                    listener.onResponseFailure(new CloudException(err));
                } else {
                    listener.onResponseFailure(new RuntimeException(errMsg));
                }
            } else {
                listener.onResponseFailure(new RuntimeException(errMsg));
            }
        } catch (JSONException e) {
            e.printStackTrace();
            listener.onResponseFailure(new RuntimeException(errMsg));
        }
    }

    private Runnable stopRequestStatusPollingTask = new Runnable() {

        @Override
        public void run() {
            requestIds.clear();
            Log.d(TAG, "Stopped Polling Task");
            handler.removeCallbacks(getUserNodeMappingStatusTask);
            EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_ADD_DEVICE_TIME_OUT));
        }
    };

    public void cancelRequestStatusPollingTask() {
        handler.removeCallbacks(stopRequestStatusPollingTask);
    }
}
