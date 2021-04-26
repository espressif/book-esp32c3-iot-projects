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

import com.espressif.rainmaker.BuildConfig;

public class AppConstants {

    public static final String SECURITY_0 = "Sec0";
    public static final String SECURITY_1 = "Sec1";

    public static final String TRANSPORT_SOFTAP = "softap";
    public static final String TRANSPORT_BLE = "ble";
    public static final String TRANSPORT_BOTH = "both";

    // Device End point names
    public static final String HANDLER_RM_USER_MAPPING = "cloud_user_assoc";
    public static final String HANDLER_RM_CLAIM = "rmaker_claim";

    public static final String ESP_PREFERENCES = "Esp_Preferences";
    public static final String PREF_FILE_WIFI_NETWORKS = "wifi_networks";
    public static final String ESP_DATABASE_NAME = "esp_db";
    public static final String NODE_TABLE = "node_table";
    public static final String GROUP_TABLE = "group_table";
    public static final String NOTIFICATION_TABLE = "notification_table";
    public static final String MDNS_SERVICE_TYPE = "_esp_local_ctrl._tcp.";
    public static final String LOCAL_CONTROL_ENDPOINT = "esp_local_ctrl/control";
    public static final String LOCAL_SESSION_ENDPOINT = "esp_local_ctrl/session";

    public enum UpdateEventType {

        EVENT_DEVICE_ADDED,
        EVENT_DEVICE_REMOVED,
        EVENT_DEVICE_ONLINE,
        EVENT_DEVICE_OFFLINE,
        EVENT_ADD_DEVICE_TIME_OUT,
        EVENT_DEVICE_STATUS_UPDATE,
        EVENT_STATE_CHANGE_UPDATE,
        EVENT_LOCAL_DEVICE_UPDATE
    }

    public static final String CURRENT_VERSION = "v1";
    public static final String PATH_SEPARATOR = "/";
    public static final String HEADER_AUTHORIZATION = "Authorization";

    // Cloud API End point Urls
    public static final String URL_LOGIN = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/login";
    public static final String URL_LOGOUT = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/logout";
    public static final String URL_USER = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/user";
    public static final String URL_FORGOT_PASSWORD = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/forgotpassword";
    public static final String URL_CHANGE_PASSWORD = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/password";

    public static final String URL_SUPPORTED_VERSIONS = BuildConfig.BASE_URL + "/apiversions";
    public static final String URL_OAUTH_LOGIN = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/login";
    public static final String URL_USER_NODE_MAPPING = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/user/nodes/mapping";
    public static final String URL_USER_NODES = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/user/nodes";
    public static final String URL_USER_NODES_DETAILS = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/user/nodes?node_details=true";
    public static final String URL_USER_NODE_STATUS = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/user/nodes/status";
    public static final String URL_USER_NODES_PARAMS = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/user/nodes/params";
    public static final String URL_CLAIM_INITIATE = BuildConfig.CLAIM_BASE_URL + "/claim/initiate";
    public static final String URL_CLAIM_VERIFY = BuildConfig.CLAIM_BASE_URL + "/claim/verify";
    public static final String URL_USER_NODE_GROUP = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/user/node_group";
    public static final String URL_USER_NODES_SHARING_REQUESTS = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/user/nodes/sharing/requests";
    public static final String URL_USER_NODES_SHARING = BuildConfig.BASE_URL + AppConstants.PATH_SEPARATOR
            + AppConstants.CURRENT_VERSION + "/user/nodes/sharing";

    // UI Types of Device
    public static final String UI_TYPE_TOGGLE = "esp.ui.toggle";
    public static final String UI_TYPE_PUSH_BTN_BIG = "esp.ui.push-btn-big";
    public static final String UI_TYPE_SLIDER = "esp.ui.slider";
    public static final String UI_TYPE_HUE_SLIDER = "esp.ui.hue-slider";
    public static final String UI_TYPE_HUE_CIRCLE = "esp.ui.hue-circle";
    public static final String UI_TYPE_DROP_DOWN = "esp.ui.dropdown";
    public static final String UI_TYPE_HIDDEN = "esp.ui.hidden";
    public static final String UI_TYPE_TRIGGER = "esp.ui.trigger";

