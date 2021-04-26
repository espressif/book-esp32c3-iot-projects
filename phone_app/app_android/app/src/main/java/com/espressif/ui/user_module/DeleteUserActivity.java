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

package com.espressif.ui.user_module;

import android.content.DialogInterface;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;

import com.espressif.EspApplication;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.rainmaker.R;
import com.espressif.ui.Utils;
import com.espressif.ui.fragments.DeleteUserConfirmFragment;
import com.espressif.ui.fragments.DeleteUserRequestFragment;
import com.google.android.material.appbar.MaterialToolbar;

public class DeleteUserActivity extends AppCompatActivity {

    private ApiManager apiManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_delete_user);
        apiManager = ApiManager.getInstance(getApplicationContext());
        initViews();
    }

    @Override
    public void onBackPressed() {

        Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container);

        if (currentFragment instanceof DeleteUserConfirmFragment) {
            Fragment deleteUserReqFragment = new DeleteUserRequestFragment();
            loadDeleteUserReqFragment(deleteUserReqFragment);
        } else {
            super.onBackPressed();
        }
    }

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setTitle(R.string.title_activity_delete_user);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container);
                if (currentFragment instanceof DeleteUserConfirmFragment) {
                    onBackPressed();
                } else {
                    finish();
                }
            }
        });

        Fragment deleteUserReqFragment = new DeleteUserRequestFragment();
        loadDeleteUserReqFragment(deleteUserReqFragment);
    }

    private void loadDeleteUserReqFragment(Fragment deleteUserReqFragment) {

        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.replace(R.id.fragment_container, deleteUserReqFragment);
        transaction.commit();
    }

    private void loadDeleteUserConfirmFragment(Fragment deleteUserConfirmFragment) {

        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.replace(R.id.fragment_container, deleteUserConfirmFragment);
        transaction.commit();
    }

    public void sendDeleteUserRequest() {

        apiManager.deleteUserRequest(true, new ApiResponseListener() {
            @Override
            public void onSuccess(Bundle data) {
                hideLoading();
                getDeleteUserCode();
            }

            @Override
            public void onResponseFailure(Exception exception) {
                hideLoading();
                if (exception instanceof CloudException) {
                    Utils.showAlertDialog(DeleteUserActivity.this, getString(R.string.dialog_title_delete_user_failed), exception.getMessage(), false);
                } else {
                    Utils.showAlertDialog(DeleteUserActivity.this, "", getString(R.string.dialog_title_delete_user_failed), false);
                }
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                hideLoading();
                Utils.showAlertDialog(DeleteUserActivity.this, getString(R.string.dialog_title_no_network), getString(R.string.dialog_msg_no_network), false);
            }
        });
    }

    public void confirmDeleteAccount(String verificationCode) {

        apiManager.deleteUserConfirm(verificationCode, new ApiResponseListener() {
            @Override
            public void onSuccess(Bundle data) {
                hideLoading();
                showSuccessDialog(getString(R.string.dialog_title_delete_user_success), "");
            }

            @Override
            public void onResponseFailure(Exception exception) {
                hideLoading();
                if (exception instanceof CloudException) {
                    Utils.showAlertDialog(DeleteUserActivity.this, getString(R.string.dialog_title_delete_user_failed), exception.getMessage(), false);
                } else {
                    Utils.showAlertDialog(DeleteUserActivity.this, "", getString(R.string.dialog_title_delete_user_failed), false);
                }
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                hideLoading();
                Utils.showAlertDialog(DeleteUserActivity.this, getString(R.string.dialog_title_no_network), getString(R.string.dialog_msg_no_network), false);
            }
        });
    }

    private void getDeleteUserCode() {
        Fragment deleteUserConfirmFragment = new DeleteUserConfirmFragment();
        loadDeleteUserConfirmFragment(deleteUserConfirmFragment);
    }

    private void hideLoading() {

        Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container);

        if (currentFragment instanceof DeleteUserRequestFragment) {

            ((DeleteUserRequestFragment) currentFragment).hideLoading();

        } else if (currentFragment instanceof DeleteUserConfirmFragment) {

            ((DeleteUserConfirmFragment) currentFragment).hideLoading();
        }
    }

    private void showSuccessDialog(String title, String msg) {

        final AlertDialog.Builder builder = new AlertDialog.Builder(this);

        if (!TextUtils.isEmpty(title)) {
            builder.setTitle(title);
        }
        builder.setMessage(msg);
        builder.setCancelable(false);
        builder.setNeutralButton(R.string.btn_ok, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
                EspApplication espApp = (EspApplication) getApplicationContext();
                espApp.clearUserSession();
            }
        });
        AlertDialog dialog = builder.create();
        dialog.show();
    }
}
