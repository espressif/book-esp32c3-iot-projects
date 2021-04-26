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

package com.espressif;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import androidx.core.app.NotificationManagerCompat;

import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;

public class NodeSharingActionReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        String reqId = intent.getStringExtra(AppConstants.KEY_REQ_ID);
        boolean reqAccepted = true;
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
        notificationManager.cancel(intent.getIntExtra(AppConstants.KEY_ID, -1));

        if (action.equals(AppConstants.ACTION_DECLINE)) {
            reqAccepted = false;
        }

        ApiManager.getInstance(context).updateSharingRequest(reqId, reqAccepted, new ApiResponseListener() {

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