    // ESP Device Types
    public static final String ESP_DEVICE_SWITCH = "esp.device.switch";
    public static final String ESP_DEVICE_BULB = "esp.device.lightbulb";
    public static final String ESP_DEVICE_BULB_CCT = "esp.device.lightbulb-cct";
    public static final String ESP_DEVICE_BULB_RGB = "esp.device.lightbulb-rgb";
    public static final String ESP_DEVICE_LOCK = "esp.device.lock";
    public static final String ESP_DEVICE_THERMOSTAT = "esp.device.thermostat";
    public static final String ESP_DEVICE_FAN = "esp.device.fan";
    public static final String ESP_DEVICE_SENSOR = "esp.device.sensor";
    public static final String ESP_DEVICE_TEMP_SENSOR = "esp.device.temperature-sensor";
    public static final String ESP_DEVICE_OUTLET = "esp.device.outlet";

    // Service Types
    public static final String SERVICE_TYPE_SCHEDULE = "esp.service.schedule";
    public static final String SERVICE_TYPE_SCENES = "esp.service.scenes";
    public static final String SERVICE_TYPE_TIME = "esp.service.time";
    public static final String SERVICE_TYPE_LOCAL_CONTROL = "esp.service.local_control";

    // Param Types
    public static final String PARAM_TYPE_NAME = "esp.param.name";
    public static final String PARAM_TYPE_CCT = "esp.param.cct";
    public static final String PARAM_TYPE_POWER = "esp.param.power";
    public static final String PARAM_TYPE_SATURATION = "esp.param.saturation";
    public static final String PARAM_TYPE_BRIGHTNESS = "esp.param.brightness";
    public static final String PARAM_TYPE_TEMPERATURE = "esp.param.temperature";
    public static final String PARAM_TYPE_TZ = "esp.param.tz";
    public static final String PARAM_TYPE_TZ_POSIX = "esp.param.tz_posix";
    public static final String PARAM_TYPE_LOCAL_CONTROL_POP = "esp.param.local_control_pop";
    public static final String PARAM_TYPE_LOCAL_CONTROL_TYPE = "esp.param.local_control_type";

    // Keys used to pass data between activities and to store data in SharedPreference.
    public static final String KEY_DEVICE_NAME_PREFIX = "device_prefix";
    public static final String KEY_PROOF_OF_POSSESSION = "proof_of_possession";
    public static final String KEY_DEVICE_NAME = "device_name";
    public static final String KEY_ESP_DEVICE = "esp_device";
    public static final String KEY_NODE_ID = "node_id";
    public static final String KEY_EMAIL = "email";
    public static final String KEY_USER_ID = "user_id";
    public static final String KEY_ID_TOKEN = "id_token";
    public static final String KEY_ACCESS_TOKEN = "access_token";
    public static final String KEY_REFRESH_TOKEN = "refresh_token";
    public static final String KEY_IS_OAUTH_LOGIN = "is_github_login";
    public static final String KEY_ERROR_MSG = "err_msg";
    public static final String KEY_SSID = "ssid";
    public static final String KEY_PASSWORD = "password";
    public static final String KEY_SECURITY_TYPE = "security_type";
    public static final String KEY_SHOULD_SAVE_PWD = "save_password";
    public static final String KEY_NEW_PASSWORD = "newpassword";
    public static final String KEY_REQUEST = "request";
    public static final String KEY_VERIFICATION_CODE = "verification_code";
    public static final String KEY_MOBILE_DEVICE_TOKEN = "mobile_device_token";
    public static final String KEY_PLATFORM = "platform";
    public static final String KEY_GCM = "GCM";
    public static final String KEY_MESSAGE_BODY = "message_body";
    public static final String KEY_ALERT_STRING = "esp.alert.str";

    // Keys used in JSON responses and used to pass data between activities.
    public static final String KEY_NAME = "name";
    public static final String KEY_TYPE = "type";
    public static final String KEY_DATA_TYPE = "data_type";
    public static final String KEY_UI_TYPE = "ui_type";

    public static final String KEY_NODE_DETAILS = "node_details";
    public static final String KEY_DEVICES = "devices";
    public static final String KEY_PARAMS = "params";
    public static final String KEY_PROPERTIES = "properties";
    public static final String KEY_ATTRIBUTES = "attributes";
    public static final String KEY_SERVICES = "services";
    public static final String KEY_SCHEDULES = "Schedules";
    public static final String KEY_SCENES = "Scenes";
    public static final String KEY_TRIGGERS = "triggers";
    public static final String KEY_BOUNDS = "bounds";
    public static final String KEY_SELECTED_DEVICES = "selected_devices";

