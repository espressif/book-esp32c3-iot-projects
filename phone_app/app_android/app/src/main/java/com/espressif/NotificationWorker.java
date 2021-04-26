package com.espressif;

import android.app.Notification;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.work.Data;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.db.EspDatabase;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.NotificationsActivity;
import com.espressif.ui.activities.SplashActivity;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Group;
import com.espressif.ui.models.NotificationEvent;
import com.espressif.ui.models.Param;
import com.espressif.ui.models.UpdateEvent;

import org.greenrobot.eventbus.EventBus;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

public class NotificationWorker extends Worker {

    private static final String TAG = NotificationWorker.class.getSimpleName();

    private EspApplication espApp;
    private static int notificationId = 0;

    public NotificationWorker(@NonNull Context context, @NonNull WorkerParameters workerParams) {
        super(context, workerParams);
        espApp = (EspApplication) getApplicationContext();
    }

    @NonNull
    @Override
    public Result doWork() {

        Log.d(TAG, "Do Notification Work");
        Data data = getInputData();
        String title = data.getString(AppConstants.KEY_TITLE);
        String eventPayload = data.getString(AppConstants.KEY_EVENT_DATA_PAYLOAD);

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

            if (!TextUtils.isEmpty(eventType)) {

                if (jsonEventData != null) {

                    if (AppConstants.EVENT_NODE_CONNECTED.equals(eventType)
                            || AppConstants.EVENT_NODE_DISCONNECTED.equals(eventType)) {

                        processConnectivityEvent(title, notificationEvent, jsonEventData);

                    } else if (AppConstants.EVENT_NODE_ADDED.equals(eventType)) {

                        processNodeAddedEvent(title, notificationEvent, jsonEventData);

                    } else if (AppConstants.EVENT_NODE_REMOVED.equals(eventType)) {

                        processNodeRemovedEvent(title, notificationEvent, jsonEventData);

                    } else if (AppConstants.EVENT_NODE_SHARING_ADD.equals(eventType)) {

                        processSharingAddEvent(title, notificationEvent, jsonEventData);

                    } else if (AppConstants.EVENT_NODE_PARAM_MODIFIED.equals(eventType)) {

                        String nodeId = jsonEventData.optString(AppConstants.KEY_NODE_ID);
                        String payload = jsonEventData.optString(AppConstants.KEY_PAYLOAD);
                        Log.d(TAG, "Node Id : " + nodeId);
                        Log.d(TAG, "Payload : " + payload);
                        JSONObject payloadJson = null;
                        try {
                            payloadJson = new JSONObject(payload);
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }

                        if (!espApp.nodeMap.containsKey(nodeId)) {
                            ApiManager.getInstance(espApp).getNodeDetails(nodeId);
                        }

                        if (!espApp.nodeMap.containsKey(nodeId)) {
                            loadDataFromLocalStorage();
                        }

                        if (payloadJson != null && espApp.nodeMap.containsKey(nodeId)) {
                            EspNode node = espApp.nodeMap.get(nodeId);
                            JsonDataParser.setAllParams(espApp, node, payloadJson);
                            // Send event for UI update
                            EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));
                        }
                    } else if (AppConstants.EVENT_ALERT.equals(eventType)) {
                        processAlertEvent(title, notificationEvent, jsonEventData);
                    } else {
                        sendNotification(title, notificationEvent.getEventDescription(), AppConstants.CHANNEL_ALERT);
                    }
                }
            }

        } catch (JSONException e) {
            e.printStackTrace();
        }


        return Result.success();
    }

    // Event type - Node connected / disconnected

    private void processConnectivityEvent(String title, NotificationEvent notificationEvent, JSONObject jsonEventData) {

        EspApplication espApp = (EspApplication) getApplicationContext();
        JSONObject connectivityJson = jsonEventData.optJSONObject(AppConstants.KEY_CONNECTIVITY);
        String nodeId = jsonEventData.optString(AppConstants.KEY_NODE_ID);
        Log.d(TAG, "Node Id : " + nodeId);
        StringBuilder msgBuilder = new StringBuilder();

        if (connectivityJson != null) {

            boolean nodeStatus = connectivityJson.optBoolean(AppConstants.KEY_CONNECTED);
            long timestamp = connectivityJson.optLong(AppConstants.KEY_TIMESTAMP);

            if (!espApp.nodeMap.containsKey(nodeId)) {
                ApiManager.getInstance(espApp).getNodeDetails(nodeId);
            }

            if (!espApp.nodeMap.containsKey(nodeId)) {
                loadDataFromLocalStorage();
            }

            if (espApp.nodeMap.containsKey(nodeId)) {

                EspNode node = espApp.nodeMap.get(nodeId);
                node.setTimeStampOfStatus(timestamp);
                node.setOnline(nodeStatus);
                ArrayList<Device> devices = node.getDevices();
                ArrayList<String> deviceNames = new ArrayList<>();
                if (devices != null) {
                    for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {
                        deviceNames.add(devices.get(deviceIndex).getUserVisibleName());
                    }
                }

                if (deviceNames.size() > 0) {

                    if (deviceNames.size() == 1) {
                        msgBuilder.append(deviceNames.get(0));
                        if (AppConstants.EVENT_NODE_CONNECTED.equals(notificationEvent.getEventType())) {
                            msgBuilder.append(" is now online.");
                        } else {
                            msgBuilder.append(" is now offline.");
                        }
                    } else {
                        for (int i = 0; i < deviceNames.size(); i++) {

                            if (i != 0) {
                                msgBuilder.append(",");
                                msgBuilder.append(" ");
                            }
                            msgBuilder.append(deviceNames.get(i));
                        }

                        if (AppConstants.EVENT_NODE_CONNECTED.equals(notificationEvent.getEventType())) {
                            msgBuilder.append(" are now online.");
                        } else {
                            msgBuilder.append(" are now offline.");
                        }
                    }
                }
            } else {
                Log.e(TAG, "Node id is not available for this event.");
            }
        } else {
            Log.e(TAG, "Connectivity object is null");
        }

        if (TextUtils.isEmpty(msgBuilder.toString())) {
            if (AppConstants.EVENT_NODE_CONNECTED.equals(notificationEvent.getEventType())) {
                msgBuilder.append(espApp.getString(R.string.notify_node_connected));
            } else {
                msgBuilder.append(espApp.getString(R.string.notify_node_disconnected));
            }
        }
        notificationEvent.setNotificationMsg(msgBuilder.toString());
        EspDatabase.getInstance(espApp).getNotificationDao().insertOrUpdate(notificationEvent);
        Log.d(TAG, "Connectivity Notification inserted in database");

        if (AppConstants.EVENT_NODE_CONNECTED.equals(notificationEvent.getEventType())) {
            sendNotification(title, msgBuilder.toString(), AppConstants.CHANNEL_NODE_ONLINE_ID);
            EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_ONLINE));
        } else {
            sendNotification(title, msgBuilder.toString(), AppConstants.CHANNEL_NODE_OFFLINE_ID);
            EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_OFFLINE));
        }
    }

    // Event type - Node added

    private void processNodeAddedEvent(String title, NotificationEvent notificationEvent, JSONObject jsonEventData) {

        EspApplication espApp = (EspApplication) getApplicationContext();
        StringBuilder msgBuilder = new StringBuilder();
        // If it is more than one node then called API to get all nodes instead of getting specific nodes.
        JSONArray nodeJsonArray = jsonEventData.optJSONArray(AppConstants.KEY_NODES);
        if (nodeJsonArray != null && nodeJsonArray.length() > 0) {

            if (nodeJsonArray.length() == 1) {

                String nodeId = nodeJsonArray.optString(0);
                ApiManager.getInstance(espApp).getNodeDetails(nodeId);

                if (!espApp.nodeMap.containsKey(nodeId)) {
                    loadDataFromLocalStorage();
                }

                if (espApp.nodeMap.containsKey(nodeId)) {
                    ArrayList<String> deviceNames = new ArrayList<>();
                    ArrayList<Device> devices = espApp.nodeMap.get(nodeId).getDevices();
                    if (devices != null) {
                        for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {
                            deviceNames.add(devices.get(deviceIndex).getUserVisibleName());
                        }
                    }

                    if (deviceNames.size() > 0) {

                        if (deviceNames.size() == 1) {
                            msgBuilder.append(deviceNames.get(0));
                            msgBuilder.append(" is added.");
                        } else {
                            for (int i = 0; i < deviceNames.size(); i++) {

                                if (i != 0) {
                                    msgBuilder.append(",");
                                    msgBuilder.append(" ");
                                }
                                msgBuilder.append(deviceNames.get(i));
                            }
                            msgBuilder.append(" are added.");
                        }
                    }
                }

                if (TextUtils.isEmpty(msgBuilder.toString())) {
                    msgBuilder.append(espApp.getString(R.string.notify_node_added));
                }

                notificationEvent.setNotificationMsg(msgBuilder.toString());
                EspDatabase.getInstance(espApp).getNotificationDao().insertOrUpdate(notificationEvent);
                Log.d(TAG, "Node added Notification inserted in database");
                sendNotification(title, msgBuilder.toString(), AppConstants.CHANNEL_NODE_ADDED);
                EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));

            } else {
                ApiManager.getInstance(espApp).getNodes(new ApiResponseListener() {
                    @Override
                    public void onSuccess(Bundle data) {
                        ArrayList<String> deviceNames = new ArrayList<>();
                        for (int nodeIndex = 0; nodeIndex < nodeJsonArray.length(); nodeIndex++) {
                            String nodeId = nodeJsonArray.optString(nodeIndex);
                            if (espApp.nodeMap.containsKey(nodeId)) {
                                ArrayList<Device> devices = espApp.nodeMap.get(nodeId).getDevices();
                                if (devices != null) {
                                    for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {
                                        deviceNames.add(devices.get(deviceIndex).getUserVisibleName());
                                    }
                                }
                            }
                        }

                        if (deviceNames.size() > 0) {

                            if (deviceNames.size() == 1) {
                                msgBuilder.append(deviceNames.get(0));
                                msgBuilder.append(" is added.");
                            } else {
                                for (int i = 0; i < deviceNames.size(); i++) {

                                    if (i != 0) {
                                        msgBuilder.append(",");
                                        msgBuilder.append(" ");
                                    }
                                    msgBuilder.append(deviceNames.get(i));
                                }
                                msgBuilder.append(" are added.");
                            }
                        }

                        if (TextUtils.isEmpty(msgBuilder.toString())) {
                            msgBuilder.append(espApp.getString(R.string.notify_node_added));
                        }
                        EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));
                    }

                    @Override
                    public void onResponseFailure(Exception exception) {
                        msgBuilder.append(espApp.getString(R.string.notify_node_added));
                        notificationEvent.setNotificationMsg(msgBuilder.toString());
                        EspDatabase.getInstance(espApp).getNotificationDao().insertOrUpdate(notificationEvent);
                        Log.d(TAG, "Node added Notification inserted in database");
                        sendNotification(title, msgBuilder.toString(), AppConstants.CHANNEL_NODE_ADDED);
                        EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));
                    }

                    @Override
                    public void onNetworkFailure(Exception exception) {
                        msgBuilder.append(espApp.getString(R.string.notify_node_added));
                        notificationEvent.setNotificationMsg(msgBuilder.toString());
                        EspDatabase.getInstance(espApp).getNotificationDao().insertOrUpdate(notificationEvent);
                        Log.d(TAG, "Node added Notification inserted in database");
                        sendNotification(title, msgBuilder.toString(), AppConstants.CHANNEL_NODE_ADDED);
                        EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));
                    }
                });
            }
        }


    }

    // Event type - Node removed

    private void processNodeRemovedEvent(String title, NotificationEvent notificationEvent, JSONObject jsonEventData) {

        EspApplication espApp = (EspApplication) getApplicationContext();
        JSONArray nodeJsonArray = jsonEventData.optJSONArray(AppConstants.KEY_NODES);
        StringBuilder msgBuilder = new StringBuilder();
        ArrayList<String> deviceNames = new ArrayList<>();

        if (nodeJsonArray != null && nodeJsonArray.length() > 0) {

            for (int nodeIndex = 0; nodeIndex < nodeJsonArray.length(); nodeIndex++) {
                String nodeId = nodeJsonArray.optString(nodeIndex);
                if (espApp.nodeMap.get(nodeId) != null) {
                    ArrayList<Device> devices = espApp.nodeMap.get(nodeId).getDevices();
                    if (devices != null) {
                        for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {
                            deviceNames.add(devices.get(deviceIndex).getUserVisibleName());
                        }
                    }
                }
                espApp.removeNodeInformation(nodeId);
            }
        }

        if (deviceNames.size() > 0) {

            if (deviceNames.size() == 1) {
                msgBuilder.append(deviceNames.get(0));
                msgBuilder.append(" is removed.");
            } else {
                for (int i = 0; i < deviceNames.size(); i++) {

                    if (i != 0) {
                        msgBuilder.append(",");
                        msgBuilder.append(" ");
                    }
                    msgBuilder.append(deviceNames.get(i));
                }
                msgBuilder.append(" are removed.");
            }
        }

        if (TextUtils.isEmpty(msgBuilder.toString())) {
            msgBuilder.append(espApp.getString(R.string.notify_node_removed));
        }
        notificationEvent.setNotificationMsg(msgBuilder.toString());
        EspDatabase.getInstance(espApp).getNotificationDao().insertOrUpdate(notificationEvent);
        Log.d(TAG, "Node removed Notification inserted in database");
        sendNotification(title, msgBuilder.toString(), AppConstants.CHANNEL_NODE_REMOVED);
        EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));
    }

    // Event type - Node sharing add

    private void processSharingAddEvent(String title, NotificationEvent notificationEvent, JSONObject jsonEventData) {

        EspApplication espApp = (EspApplication) getApplicationContext();
        String primaryUserName = jsonEventData.optString(AppConstants.KEY_PRIMARY_USER_NAME);
        String secondaryUserName = jsonEventData.optString(AppConstants.KEY_SECONDARY_USER_NAME);
        String requestId = jsonEventData.optString(AppConstants.KEY_REQ_ID);
        boolean accepted = jsonEventData.optBoolean(AppConstants.KEY_REQ_ACCEPT);
        JSONObject metadataJson = jsonEventData.optJSONObject(AppConstants.KEY_METADATA);
        StringBuilder msgBuilder = new StringBuilder();

        if (!jsonEventData.has(AppConstants.KEY_REQ_ACCEPT)) {

            if (!TextUtils.isEmpty(primaryUserName) && !TextUtils.isEmpty(requestId)) {

                msgBuilder.append(primaryUserName);
                msgBuilder.append(" wants to share ");

                if (metadataJson != null) {

                    ArrayList<String> deviceNames = new ArrayList<>();
                    JSONArray deviceJsonArray = metadataJson.optJSONArray(AppConstants.KEY_DEVICES);

                    if (deviceJsonArray != null) {

                        for (int i = 0; i < deviceJsonArray.length(); i++) {
                            JSONObject deviceObj = deviceJsonArray.optJSONObject(i);
                            if (deviceObj != null) {
                                String deviceName = deviceObj.optString(AppConstants.KEY_NAME);
                                if (!TextUtils.isEmpty(deviceName)) {
                                    deviceNames.add(deviceName);
                                }
                            }
                        }

                        if (deviceNames.size() > 0) {

                            if (deviceNames.size() == 1) {
                                msgBuilder.append("device ");
                            } else {
                                msgBuilder.append("devices ");
                            }

                            msgBuilder.append("(");

                            for (int i = 0; i < deviceNames.size(); i++) {

                                if (i != 0) {
                                    msgBuilder.append(",");
                                    msgBuilder.append(" ");
                                }
                                msgBuilder.append(deviceNames.get(i));
                            }
                            msgBuilder.append(")");
                        } else {
                            msgBuilder.append("device(s)");
                        }
                        msgBuilder.append(" with you.");

                    } else {
                        msgBuilder.append("device(s)");
                        msgBuilder.append(" with you.");
                    }
                } else {
                    msgBuilder.append("device(s)");
                    msgBuilder.append(" with you.");
                }
                msgBuilder.append(" ");
                msgBuilder.append("Tap to accept or decline.");

                Log.d(TAG, "Notification msg string  : " + msgBuilder.toString());
                sendSharingRequestNotification(title, msgBuilder.toString(), requestId);
            }

        } else {

            // Comment details case
            Log.d(TAG, "Secondary User : " + secondaryUserName);
            JSONArray nodeJsonArray = jsonEventData.optJSONArray(AppConstants.KEY_NODES);
            ArrayList<String> deviceNames = new ArrayList<>();
            loadDataFromLocalStorage();

            if (nodeJsonArray != null && nodeJsonArray.length() > 0) {
                for (int nodeIndex = 0; nodeIndex < nodeJsonArray.length(); nodeIndex++) {
                    String nodeId = nodeJsonArray.optString(nodeIndex);
                    Log.d(TAG, "Node Id : " + nodeId);
                    if (espApp.nodeMap.containsKey(nodeId)) {
                        ArrayList<Device> devices = espApp.nodeMap.get(nodeId).getDevices();
                        if (devices != null) {
                            for (int deviceIndex = 0; deviceIndex < devices.size(); deviceIndex++) {
                                String deviceName = devices.get(deviceIndex).getUserVisibleName();
                                if (!TextUtils.isEmpty(deviceName)) {
                                    deviceNames.add(deviceName);
                                }
                            }
                        }
                    }
                }
            }

            if (!TextUtils.isEmpty(secondaryUserName)) {

                msgBuilder.append(secondaryUserName);
                if (accepted) {
                    msgBuilder.append(" accepted sharing request for ");
                } else {
                    msgBuilder.append(" declined sharing request for ");
                }

                if (deviceNames.size() > 0) {

                    if (deviceNames.size() == 1) {
                        msgBuilder.append("device ");
                    } else {
                        msgBuilder.append("devices ");
                    }
                    msgBuilder.append("(");

                    for (int i = 0; i < deviceNames.size(); i++) {

                        if (i != 0) {
                            msgBuilder.append(",");
                            msgBuilder.append(" ");
                        }
                        msgBuilder.append(deviceNames.get(i));
                    }
                    msgBuilder.append(").");
                } else {
                    msgBuilder.append("device(s)");
                }
            }

            Log.d(TAG, "Notification msg string  : " + msgBuilder.toString());
            notificationEvent.setNotificationMsg(msgBuilder.toString());
            EspDatabase.getInstance(espApp).getNotificationDao().insertOrUpdate(notificationEvent);
            Log.d(TAG, "Node sharing add Notification inserted in database");
            sendSharingNotificationForPrimaryUser(title, msgBuilder.toString());
        }
    }

    private void sendSharingNotificationForPrimaryUser(String title, String messageBody) {

        Intent activityIntent = new Intent(espApp, NotificationsActivity.class);
        activityIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent contentIntent = PendingIntent.getActivity(espApp,
                0 /* Request code */,
                activityIntent,
                PendingIntent.FLAG_UPDATE_CURRENT);

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(getApplicationContext());
        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

        Notification notification = new NotificationCompat.Builder(espApp, AppConstants.CHANNEL_NODE_SHARING)
                .setSmallIcon(R.drawable.ic_notify_rainmaker)
                .setColor(espApp.getColor(R.color.color_esp_logo))
                .setContentTitle(title)
                .setContentText(messageBody)
                .setStyle(new NotificationCompat.BigTextStyle()
                        .bigText(messageBody))
                .setContentIntent(contentIntent)
                .setSound(defaultSoundUri)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build();

        notificationManager.notify(notificationId++, notification);
    }

    private void sendSharingRequestNotification(String title, String contentText, String reqId) {

        Log.d(TAG, "Display sharing notification with request id : " + reqId);
        Intent intent = new Intent(espApp, NotificationsActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent contentIntent = PendingIntent.getActivity(espApp, 0 /* Request code */, intent,
                PendingIntent.FLAG_ONE_SHOT);
        int id = notificationId++;

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(getApplicationContext());
        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(espApp, AppConstants.CHANNEL_NODE_SHARING)
                .setSmallIcon(R.drawable.ic_notify_rainmaker)
                .setColor(espApp.getColor(R.color.color_esp_logo))
                .setContentTitle(title)
                .setContentText(contentText)
                .setStyle(new NotificationCompat.BigTextStyle()
                        .bigText(contentText))
                .setAutoCancel(true)
                .setSound(defaultSoundUri)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(contentIntent);

//        Intent acceptIntent = new Intent(espApp, EspBroadcastReceiver.class);
//        acceptIntent.setAction(AppConstants.ACTION_ACCEPT);
//        acceptIntent.putExtra(AppConstants.KEY_REQ_ID, reqId);
//        acceptIntent.putExtra(AppConstants.KEY_ID, id);
//        PendingIntent acceptPendingIntent =
//                PendingIntent.getBroadcast(espApp, notificationId++, acceptIntent, PendingIntent.FLAG_ONE_SHOT);

        Intent acceptIntent = new Intent(espApp, SplashActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP
                | Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
        acceptIntent.putExtra(AppConstants.KEY_REQ_ID, reqId);
        acceptIntent.putExtra(AppConstants.KEY_ID, id);
        PendingIntent acceptPendingIntent = PendingIntent.getActivity(espApp, notificationId++ /* Request code */,
                acceptIntent, PendingIntent.FLAG_ONE_SHOT);

        Intent declineIntent = new Intent(espApp, NodeSharingActionReceiver.class);
        declineIntent.setAction(AppConstants.ACTION_DECLINE);
        declineIntent.putExtra(AppConstants.KEY_REQ_ID, reqId);
        declineIntent.putExtra(AppConstants.KEY_ID, id);
        PendingIntent declinePendingIntent =
                PendingIntent.getBroadcast(espApp, notificationId++, declineIntent, PendingIntent.FLAG_ONE_SHOT);

        notificationBuilder.addAction(R.drawable.ic_notify_accept, espApp.getString(R.string.btn_accept), acceptPendingIntent);
        notificationBuilder.addAction(R.drawable.ic_notify_decline, espApp.getString(R.string.btn_deny), declinePendingIntent);

        notificationManager.notify(id, notificationBuilder.build());
    }

    // Event type - Alert

    private void processAlertEvent(String title, NotificationEvent notificationEvent, JSONObject jsonEventData) {

        EspApplication espApp = (EspApplication) getApplicationContext();
        String nodeId = jsonEventData.optString(AppConstants.KEY_NODE_ID);
        String msgBody = jsonEventData.optString(AppConstants.KEY_MESSAGE_BODY);
        Log.d(TAG, "Node Id : " + nodeId);
        Log.d(TAG, "Message body : " + msgBody);
        StringBuilder msgBuilder = new StringBuilder();
        JSONObject payloadJson = null;

        try {
            payloadJson = new JSONObject(msgBody);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        if (payloadJson != null) {
            String alertStr = payloadJson.optString(AppConstants.KEY_ALERT_STRING);
            Log.e(TAG, "Alert string : " + alertStr);
            if (TextUtils.isEmpty(alertStr)) {

                if (!espApp.nodeMap.containsKey(nodeId)) {
                    ApiManager.getInstance(espApp).getNodeDetails(nodeId);
                }

                if (!espApp.nodeMap.containsKey(nodeId)) {
                    loadDataFromLocalStorage();
                }

                if (espApp.nodeMap.containsKey(nodeId)) {
                    EspNode node = espApp.nodeMap.get(nodeId);
                    JsonDataParser.setAllParams(espApp, node, payloadJson);
                    ArrayList<Device> devices = node.getDevices();

                    if (devices != null) {
                        for (int i = 0; i < devices.size(); i++) {

                            ArrayList<Param> params = devices.get(i).getParams();
                            String deviceName = devices.get(i).getDeviceName();
                            JSONObject deviceJson = payloadJson.optJSONObject(deviceName);

                            if (deviceJson != null) {

                                msgBuilder.append(devices.get(i).getUserVisibleName());
                                msgBuilder.append(" ");
                                msgBuilder.append("reported");
                                msgBuilder.append(" ");

                                for (int j = 0; j < params.size(); j++) {

                                    Param param = params.get(j);
                                    String key = param.getName();

                                    if (!param.isDynamicParam()) {
                                        continue;
                                    }

                                    if (deviceJson.has(key)) {
                                        msgBuilder.append(key);
                                        msgBuilder.append(" : ");
                                        String dataType = param.getDataType();

                                        if (dataType.equalsIgnoreCase("bool") || dataType.equalsIgnoreCase("boolean")) {
                                            boolean value = deviceJson.optBoolean(key);
                                            msgBuilder.append("" + value);
                                        } else if (dataType.equalsIgnoreCase("int") || dataType.equalsIgnoreCase("integer")) {
                                            int value = deviceJson.optInt(key);
                                            msgBuilder.append("" + value);
                                        } else if (dataType.equalsIgnoreCase("float") || dataType.equalsIgnoreCase("double")) {
                                            double value = deviceJson.optDouble(key);
                                            msgBuilder.append("" + value);
                                        }
                                    }
                                }
                            } else {
                                Log.e(TAG, "Device JSON is not available");
                                msgBuilder.append(espApp.getString(R.string.notify_node_alert));
                            }
                        }
                    } else {
                        msgBuilder.append(espApp.getString(R.string.notify_node_alert));
                    }
                } else {
                    msgBuilder.append(espApp.getString(R.string.notify_node_alert));
                }
            } else {
                msgBuilder.append(alertStr);
            }
        } else {
            msgBuilder.append(espApp.getString(R.string.notify_node_alert));
        }

        notificationEvent.setNotificationMsg(msgBuilder.toString());
        EspDatabase.getInstance(espApp).getNotificationDao().insertOrUpdate(notificationEvent);
        Log.d(TAG, "Alert Notification inserted in database");
        sendAlertNotification(title, msgBuilder.toString(), AppConstants.CHANNEL_ALERT);
        // Send event for UI update
        EventBus.getDefault().post(new UpdateEvent(AppConstants.UpdateEventType.EVENT_DEVICE_STATUS_UPDATE));
    }

    private void sendAlertNotification(String title, String messageBody, String channelId) {

        Intent activityIntent = new Intent(espApp, NotificationsActivity.class);
        activityIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        PendingIntent contentIntent = PendingIntent.getActivity(espApp,
                0 /* Request code */,
                activityIntent,
                PendingIntent.FLAG_UPDATE_CURRENT);

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(getApplicationContext());
        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

        Notification notification = new NotificationCompat.Builder(espApp, channelId)
                .setSmallIcon(R.drawable.ic_notify_rainmaker)
                .setColor(espApp.getColor(R.color.color_esp_logo))
                .setContentTitle(title)
                .setContentText(messageBody)
                .setStyle(new NotificationCompat.BigTextStyle()
                        .bigText(messageBody))
                .setContentIntent(contentIntent)
                .setAutoCancel(true)
                .setSound(defaultSoundUri)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .build();

        notificationManager.notify(notificationId++, notification);
    }

    private void sendNotification(String title, String messageBody, String channelId) {

        Log.e(TAG, "Message : " + messageBody);
        Intent activityIntent = new Intent(espApp, SplashActivity.class);
        activityIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent contentIntent = PendingIntent.getActivity(espApp,
                0 /* Request code */,
                activityIntent,
                PendingIntent.FLAG_UPDATE_CURRENT);

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(getApplicationContext());
        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

        Notification notification = new NotificationCompat.Builder(espApp, channelId)
                .setSmallIcon(R.drawable.ic_notify_rainmaker)
                .setColor(espApp.getColor(R.color.color_esp_logo))
                .setContentTitle(title)
                .setContentText(messageBody)
                .setStyle(new NotificationCompat.BigTextStyle()
                        .bigText(messageBody))
                .setContentIntent(contentIntent)
                .setShowWhen(true)
                .setAutoCancel(true)
                .setSound(defaultSoundUri)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .build();

        notificationManager.notify(notificationId++, notification);
    }

    private void loadDataFromLocalStorage() {

        EspDatabase espDatabase = EspDatabase.getInstance(getApplicationContext());
        ArrayList<EspNode> nodeList = (ArrayList<EspNode>) espDatabase.getNodeDao().getNodesFromStorage();

        for (int nodeIndex = 0; nodeIndex < nodeList.size(); nodeIndex++) {

            EspNode node = nodeList.get(nodeIndex);

            if (node != null) {

                String configData = node.getConfigData();
                String paramData = node.getParamData();

                if (configData != null) {
                    try {
                        node = JsonDataParser.setNodeConfig(node, new JSONObject(configData));
                        if (paramData != null) {
                            JSONObject paramsJson = new JSONObject(paramData);
                            JsonDataParser.setAllParams(espApp, node, paramsJson);
                        } else {
                            Log.e(TAG, "Param configuration is not available.");
                        }
                        espApp.nodeMap.put(node.getNodeId(), node);

                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } else {
                    Log.e(TAG, "Node configuration is not available.");
                }
            }
        }

        if (BuildConfig.isNodeGroupingSupported) {
            ArrayList<Group> groupList = (ArrayList<Group>) espDatabase.getGroupDao().getGroupsFromStorage();
            for (int groupIndex = 0; groupIndex < groupList.size(); groupIndex++) {

                Group group = groupList.get(groupIndex);
                if (group != null) {
                    espApp.groupMap.put(group.getGroupId(), group);
                }
            }
        }
        Log.d(TAG, "Node list size from local storage : " + espApp.nodeMap.size());
    }
}
