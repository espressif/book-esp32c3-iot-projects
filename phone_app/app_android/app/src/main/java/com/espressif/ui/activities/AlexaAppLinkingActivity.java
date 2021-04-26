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

import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.coordinatorlayout.widget.CoordinatorLayout;
import androidx.lifecycle.Observer;
import androidx.work.Data;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkInfo;
import androidx.work.WorkManager;

import com.espressif.AlexaLinkingWorker;
import com.espressif.AppConstants;
import com.espressif.cloudapi.AlexaApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.card.MaterialCardView;

public class AlexaAppLinkingActivity extends AppCompatActivity {

    private static final String TAG = "AlexaAppLinking";
    private static final long REQUIRED_MINIMUM_VERSION_CODE = 866607211;

    private MaterialCardView btnAppLink;
    private TextView txtAppLinkBtn;
    private RelativeLayout rlLinkingProgress;
    private CoordinatorLayout rlAlexaAppLink;
    private ConstraintLayout layoutLink, layoutUnlink;

    private static String alexaCode = "", alexaAuthCode = "";
    private AlexaApiManager apiManager;
    private SharedPreferences sharedPreferences;
    private boolean isLinked = false;
    private boolean shouldGetAuthCode = false;
    private boolean isReturnedFromBrowser = false;

    private AppLinkingProgress appLinkingProgress = AppLinkingProgress.NONE;

    enum AppLinkingProgress {
        NONE,
        GET_ALEXA_CODE,
        GET_ALEXA_TOKEN,
        GET_LINKING_STATUS,
        GET_AUTH_CODE,
        ENABLING_SKILL,
        DISABLING_SKILL
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_alexa_app_linking);

        apiManager = AlexaApiManager.getInstance(getApplicationContext());
        sharedPreferences = getSharedPreferences(AppConstants.ESP_PREFERENCES, Context.MODE_PRIVATE);

        String alexaRefreshToken = sharedPreferences.getString(AppConstants.KEY_ALEXA_REFRESH_TOKEN, "");

        initViews();
        updateUi();

        if (!TextUtils.isEmpty(alexaRefreshToken)) {

            Log.d(TAG, "Get Linking Status....");
            appLinkingProgress = AppLinkingProgress.GET_ALEXA_TOKEN;
            showLoading("Getting linking status...");

            apiManager.getNewToken(new ApiResponseListener() {

                @Override
                public void onSuccess(Bundle data) {
                    try {
                        appLinkingProgress = AppLinkingProgress.GET_LINKING_STATUS;
                        Data inoutData = new Data.Builder()
                                .putString(AppConstants.KEY_EVENT_TYPE, AppConstants.EVENT_GET_STATUS)
                                .build();

                        OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(AlexaLinkingWorker.class)
                                .setInputData(inoutData)
                                .build();

                        WorkManager workManager = WorkManager.getInstance(getApplicationContext());
                        workManager.enqueue(workRequest);
                        workManager.getWorkInfoByIdLiveData(workRequest.getId())
                                .observe(AlexaAppLinkingActivity.this, new Observer<WorkInfo>() {

                                    @Override
                                    public void onChanged(@Nullable WorkInfo workInfo) {

                                        if (workInfo != null) {
                                            Log.i("AppLinkingWorkRequest", "Status changed to : " + workInfo.getState());

                                            if (workInfo.getState().equals(WorkInfo.State.SUCCEEDED)) {
                                                hideLoading();
                                                isLinked = true;
                                                updateUi();
                                            }
                                            if (workInfo.getState().equals(WorkInfo.State.FAILED)) {
                                                hideLoading();
                                                isLinked = false;
                                                updateUi();
                                            }
                                        }
                                    }
                                });
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }

                @Override
                public void onResponseFailure(Exception exception) {
                    updateUi();
                    hideLoading();
                }

                @Override
                public void onNetworkFailure(Exception exception) {
                    updateUi();
                    hideLoading();
                    Toast.makeText(AlexaAppLinkingActivity.this, R.string.msg_no_internet, Toast.LENGTH_LONG).show();
                }
            });
        }
    }