    public static final String KEY_SUPPORTED_VERSIONS = "supported_versions";
    public static final String KEY_ADDITIONAL_INFO = "additional_info";
    public static final String KEY_CONFIG = "config";
    public static final String KEY_CONFIG_VERSION = "config_version";
    public static final String KEY_FW_VERSION = "fw_version";
    public static final String KEY_INFO = "info";
    public static final String KEY_PRIMARY = "primary";
    public static final String KEY_MAX = "max";
    public static final String KEY_MIN = "min";
    public static final String KEY_STEP = "step";
    public static final String KEY_VALID_STRS = "valid_strs";
    public static final String KEY_VALUE = "value";
    public static final String KEY_SCHEDULE = "Schedule";
    public static final String KEY_SCENE = "Scene";
    public static final String KEY_ACTION = "action";
    public static final String KEY_ACTIONS = "actions";
    public static final String KEY_DAYS = "d";
    public static final String KEY_MINUTES = "m";
    public static final String KEY_ENABLED = "enabled";
    public static final String KEY_ID = "id";
    public static final String KEY_ROLE = "role";
    public static final String KEY_STATUS = "status";
    public static final String KEY_TIME = "Time";
    public static final String KEY_CONNECTIVITY = "connectivity";
    public static final String KEY_CONNECTED = "connected";
    public static final String KEY_TIMESTAMP = "timestamp";
    public static final String KEY_DESCRIPTION = "description";
    public static final String KEY_PROPERTY_WRITE = "write";
    public static final String KEY_FAILURE_RESPONSE = "failure";
    public static final String KEY_SECRET_KEY = "secret_key";
    public static final String KEY_PROPERTY_COUNT = "property_count";
    public static final String KEY_CLAIM_VERIFY_RESPONSE = "claim_verify_response";
    public static final String KEY_CLAIM_INIT_RESPONSE = "claim_initiate_response";
    public static final String KEY_REQ_ID = "request_id";
    public static final String KEY_REQ_STATUS = "request_status";
    public static final String KEY_REQ_TIME = "request_timestamp";
    public static final String KEY_REQ_CONFIRMED = "confirmed";
    public static final String KEY_REQ_TIMEDOUT = "timedout";
    public static final String KEY_REQ_TIMESTAMP = "request_timestamp";
    public static final String KEY_USER_REQUEST = "user_request";
    public static final String KEY_GROUP_ID = "group_id";
    public static final String KEY_GROUP_NAME = "group_name";
    public static final String KEY_GROUPS = "groups";
    public static final String KEY_NODES = "nodes";
    public static final String KEY_NODE_LIST = "node_list";
    public static final String KEY_GROUP = "group";
    public static final String KEY_NODE_IDS = "node_ids";
    public static final String KEY_NODE_SHARING = "node_sharing";
    public static final String KEY_USERS = "users";
    public static final String KEY_PRIMARY_USER = "primary_user";
    public static final String KEY_START_REQ_ID = "start_request_id";
    public static final String KEY_START_USER_NAME = "start_user_name";
    public static final String KEY_NEXT_REQ_ID = "next_request_id";
    public static final String KEY_NEXT_USER_NAME = "next_user_name";
    public static final String KEY_PRIMARY_USER_NAME = "primary_user_name";
    public static final String KEY_SECONDARY_USER_NAME = "secondary_user_name";
    public static final String KEY_USER_NAME = "user_name";
    public static final String KEY_REQ_ACCEPT = "accept";
    public static final String KEY_SHARING_REQUESTS = "sharing_requests";
    public static final String KEY_METADATA = "metadata";
    public static final String KEY_START_ID = "start_id";
    public static final String KEY_NEXT_ID = "next_id";
    public static final String KEY_EVENT_VERSION = "event_version";
    public static final String KEY_EVENT_TYPE = "event_type";
    public static final String KEY_EVENT_DATA = "event_data";
    public static final String KEY_TITLE = "title";
    public static final String KEY_BODY = "body";
    public static final String KEY_EVENT_DATA_PAYLOAD = "event_data_payload";
    public static final String KEY_NOTIFICATION_MSG = "notification_msg";
    public static final String KEY_PAYLOAD = "payload";
    public static final String KEY_LOCAL_CONTROL = "Local Control";
    public static final String KEY_REDIRECT_URI = "redirect_uri";
    public static final String KEY_CODE = "code";
    public static final String KEY_AUTH_CODE = "authCode";
    public static final String KEY_ACCOUNT_LINK_REQUEST = "accountLinkRequest";
    public static final String KEY_STAGE = "stage";
    public static final String KEY_CLIENT_ID = "client_id";
    public static final String KEY_CLIENT_SECRET = "client_secret";
    public static final String KEY_GRANT_TYPE = "grant_type";
    public static final String KEY_CONTENT_TYPE = "Content-type";
    public static final String KEY_ENDPOINTS = "endpoints";
    public static final String KEY_ACCOUNTLINK = "accountLink";
    public static final String KEY_SKILL = "skill";
    public static final String KEY_STATUS_LINKED = "LINKED";
    public static final String KEY_RESPONSE = "response";

