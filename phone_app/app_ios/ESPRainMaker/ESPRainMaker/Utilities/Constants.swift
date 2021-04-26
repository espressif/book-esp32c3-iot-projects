// Copyright 2020 Espressif Systems
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
//
//  Constants.swift
//  ESPRainMaker
//

import Foundation

struct Constants {
    static let bundleIdentifier = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    // API version for the current network request
    static let apiVersion = "v1"

    // User-Defined keys
    static let deviceNamePrefix = "DeviceNamePrefix"
    static let allowFilteringByPrefix = "AllowFilteringByPrefix"
    static let wifiBaseUrl = "WifiBaseUrl"

    // User-Defined Values
    static let devicePrefixDefault = "PROV_"
    static let wifiBaseUrlDefault = "192.168.4.1:80"

    // Device path parameters
    static let configPath = "prov-config"
    static let versionPath = "proto-ver"
    static let scanPath = "prov-scan"
    static let sessionPath = "prov-session"
    static let associationPath = "cloud_user_assoc"
    static let claimPath = "rmaker_claim"

    // Segue identifiers
    static let deviceTraitListVCIdentifier = "deviceTrailListVC"
    static let nodeDetailSegue = "nodeDetailSegue"
    static let claimVCIdentifier = "claimVC"
    static let connectVCIdentifier = "connectVC"
    static let addScheduleSegue = "addScheduleSegue"
    static let addNewScheduleSegue = "addNewScheduleSegue"

    // JSON keys
    static let userID = "user_id"
    static let requestID = "request_id"

    static let usernameKey = "espusername"
    static let scanCharacteristic = "scan"
    static let sessionCharacterstic = "session"
    static let configCharacterstic = "config"
    static let versionCharacterstic = "ver"
    static let associationCharacterstic = "assoc"
    static let deviceInfoStoryboardID = "versionInfo"

    // Device version info
    static let provKey = "prov"
    static let capabilitiesKey = "cap"
    static let wifiScanCapability = "wifi_scan"
    static let noProofCapability = "no_pop"

    // Amazon Cognito setup configuration

    static let AWSCognitoUserPoolsSignInProviderKey = "UserPool"
    static let idProvider = "Github"

    // AWS cognito APIs
    static let addDevice = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/mapping"
    static let getUserId = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user"
    static let getNodes = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes"
    static let getNodeConfig = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/config"
    static let getNodeStatus = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/status"
    static let checkStatus = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/mapping"
    static let setParam = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/params"
    static let sharing = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/sharing"
    static let pushNotification = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/push_notification/mobile_platform_endpoint"
    static let deleteUserAccount = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user"

    // UserDefault keys
    static let newDeviceAdded = Constants.bundleIdentifier + ".newDeviceAdded"
    static let prefixKey = Constants.bundleIdentifier + ".prefix"
    static let userInfoKey = Constants.bundleIdentifier + ".userinfo"
    static let providerKey = Constants.bundleIdentifier + ".provider"
    static let idTokenKey = Constants.bundleIdentifier + ".idToken"
    static let refreshTokenKey = Constants.bundleIdentifier + ".refreshToken"
    static let accessTokenKey = Constants.bundleIdentifier + ".accessToken"
    static let userDetailsKey = Constants.bundleIdentifier + ".userDetails"
    static let expireTimeKey = Constants.bundleIdentifier + ".expiresIn"
    static let loginIdKey = Constants.bundleIdentifier + ".loginIdKey"
    static let appThemeKey = Constants.bundleIdentifier + ".appTheme"
    static let appBGKey = Constants.bundleIdentifier + ".appbg"
    static let ignoreVersionKey = Constants.bundleIdentifier + ".ignoreVersions"
    static let wifiPassword = Constants.bundleIdentifier + ".wifiPassword"

    // Device param keys
    static let deviceNameParam = "esp.param.name"
    static let deviceBrightnessParam = "esp.param.brightness"
    static let deviceSaturationParam = "esp.param.saturation"
    static let deviceCCTParam = "esp.param.cct"

    static let cognito = "Cognito"
    static let github = "Github"

    // UI types
    static let slider = "esp.ui.slider"
    static let hue = "esp.ui.hue-slider"
    static let toggle = "esp.ui.toggle"
    static let hueCircle = "esp.ui.hue-circle"
    static let bigSwitch = "esp.ui.push-btn-big"
    static let dropdown = "esp.ui.dropdown"
    static let trigger = "esp.ui.trigger"
    static let hidden = "esp.ui.hidden"

    // Service types
    static let timezoneServiceName = "esp.service.time"
    static let timezoneServiceParam = "esp.param.tz"

    // Theme Color
    static let backgroundColor = Configuration.shared.appThemeColor

    #if PROD
        static let tokenURL = "https://rainmaker-prod.auth.us-east-1.amazoncognito.com/oauth2/token"
    #else
        static let tokenURL = "https://rainmaker-staging.auth.us-east-1.amazoncognito.com/oauth2/token"
    #endif

    static let uiViewUpdateNotification = "com.espressif.updateuiview"
    static let paramUpdateNotification = "com.espressif.paramUpdate"
    static let scheduleParamNotification = "com.espressif.scheduleParamNotification"
    static let scheduleChangeNotification = "com.espressif.scheduleChangeNotification"

    static let networkUpdateNotification = "com.espressif.networkUpdateNotification"
    static let localNetworkUpdateNotification = "com.espressif.localNetworkUpdateNotification"
    static let reloadCollectionView = "com.espressif.reloadCollectionView"
    static let reloadParamTableView = "com.espressif.reloadParamTableView"
    static let refreshDeviceList = "com.espressif.refreshDeviceList"

    // Claim APIs
    static let claimInitPath = Configuration.shared.awsConfiguration.claimURL + "/claim/initiate"
    static let claimVerifyPath = Configuration.shared.awsConfiguration.claimURL + "/claim/verify"

    static let boolTypeValidValues: [String: Bool] = ["true": true, "false": false, "yes": true, "no": false, "0": false, "1": true]

    // Schedule related constants
    // TODO: Read service/param key from node config.
    static let scheduleServiceType = "esp.service.schedule"
    static let scheduleParamType = "esp.param.schedules"
    static let localControlServiceType = "esp.service.local_control"
    static let localControlParamType = "esp.param.local_control_type"
    static let popParamType = "esp.param.local_control_pop"
    static let scheduleKey = "Schedule"
    static let schedulesKey = "Schedules"

    static let serviceType = "_esp_local_ctrl._tcp."
    static let serviceDomain = "local"
    
    // APIs JSON keys
    static let successKey = "success"
    static let descriptionKey = "description"
    static let statusKey = "status"

    static let sceneServiceType = "esp.service.scenes"
    static let sceneParamType = "esp.param.scenes"
    static let sceneKey = "Scene"
    static let scenesKey = "Scenes"
    
    static let edit = "Edit"
    
    // Image names
    static let dummyDeviceImage = "dummy_device_icon"
}