    @Override
    protected void onResume() {
        super.onResume();

        if (!isReturnedFromBrowser) {
            isReturnedFromBrowser = false;
            if (!appLinkingProgress.equals(AppLinkingProgress.GET_ALEXA_TOKEN)) {
                hideLoading();
            }
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        isReturnedFromBrowser = true;

        if (intent.getData() != null) {

            String data = intent.getData().toString();
            Log.d(TAG, "Data : " + data);

            if (data.contains(AppConstants.STATE)) {

                data = data.replace(BuildConfig.ALEXA_REDIRECT_URL, "");
                data = data.replace("?code=", "");
                data = data.replace("&state=", "");
                data = data.replace(AppConstants.STATE, "");

                if (data.contains("error")) {
                    Log.e(TAG, "Received error : " + data);
                    hideLoading();
                    return;
                }

                if (appLinkingProgress.equals(AppLinkingProgress.GET_ALEXA_CODE)) {

                    Log.d(TAG, "Received Alexa Code : " + data);
                    alexaCode = data;

                    appLinkingProgress = AppLinkingProgress.GET_ALEXA_TOKEN;
                    showLoading("Getting alexa token...");

                    apiManager.getAlexaAccessToken(BuildConfig.ALEXA_REDIRECT_URL, alexaCode, new ApiResponseListener() {

                        @Override
                        public void onSuccess(Bundle data) {

                            appLinkingProgress = AppLinkingProgress.GET_LINKING_STATUS;
                            showLoading("Getting linking status...");
                            apiManager.getApiEndpoints(new ApiResponseListener() {

                                @Override
                                public void onSuccess(Bundle data) {
                                    shouldGetAuthCode = true;
                                    getLinkingStatus();
                                }

                                @Override
                                public void onResponseFailure(Exception exception) {
                                    updateUi();
                                    hideLoading();
                                }

                                @Override
                                public void onNetworkFailure(Exception exception) {
                                    updateUi();
                                    hideLoading();
                                }
                            });
                        }

                        @Override
                        public void onResponseFailure(Exception exception) {
                            updateUi();
                            hideLoading();
                        }

                        @Override
                        public void onNetworkFailure(Exception exception) {
                            updateUi();
                            hideLoading();
                        }
                    });
                } else if (appLinkingProgress.equals(AppLinkingProgress.GET_AUTH_CODE)) {

                    Log.d(TAG, "Received Alexa Auth Code : " + data);
                    alexaAuthCode = data;
                    appLinkingProgress = AppLinkingProgress.ENABLING_SKILL;
                    showLoading("Enabling skill...");
                    Data inputData = new Data.Builder()
                            .putString(AppConstants.KEY_EVENT_TYPE, AppConstants.EVENT_ENABLE_SKILL)
                            .putString(AppConstants.KEY_AUTH_CODE, alexaAuthCode)
                            .build();

                    OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(AlexaLinkingWorker.class)
                            .setInputData(inputData)
                            .build();

                    WorkManager workManager = WorkManager.getInstance(getApplicationContext());
                    workManager.enqueue(workRequest);
                    workManager.getWorkInfoByIdLiveData(workRequest.getId())
                            .observe(this, new Observer<WorkInfo>() {

                                @Override
                                public void onChanged(@Nullable WorkInfo workInfo) {
                                    if (workInfo != null) {
                                        Log.d("AppLinkingWorkRequest", "Status changed to : " + workInfo.getState());

                                        if (workInfo.getState().equals(WorkInfo.State.SUCCEEDED)) {
                                            isLinked = true;
                                            updateUi();
                                            hideLoading();
                                        }
                                        if (workInfo.getState().equals(WorkInfo.State.FAILED)) {
                                            isLinked = false;
                                            updateUi();
                                            hideLoading();
                                            Toast.makeText(AlexaAppLinkingActivity.this, "Failed to link with Amazon Alexa", Toast.LENGTH_LONG).show();
                                        }
                                    }
                                }
                            });
                }
            }
        }
    }

    private void getAuthCode() {
        Log.d(TAG, "Getting auth code");
        isReturnedFromBrowser = false;
        appLinkingProgress = AppLinkingProgress.GET_AUTH_CODE;

        showLoading("Getting auth code...");
        String uriStr = BuildConfig.AUTH_URL
                + "/authorize?response_type=code"
                + "&client_id=" + BuildConfig.ALEXA_RM_CLIENT_ID
                + "&redirect_uri=" + BuildConfig.ALEXA_REDIRECT_URL
                + "&state=" + AppConstants.STATE + "&scope=aws.cognito.signin.user.admin";
        Log.d(TAG, "URL : " + uriStr);
        Uri uri = Uri.parse(uriStr);
        Intent openURL = new Intent(Intent.ACTION_VIEW, uri);
        startActivity(openURL);
    }

    private void getLinkingStatus() {
        try {
            Data inoutData = new Data.Builder()
                    .putString(AppConstants.KEY_EVENT_TYPE, AppConstants.EVENT_GET_STATUS)
                    .build();

            OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(AlexaLinkingWorker.class)
                    .setInputData(inoutData)
                    .build();

            WorkManager workManager = WorkManager.getInstance(getApplicationContext());
            workManager.enqueue(workRequest);
            workManager.getWorkInfoByIdLiveData(workRequest.getId())
                    .observe(AlexaAppLinkingActivity.this, new Observer<WorkInfo>() {

                        @Override
                        public void onChanged(@Nullable WorkInfo workInfo) {

                            if (workInfo != null) {
                                Log.d("AppLinkingWorkRequest", "Status changed to : " + workInfo.getState());

                                if (workInfo.getState().equals(WorkInfo.State.SUCCEEDED)) {
                                    isLinked = true;
                                    updateUi();
                                    hideLoading();
                                }
                                if (workInfo.getState().equals(WorkInfo.State.FAILED)) {
                                    isLinked = false;
                                    updateUi();

                                    if (shouldGetAuthCode) {
                                        getAuthCode();
                                        shouldGetAuthCode = false;
                                    } else {
                                        hideLoading();
                                    }
                                }
                            }
                        }
                    });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void updateUi() {
        if (isLinked) {
            layoutLink.setVisibility(View.GONE);
            layoutUnlink.setVisibility(View.VISIBLE);
            txtAppLinkBtn.setText(R.string.btn_unlink_alexa);
        } else {
            layoutLink.setVisibility(View.VISIBLE);
            layoutUnlink.setVisibility(View.GONE);
            txtAppLinkBtn.setText(R.string.btn_link_alexa);
        }
    }

    private boolean doesAlexaAppSupportAppToApp() {
        try {
            PackageManager packageManager = getPackageManager();
            PackageInfo packageInfo = packageManager.getPackageInfo(AppConstants.ALEXA_PACKAGE_NAME, 0);

            Log.d(TAG, "Version : " + Build.VERSION.SDK_INT);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                Log.d(TAG, "getLongVersionCode : " + packageInfo.getLongVersionCode());

                if (packageInfo.getLongVersionCode() > REQUIRED_MINIMUM_VERSION_CODE) {
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }

        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
            // The Alexa App is not installed
            return false;
        }
    }

    View.OnClickListener btnAppLinkClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {

            Log.d(TAG, "Amazon Alexa button clicked.");

            if (isLinked) {
                confirmUnlink();
            } else {
                alexaCode = "";
                appLinkingProgress = AppLinkingProgress.GET_ALEXA_CODE;
                showLoading("Getting code...");
                isReturnedFromBrowser = false;

                if (doesAlexaAppSupportAppToApp()) {
                    String url = AppConstants.ALEXA_APP_URL + "&client_id=" + BuildConfig.ALEXA_CLIENT_ID
                            + "&scope=" + AppConstants.LWA_SCOPE + "&skill_stage=" + BuildConfig.SKILL_STAGE
                            + "&response_type=code" + "&redirect_uri=" + BuildConfig.ALEXA_REDIRECT_URL
                            + "&state=" + AppConstants.STATE;
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
                } else {
                    String fallbackUrl = AppConstants.LWA_URL + "?client_id=" + BuildConfig.ALEXA_CLIENT_ID
                            + "&scope=" + AppConstants.LWA_SCOPE + "&response_type=code"
                            + "&redirect_uri=" + BuildConfig.ALEXA_REDIRECT_URL
                            + "&state=" + AppConstants.STATE;
                    Log.d(TAG, "URL : " + fallbackUrl);
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(fallbackUrl)));
                }
            }
        }
    };

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setTitle(R.string.title_activity_amazon_alexa);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        btnAppLink = findViewById(R.id.btn_alexa_app_link);
        txtAppLinkBtn = findViewById(R.id.text_btn);
        btnAppLink.findViewById(R.id.iv_arrow).setVisibility(View.GONE);
        txtAppLinkBtn.setText(R.string.btn_link_alexa);
        btnAppLink.setOnClickListener(btnAppLinkClickListener);

