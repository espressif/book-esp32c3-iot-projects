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

import android.text.TextUtils;
import android.util.Log;

import com.espressif.ui.models.Action;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Param;
import com.espressif.ui.models.Scene;
import com.espressif.ui.models.Schedule;
import com.espressif.ui.models.Service;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

public class JsonDataParser {

    private static final String TAG = JsonDataParser.class.getSimpleName();

    /**
     * This method is used to set param value received from cloud.
     *
     * @param deviceJson JSON data of device params.
     * @param device     Device object.
     * @param param      Param object in which values to be set.
     */
    public static void setDeviceParamValue(JSONObject deviceJson, Device device, Param param) {

        String dataType = param.getDataType();
        String paramName = param.getName();

        if (AppConstants.UI_TYPE_SLIDER.equalsIgnoreCase(param.getUiType()) || AppConstants.UI_TYPE_HUE_SLIDER.equalsIgnoreCase(param.getUiType())) {

            String labelValue = "";

            if (dataType.equalsIgnoreCase("int") || dataType.equalsIgnoreCase("integer")) {

                int value = deviceJson.optInt(paramName);
                labelValue = String.valueOf(value);
                param.setLabelValue(labelValue);
                param.setValue(value);

            } else if (dataType.equalsIgnoreCase("float") || dataType.equalsIgnoreCase("double")) {

                double value = deviceJson.optDouble(paramName);
                labelValue = String.valueOf(value);
                param.setLabelValue(labelValue);
                param.setValue(value);

            } else {

                labelValue = deviceJson.optString(paramName);
                param.setLabelValue(labelValue);
            }
        } else if (AppConstants.UI_TYPE_TOGGLE.equalsIgnoreCase(param.getUiType())) {

            boolean value = deviceJson.optBoolean(paramName);
            param.setSwitchStatus(value);

        } else if (AppConstants.UI_TYPE_TRIGGER.equalsIgnoreCase(param.getUiType())) {

            boolean value = deviceJson.optBoolean(paramName);
            param.setSwitchStatus(value);

        } else if (AppConstants.UI_TYPE_DROP_DOWN.equalsIgnoreCase(param.getUiType())) {

            String labelValue = "";

            if (dataType.equalsIgnoreCase("int") || dataType.equalsIgnoreCase("integer")) {
                int value = deviceJson.optInt(paramName);
                labelValue = String.valueOf(value);
                param.setLabelValue(labelValue);
                param.setValue(value);
            } else {
                labelValue = deviceJson.optString(paramName);
                param.setLabelValue(labelValue);
            }
        } else {

            String labelValue = "";

            if (dataType.equalsIgnoreCase("bool") || dataType.equalsIgnoreCase("boolean")) {

                boolean value = deviceJson.optBoolean(paramName);
                if (value) {
                    param.setLabelValue("true");
                } else {
                    param.setLabelValue("false");
                }

            } else if (dataType.equalsIgnoreCase("int") || dataType.equalsIgnoreCase("integer")) {

                int value = deviceJson.optInt(paramName);
                labelValue = String.valueOf(value);
                param.setLabelValue(labelValue);

            } else if (dataType.equalsIgnoreCase("float") || dataType.equalsIgnoreCase("double")) {

                double value = deviceJson.optDouble(paramName);
                labelValue = String.valueOf(value);
                param.setLabelValue(labelValue);

            } else {

                labelValue = deviceJson.optString(paramName);
                param.setLabelValue(labelValue);

                if (param.getParamType().equals(AppConstants.PARAM_TYPE_NAME)) {
                    device.setUserVisibleName(labelValue);
                }
            }
        }
    }

