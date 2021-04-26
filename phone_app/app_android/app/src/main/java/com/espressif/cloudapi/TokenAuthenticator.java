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

package com.espressif.cloudapi;

import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.util.Log;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.ui.activities.MainActivity;

import okhttp3.Authenticator;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.Route;

public class TokenAuthenticator implements Authenticator {

    private static final String TAG = TokenAuthenticator.class.getSimpleName();

    private Context context;

    TokenAuthenticator(Context context) {
        this.context = context;
    }

    @Override
    public Request authenticate(Route route, Response response) {

        Log.d(TAG, "=============== Authenticate callback ===============");
        Log.d(TAG, "Response code : " + response.code());
        String newToken = ApiManager.getInstance(context).getNewToken();

        if (!TextUtils.isEmpty(newToken)) {
            Log.d(TAG, "Retrying with new token");
            // Add new header to rejected request and retry it
            return response.request().newBuilder()
                    .header(AppConstants.HEADER_AUTHORIZATION, newToken)
                    .build();
        } else {
            doLogout();
            return null;
        }
    }

    private void doLogout() {
        Log.d(TAG, "Logout and display Login screen");
        ((EspApplication) context).logout();
    }
}