        layoutLink = findViewById(R.id.layout_alexa_link);
        layoutUnlink = findViewById(R.id.layout_alexa_unlink);

        rlAlexaAppLink = findViewById(R.id.rl_amazon_alexa);
        rlLinkingProgress = findViewById(R.id.rl_progress_app_linking);
    }

    private void confirmUnlink() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.dialog_title_unlink_skill);
        builder.setMessage(R.string.dialog_msg_unlink_skill);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_yes, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
                unlinkAlexaSkill();
            }
        });

        builder.setNegativeButton(R.string.btn_no, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });

        AlertDialog userDialog = builder.create();
        userDialog.show();
    }

    private void unlinkAlexaSkill() {

        showLoading("Unlinking skill...");

        Data data = new Data.Builder()
                .putString(AppConstants.KEY_EVENT_TYPE, AppConstants.EVENT_DISABLE_SKILL)
                .build();
        OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(AlexaLinkingWorker.class)
                .setInputData(data)
                .build();
        WorkManager workManager = WorkManager.getInstance(getApplicationContext());
        workManager.enqueue(workRequest);
        workManager.getWorkInfoByIdLiveData(workRequest.getId())
                .observe(AlexaAppLinkingActivity.this, new Observer<WorkInfo>() {

                    @Override
                    public void onChanged(@Nullable WorkInfo workInfo) {
                        if (workInfo != null) {
                            Log.d("AppLinkingWorkRequest", "Status changed to : " + workInfo.getState());

                            if (workInfo.getState().equals(WorkInfo.State.SUCCEEDED)) {
                                isLinked = false;
                            } else if (workInfo.getState().equals(WorkInfo.State.FAILED)) {
                                isLinked = true;
                                Toast.makeText(AlexaAppLinkingActivity.this, "Failed to unlink from Amazon Alexa", Toast.LENGTH_LONG).show();
                            }
                            updateUi();
                            hideLoading();
                        }
                    }
                });
    }

    private void showLoading(String msg) {
        rlAlexaAppLink.setAlpha(0.3f);
        rlLinkingProgress.setVisibility(View.VISIBLE);
        TextView progressText = findViewById(R.id.tv_loading_app_linking);
//        progressText.setText(msg);
        progressText.setVisibility(View.GONE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
    }

    private void hideLoading() {
        rlAlexaAppLink.setAlpha(1);
        rlLinkingProgress.setVisibility(View.GONE);
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
    }
}
