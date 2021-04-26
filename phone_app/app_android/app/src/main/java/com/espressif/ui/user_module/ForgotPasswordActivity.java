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

package com.espressif.ui.user_module;

import android.os.Bundle;
import android.view.View;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;

import com.espressif.AppConstants;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.rainmaker.R;
import com.espressif.ui.Utils;
import com.espressif.ui.fragments.ForgotPasswordFragment;
import com.espressif.ui.fragments.ResetPasswordFragment;
import com.google.android.material.appbar.MaterialToolbar;

public class ForgotPasswordActivity extends AppCompatActivity {

    private String email;
    private MaterialToolbar toolbar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_forgot_password);
        initViews();
    }

    @Override
    public void onBackPressed() {

        Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container);

        if (currentFragment instanceof ResetPasswordFragment) {
            Fragment forgotPasswordFragment = new ForgotPasswordFragment();
            Bundle data = new Bundle();
            data.putString(AppConstants.KEY_USER_NAME, email);
            forgotPasswordFragment.setArguments(data);
            loadForgotPasswordFragment(forgotPasswordFragment);
        }else{
            super.onBackPressed();
        }
    }

    private void initViews() {

        toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setTitle(R.string.title_activity_forgot_password);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container);
                if (currentFragment instanceof ResetPasswordFragment) {
                    onBackPressed();
                } else {
                    finish();
                }
            }
        });

        Fragment forgotPasswordFragment = new ForgotPasswordFragment();
        loadForgotPasswordFragment(forgotPasswordFragment);
    }

    private void loadForgotPasswordFragment(Fragment forgotPasswordFragment) {

        toolbar.setTitle(R.string.title_activity_forgot_password);

        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.replace(R.id.fragment_container, forgotPasswordFragment);
        transaction.commit();
    }

    private void loadResetPasswordFragment(Fragment resetPasswordFragment) {

        toolbar.setTitle(R.string.title_activity_reset_password);

        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.replace(R.id.fragment_container, resetPasswordFragment);
        transaction.commit();
    }

    public void forgotPassword(final String email) {

        this.email = email;
        ApiManager apiManager = ApiManager.getInstance(getApplicationContext());
        apiManager.forgotPassword(email, new ApiResponseListener() {
            @Override
            public void onSuccess(Bundle data) {
                hideLoading();
                getForgotPasswordCode(email);
            }

            @Override
            public void onResponseFailure(Exception exception) {
                hideLoading();
                if (exception instanceof CloudException) {
                    Utils.showAlertDialog(ForgotPasswordActivity.this, getString(R.string.dialog_title_forgot_password_failed), exception.getMessage(), false);
                } else {
                    Utils.showAlertDialog(ForgotPasswordActivity.this, "", getString(R.string.dialog_title_forgot_password_failed), false);
                }
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                hideLoading();
                Utils.showAlertDialog(ForgotPasswordActivity.this, getString(R.string.dialog_title_no_network), getString(R.string.dialog_msg_no_network), false);
            }
        });
    }

    public void resetPassword(String newPassword, String verificationCode) {

        ApiManager apiManager = ApiManager.getInstance(getApplicationContext());
        apiManager.resetPassword(email, newPassword, verificationCode, new ApiResponseListener() {
            @Override
            public void onSuccess(Bundle data) {
                hideLoading();
                Utils.showAlertDialog(ForgotPasswordActivity.this, getString(R.string.dialog_title_password_changed), "", true);
            }

            @Override
            public void onResponseFailure(Exception exception) {
                hideLoading();
                if (exception instanceof CloudException) {
                    Utils.showAlertDialog(ForgotPasswordActivity.this, getString(R.string.dialog_title_forgot_password_failed), exception.getMessage(), false);
                } else {
                    Utils.showAlertDialog(ForgotPasswordActivity.this, "", getString(R.string.dialog_title_forgot_password_failed), false);
                }
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                hideLoading();
                Utils.showAlertDialog(ForgotPasswordActivity.this, getString(R.string.dialog_title_no_network), getString(R.string.dialog_msg_no_network), false);
            }
        });
    }

    private void getForgotPasswordCode(String email) {
        Fragment resetPasswordFragment = new ResetPasswordFragment();
        Bundle data = new Bundle();
        data.putString(AppConstants.KEY_USER_NAME, email);
        resetPasswordFragment.setArguments(data);
        loadResetPasswordFragment(resetPasswordFragment);
    }

    private void hideLoading() {

        Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container);

        if (currentFragment instanceof ForgotPasswordFragment) {

            ((ForgotPasswordFragment) currentFragment).hideLoading();

        } else if (currentFragment instanceof ResetPasswordFragment) {

            ((ResetPasswordFragment) currentFragment).hideLoading();
        }
    }
}