    public static EspNode setNodeConfig(EspNode espNode, JSONObject nodeConfigJson) {

        // Node ID
        String nodeId = nodeConfigJson.optString(AppConstants.KEY_NODE_ID);

        if (TextUtils.isEmpty(nodeId)) {
            return null;
        }

        if (espNode == null) {
            espNode = new EspNode(nodeId);
        }

        // Node Config
        espNode.setConfigVersion(nodeConfigJson.optString(AppConstants.KEY_CONFIG_VERSION));

        JSONObject infoObj = nodeConfigJson.optJSONObject(AppConstants.KEY_INFO);

        if (infoObj != null) {
            espNode.setNodeName(infoObj.optString(AppConstants.KEY_NAME));
            espNode.setFwVersion(infoObj.optString(AppConstants.KEY_FW_VERSION));
            espNode.setNodeType(infoObj.optString(AppConstants.KEY_TYPE));
        } else {
            Log.d(TAG, "Info object is null");
        }

        // Devices
        JSONArray devicesJsonArray = nodeConfigJson.optJSONArray(AppConstants.KEY_DEVICES);
        ArrayList<Device> devices = new ArrayList<>();

        if (devicesJsonArray != null) {

            for (int i = 0; i < devicesJsonArray.length(); i++) {

                JSONObject deviceObj = devicesJsonArray.optJSONObject(i);
                Device device = new Device(nodeId);
                device.setDeviceName(deviceObj.optString(AppConstants.KEY_NAME));
                device.setUserVisibleName(deviceObj.optString(AppConstants.KEY_NAME));
                device.setDeviceType(deviceObj.optString(AppConstants.KEY_TYPE));
                device.setPrimaryParamName(deviceObj.optString(AppConstants.KEY_PRIMARY));

                JSONArray paramsJson = deviceObj.optJSONArray(AppConstants.KEY_PARAMS);
                ArrayList<Param> params = new ArrayList<>();

                if (paramsJson != null) {

                    for (int j = 0; j < paramsJson.length(); j++) {

                        JSONObject paraObj = paramsJson.optJSONObject(j);
                        Param param = new Param();
                        param.setName(paraObj.optString(AppConstants.KEY_NAME));
                        param.setParamType(paraObj.optString(AppConstants.KEY_TYPE));
                        param.setDataType(paraObj.optString(AppConstants.KEY_DATA_TYPE));
                        param.setUiType(paraObj.optString(AppConstants.KEY_UI_TYPE));
                        param.setDynamicParam(true);
                        params.add(param);

                        JSONArray propertiesJson = paraObj.optJSONArray(AppConstants.KEY_PROPERTIES);
                        ArrayList<String> properties = new ArrayList<>();

                        if (propertiesJson != null) {
                            for (int k = 0; k < propertiesJson.length(); k++) {

                                properties.add(propertiesJson.optString(k));
                            }
                        }
                        param.setProperties(properties);

                        JSONObject boundsJson = paraObj.optJSONObject(AppConstants.KEY_BOUNDS);

                        if (boundsJson != null) {
                            param.setMaxBounds(boundsJson.optInt(AppConstants.KEY_MAX));
                            param.setMinBounds(boundsJson.optInt(AppConstants.KEY_MIN));
                            param.setStepCount((float) boundsJson.optDouble(AppConstants.KEY_STEP, 0));
                        }

                        JSONArray validValuesJson = paraObj.optJSONArray(AppConstants.KEY_VALID_STRS);
                        ArrayList<String> validVals = new ArrayList<>();

                        if (validValuesJson != null) {
                            for (int k = 0; k < validValuesJson.length(); k++) {
                                validVals.add(validValuesJson.optString(k));
                            }
                        }
                        param.setValidStrings(validVals);
                    }
                }

                JSONArray attributesJson = deviceObj.optJSONArray(AppConstants.KEY_ATTRIBUTES);

                if (attributesJson != null) {

                    for (int j = 0; j < attributesJson.length(); j++) {

                        JSONObject attrObj = attributesJson.optJSONObject(j);
                        Param param = new Param();
                        param.setName(attrObj.optString(AppConstants.KEY_NAME));
                        param.setDataType(attrObj.optString(AppConstants.KEY_DATA_TYPE));
                        param.setLabelValue(attrObj.optString(AppConstants.KEY_VALUE));
                        params.add(param);
                    }
                }

                device.setParams(params);
                devices.add(device);
            }
        }
        espNode.setDevices(devices);

        // Services
        JSONArray servicesJsonArray = nodeConfigJson.optJSONArray(AppConstants.KEY_SERVICES);
        ArrayList<Service> services = new ArrayList<>();

        if (servicesJsonArray != null) {

            for (int i = 0; i < servicesJsonArray.length(); i++) {

                JSONObject serviceObj = servicesJsonArray.optJSONObject(i);
                Service service = new Service(nodeId);
                service.setName(serviceObj.optString(AppConstants.KEY_NAME));
                service.setType(serviceObj.optString(AppConstants.KEY_TYPE));

                JSONArray paramsJson = serviceObj.optJSONArray(AppConstants.KEY_PARAMS);
                ArrayList<Param> params = new ArrayList<>();

                if (paramsJson != null) {

                    for (int j = 0; j < paramsJson.length(); j++) {

                        JSONObject paraObj = paramsJson.optJSONObject(j);
                        Param param = new Param();
                        param.setName(paraObj.optString(AppConstants.KEY_NAME));
                        param.setParamType(paraObj.optString(AppConstants.KEY_TYPE));
                        param.setDataType(paraObj.optString(AppConstants.KEY_DATA_TYPE));
                        param.setDynamicParam(true);
                        params.add(param);

                        JSONArray propertiesJson = paraObj.optJSONArray(AppConstants.KEY_PROPERTIES);
                        ArrayList<String> properties = new ArrayList<>();

                        if (propertiesJson != null) {
                            for (int k = 0; k < propertiesJson.length(); k++) {

                                properties.add(propertiesJson.optString(k));
                            }
                        }
                        param.setProperties(properties);
                    }
                }
                service.setParams(params);
                services.add(service);
            }
        }
        espNode.setServices(services);

        // Attributes
        JSONArray nodeAttributesJson = infoObj.optJSONArray(AppConstants.KEY_ATTRIBUTES);
        ArrayList<Param> nodeAttributes = new ArrayList<>();

        if (nodeAttributesJson != null) {

            for (int j = 0; j < nodeAttributesJson.length(); j++) {

                JSONObject attrObj = nodeAttributesJson.optJSONObject(j);
                Param param = new Param();
                param.setName(attrObj.optString(AppConstants.KEY_NAME));
                param.setLabelValue(attrObj.optString(AppConstants.KEY_VALUE));
                nodeAttributes.add(param);
            }
        }
        espNode.setAttributes(nodeAttributes);

        // Node Params values
        JSONObject paramsJson = nodeConfigJson.optJSONObject(AppConstants.KEY_PARAMS);
        if (paramsJson != null) {

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
                            setDeviceParamValue(deviceJson, devices.get(i), param);
                        }
                    }
                } else {
                    Log.e(TAG, "Device JSON is null");
                }
            }
        }

        // Node Status
        JSONObject statusJson = nodeConfigJson.optJSONObject(AppConstants.KEY_STATUS);
        if (statusJson != null) {

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
        return espNode;
    }

    public static void setAllParams(EspApplication espAppContext, EspNode node, JSONObject paramsJson) {

        String nodeId = node.getNodeId();
        ArrayList<Device> devices = node.getDevices();
        ArrayList<Service> services = node.getServices();
        JSONObject scheduleJson = paramsJson.optJSONObject(AppConstants.KEY_SCHEDULE);
        JSONObject sceneJson = paramsJson.optJSONObject(AppConstants.KEY_SCENES);
        JSONObject timeJson = paramsJson.optJSONObject(AppConstants.KEY_TIME);
        JSONObject localControlJson = paramsJson.optJSONObject(AppConstants.KEY_LOCAL_CONTROL);

        if (devices != null) {
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
                            setDeviceParamValue(deviceJson, devices.get(i), param);
                        }
                    }
                } else {
                    Log.e(TAG, "Device JSON is not available");
                }
            }
        }

        // Schedules
        if (scheduleJson != null) {

            JSONArray scheduleArrayJson = scheduleJson.optJSONArray(AppConstants.KEY_SCHEDULES);

            if (scheduleArrayJson != null) {

                for (int index = 0; index < scheduleArrayJson.length(); index++) {

                    JSONObject schJson = null;
                    try {
                        schJson = scheduleArrayJson.getJSONObject(index);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
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

                        Schedule schedule = espAppContext.scheduleMap.get(key);
                        if (schedule == null) {
                            schedule = new Schedule();
                        }

                        schedule.setId(scheduleId);
                        schedule.setName(schJson.optString(AppConstants.KEY_NAME));
                        schedule.setEnabled(schJson.optBoolean(AppConstants.KEY_ENABLED));
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
                                            setDeviceParamValue(deviceAction, devices.get(deviceIndex), p);
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
                        espAppContext.scheduleMap.put(key, schedule);
                    }
                }
            }
        } else {
            Log.e(TAG, "Schedule JSON is not available");
        }

        // Scenes
        if (sceneJson != null) {

            JSONArray sceneArrayJson = sceneJson.optJSONArray(AppConstants.KEY_SCENES);

            if (sceneArrayJson != null) {

                for (int index = 0; index < sceneArrayJson.length(); index++) {

                    JSONObject scJson = null;
                    try {
                        scJson = sceneArrayJson.getJSONObject(index);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                    String sceneId = scJson.optString(AppConstants.KEY_ID);
                    String key = sceneId;

                    if (!TextUtils.isEmpty(sceneId)) {

                        String name = scJson.optString(AppConstants.KEY_NAME);
                        String info = scJson.optString(AppConstants.KEY_INFO);
                        key = key + "_" + name + "_" + info;

                        Scene scene = espAppContext.sceneMap.get(key);
                        if (scene == null) {
                            scene = new Scene();
                        }

                        scene.setId(sceneId);
                        scene.setName(name);
                        scene.setInfo(info);

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
                                            setDeviceParamValue(deviceAction, devices.get(deviceIndex), p);
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
                        espAppContext.sceneMap.put(key, scene);
                    }
                }
            }
        } else {
            Log.e(TAG, "Scene JSON is not available");
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
}
