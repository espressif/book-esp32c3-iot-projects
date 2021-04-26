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
import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.viewpager.widget.ViewPager;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.rainmaker.R;
import com.espressif.ui.Utils;
import com.espressif.ui.adapters.TabsPagerAdapter;
import com.espressif.ui.fragments.LoginFragment;
import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.tabs.TabLayout;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = MainActivity.class.getSimpleName();

    public static final int SIGN_UP_CONFIRM_ACTIVITY_REQUEST = 10;

    private ViewPager viewPager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        toolbar.setTitle("");
        setSupportActionBar(toolbar);

        TabsPagerAdapter tabsPagerAdapter = new TabsPagerAdapter(this, getSupportFragmentManager());

        viewPager = findViewById(R.id.view_pager);
        viewPager.setAdapter(tabsPagerAdapter);

        TabLayout tabs = findViewById(R.id.tabs);
        tabs.setupWithViewPager(viewPager);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {

        Log.d(TAG, "On activity result");

        if (requestCode == SIGN_UP_CONFIRM_ACTIVITY_REQUEST) {

            if (resultCode == RESULT_OK) {

                String userName = data.getStringExtra(AppConstants.KEY_USER_NAME);
                String password = data.getStringExtra(AppConstants.KEY_PASSWORD);
                viewPager.setCurrentItem(0);
                Fragment page = getSupportFragmentManager().findFragmentByTag("android:switcher:" + R.id.view_pager + ":" + viewPager.getCurrentItem());
                if (page != null && page instanceof LoginFragment) {
                    ((LoginFragment) page).doLoginWithNewUser(userName, password);
                }
            }
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    public void launchHomeScreen() {
        ((EspApplication) getApplicationContext()).changeAppState(EspApplication.AppState.GETTING_DATA, null);
        Intent espMainActivity = new Intent(getApplicationContext(), EspMainActivity.class);
        espMainActivity.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(espMainActivity);
        finish();
    }

    public void signInUser(final String email, String password) {

        showLoginLoading();
        ApiManager apiManager = ApiManager.getInstance(getApplicationContext());
        apiManager.login(email, password, new ApiResponseListener() {
            @Override
            public void onSuccess(Bundle data) {
                hideLoginLoading();
                launchHomeScreen();
            }

            @Override
            public void onResponseFailure(Exception exception) {
                hideLoginLoading();
                if (exception instanceof CloudException) {
                    Utils.showAlertDialog(MainActivity.this, getString(R.string.dialog_title_login_failed), exception.getMessage(), false);
                } else {
                    Utils.showAlertDialog(MainActivity.this, "", getString(R.string.dialog_title_login_failed), false);
                }
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                hideLoginLoading();
                Utils.showAlertDialog(MainActivity.this, getString(R.string.dialog_title_no_network), getString(R.string.dialog_msg_no_network), false);
            }
        });
    }

    private void showLoginLoading() {
        Fragment page = getSupportFragmentManager().findFragmentByTag("android:switcher:" + R.id.view_pager + ":" + viewPager.getCurrentItem());
        if (page != null && page instanceof LoginFragment) {
            ((LoginFragment) page).showLoginLoading();
        }
    }

    private void hideLoginLoading() {
        Fragment page = getSupportFragmentManager().findFragmentByTag("android:switcher:" + R.id.view_pager + ":" + viewPager.getCurrentItem());
        if (page != null && page instanceof LoginFragment) {
            ((LoginFragment) page).hideLoginLoading();
        }
    }
}
