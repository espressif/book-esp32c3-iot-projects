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

import android.util.Log;

import androidx.work.Data;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkManager;

import com.espressif.ui.models.NotificationEvent;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

public class EspFcmService extends FirebaseMessagingService {

    private final String TAG = EspFcmService.class.getSimpleName();

    @Override
    public void onNewToken(String token) {
        Log.d(TAG, "Refreshed token: " + token);
        // If you want to send messages to this application instance or manage this apps subscriptions on the server side, send the
        // FCM registration token to your app server.
//        sendRegistrationToServer(token);
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {

        Log.e(TAG, "========================================== onMessageReceived ==========================================");
        Map<String, String> msgData = remoteMessage.getData();
        String title = msgData.get(AppConstants.KEY_TITLE);
        String body = msgData.get(AppConstants.KEY_BODY);
        String eventPayload = msgData.get(AppConstants.KEY_EVENT_DATA_PAYLOAD);

        Log.e(TAG, "Title : " + title);
        Log.e(TAG, "Body : " + body);
        Log.e(TAG, "Event payload : " + eventPayload);
        Log.e(TAG, "remoteMessage : " + remoteMessage.getData().toString());

        if (eventPayload != null) {

            try {
                JSONObject eventDataJson = new JSONObject(eventPayload);
                String eventType = eventDataJson.optString(AppConstants.KEY_EVENT_TYPE);
                JSONObject jsonEventData = eventDataJson.optJSONObject(AppConstants.KEY_EVENT_DATA);
                NotificationEvent notificationEvent = new NotificationEvent();
                notificationEvent.setEventType(eventType);
                notificationEvent.setEventVersion(eventDataJson.optString(AppConstants.KEY_EVENT_VERSION));
                notificationEvent.setEventId(eventDataJson.optString(AppConstants.KEY_ID));
                notificationEvent.setEventData(jsonEventData.toString());
                notificationEvent.setEventDescription(eventDataJson.optString(AppConstants.KEY_DESCRIPTION));
                notificationEvent.setTimestamp(eventDataJson.optLong(AppConstants.KEY_TIMESTAMP));
                Log.e(TAG, "Event type : " + eventType);
                Data data = new Data.Builder()
                        .putString(AppConstants.KEY_TITLE, title)
                        .putString(AppConstants.KEY_EVENT_DATA_PAYLOAD, eventPayload)
                        .build();
                OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(NotificationWorker.class)
                        .setInputData(data)
                        .build();
                WorkManager.getInstance().enqueue(workRequest);

            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }
}