    public static final String KEY_OPERATION = "operation";
    public static final String KEY_OPERATION_ADD = "add";
    public static final String KEY_OPERATION_EDIT = "edit";
    public static final String KEY_OPERATION_REMOVE = "remove";
    public static final String KEY_OPERATION_ENABLE = "enable";
    public static final String KEY_OPERATION_DISABLE = "disable";
    public static final String KEY_OPERATION_ACTIVATE = "activate";

    public static final String KEY_REQ_STATUS_DECLINED = "declined";
    public static final String KEY_REQ_STATUS_PENDING = "pending";

    public static final String KEY_USER_ROLE_PRIMARY = "primary";
    public static final String KEY_USER_ROLE_SECONDARY = "secondary";
    public static final String KEY_PRIMARY_USERS = "primary_users";
    public static final String KEY_SECONDARY_USERS = "secondary_users";

    // Device capability
    public static final String CAPABILITY_WIFI_SACN = "wifi_scan";
    public static final String CAPABILITY_NO_POP = "no_pop";
    public static final String CAPABILITY_CLAIM = "claim";

    public static final String WIFI_SCAN_FROM_DEVICE = "Device";
    public static final String WIFI_SCAN_FROM_PHONE = "Phone";

    // Event types
    public static final String EVENT_NODE_CONNECTED = "rmaker.event.node_connected";
    public static final String EVENT_NODE_DISCONNECTED = "rmaker.event.node_disconnected";
    public static final String EVENT_NODE_ADDED = "rmaker.event.user_node_added";
    public static final String EVENT_NODE_REMOVED = "rmaker.event.user_node_removed";
    public static final String EVENT_NODE_SHARING_ADD = "rmaker.event.user_node_sharing_add";
    public static final String EVENT_NODE_PARAM_MODIFIED = "rmaker.event.node_params_changed";
    public static final String EVENT_ALERT = "rmaker.event.alert";

    // Notification channel IDs
    public static final String CHANNEL_NODE_ONLINE_ID = "notify_node_online_id";
    public static final String CHANNEL_NODE_OFFLINE_ID = "notify_node_offline_id";
    public static final String CHANNEL_NODE_ADDED = "notify_node_added_id";
    public static final String CHANNEL_NODE_REMOVED = "notify_node_removed_id";
    public static final String CHANNEL_ALERT = "notify_alert_id";
    public static final String CHANNEL_NODE_SHARING = "notify_node_sharing_id";

    public static final String ACTION_ACCEPT = "com.espressif.rainmaker.ACTION_ACCEPT";
    public static final String ACTION_DECLINE = "com.espressif.rainmaker.ACTION_DECLINE";

    public static final String ALEXA_PACKAGE_NAME = "com.amazon.dee.app";
    public static final String KEY_ALEXA_ACCESS_TOKEN = "alexa_access_token";
    public static final String KEY_ALEXA_REFRESH_TOKEN = "alexa_refresh_token";

    public static final String EVENT_ENABLE_SKILL = "enable_skill";
    public static final String EVENT_DISABLE_SKILL = "disable_skill";
    public static final String EVENT_GET_STATUS = "get_status";

    // Constants for Alexa account linking
    public static final String ALEXA_API_ENDPOINTS_URL = "https://api.amazonalexa.com/v1/alexaApiEndpoint";
    public static final String ALEXA_REFRESH_TOKEN_URL = "https://api.amazon.com/auth/o2/token";
    public static final String ALEXA_APP_URL = "https://alexa.amazon.com/spa/skill-account-linking-consent?fragment=skill-account-linking-consent";
    public static final String LWA_URL = "https://www.amazon.com/ap/oa";
    public static final String LWA_SCOPE = "alexa::skills:account_linking";
    public static final String STATE = "temp"; // Place holder string
}
