
## ESP RainMaker iOS App

  

This is the official iOS app for [ESP RainMaker](https://github.com/espressif/esp-rainmaker), an end-to-end solution offered by Espressif to enable remote control and monitoring for ESP32-S2 and ESP32 based products without any configuration required in the Cloud.

  

For more details :

- Please check the ESP RainMaker documentation [here](http://rainmaker.espressif.com/docs/get-started.html) to get started.

- Try out this app in [App Store](https://apps.apple.com/app/esp-rainmaker/id1497491540).

  

## Features

  

### User Management

  

- Signup/Signin using email id.

- Third party login includes Apple login, GitHub and Google.

- Forgot/reset password support.

- Signing out.

  

### Provisioning

  

- Uses [ESPProvision](https://github.com/espressif/esp-idf-provisioning-ios/) library for provisioning.

- Automatically connects to device using QR code.

- Can choose manual flow if QR code is not present.

- Shows list of available Wi-Fi networks.

- Supports SoftAP based Wi-Fi Provisioning.

- Performs the User-Node association workflow.

  

### Manage

  

- List all devices associated with a user.

- Shows node and device details.

- Capability to remove node of a user.

- Shows online/offline status of nodes.

  

### Control

  

- Shows all static and configurable parameters of a device.

- Adapt UI according to the parameter type like toggle for power, slider for brightness.

- Allow user to change and monitor parameters of devices.


### Local Control


- This feature allows discovering devices on local Wi-Fi network using Bonjour (mDNS) and controlling them using HTTP as per the [ESP Local Control](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/esp32/api-reference/protocols/esp_local_ctrl.html) specifications.

- Local Control ensures your devices are reachable even when your internet connection is poor or there is no internet over connected Wi-Fi.

- Supports both secure and unsecure communication with device over local network.

Local Control feature is optional but enabled by default. It can be disabled from the `Configuration.plist` by setting `Enable Local Control` key from `App Configuration` to `NO`.


### Personalisation

  

- Change theme colour of App at runtime.

- Change app background during runtime.

### Scheduling

 Schedules allow you to automate a device by setting it to trigger an action at the same time on a specified day or days of the week.  List of operations that are supported for scheduling :
 
 - Add.
 - Edit.
 - Remove.
 - Enable/disable.

Schedule feature is optional but enabled by default. Schedule can be disabled from the `Configuration.plist` by setting `Enable Schedule` key from `App Configuration` to `NO`.

### Scenes

 Scene is a group of parameters with specific values, for one or more devices (optionally) spanning across multiple nodes. As an example, an "Evening" scene may turn on all the lights and set them to a warm colour. A "Night" scene may turn off all the lights, turn on a bedside lamp set to minimal brightness and turn on the fan/ac. 
 List of operations that are supported for scene :
 
 - Add.
 - Edit.
 - Remove.
 - Activate.

Scene feature is optional but enabled by default. Scenes can be disabled from the `Configuration.plist` by setting `Enable Scene` key from `App Configuration` to `NO`.

### Node Grouping

Node Grouping allows you to create abstract or logical groups of devices like lights, switches, fans etc. List of operations that are supported in node grouping :

 - Create groups.
 - Edit groups (rename or add/remove device).
 - Remove groups.
 - List groups.

Node Grouping is optional but enabled by default. It can be disabled from the `Configuration.plist` by setting `Enable Grouping` key from `App Configuration` to `NO`.
  
  ### Node Sharing

  Node Sharing allows a user to share nodes with other registered users and allow them to monitor and control these nodes.
  List of operations that are supported in node sharing :

  For primary users:

  - Register requests to share nodes.
  - View pending requests.
  - Cancel a pending request, if required.
  - Remove node sharing.

  For secondary users:

  - View pending requests.
  - Accept/decline pending requests.

Node Sharing is optional but enabled by default. It can be disabled from the `Configuration.plist` by setting `Enable Sharing` key from `App Configuration` to `NO`.


### Push Notifications

ESPRainMaker app supports remote notifiations in order to notify app in realtime for any updates. Types of notification enabled in the app :

1. Alert notification: User will be updated by sending alert notification in case of below events:
   - A new node is added to the user.
   - Existing node is removed from the user account.
   - Node sharing request is accepted/declined by secondary user.
   - Alerts triggered from the node.
 
2. Actionable notification: In case a node sharing request is received, user will be be alerted with an actionable notification. This will enable the user to accept or decline the sharing request from the notification center.

3. Silent notifications: This notification is triggered at the time when any of the user device param changes. It will update the app with latest param value in case when app is in foreground.

### Alexa App to App Linking

  This account linking flow enables users to link their Alexa user identity with their Rainmaker identity
  by starting from Rainmaker app. When they start the account linking flow from the app, users can:
  - Discover their Alexa skill through the app.
  - Initiate skill enablement and account linking from within the app.
  - Link their account without entering Alexa account credentials if already logged into Alexa app. They will have to login to Rainmaker once, when trying to link accounts.
  - Link their account from your Rainmaker using [Login with Amazon (LWA)](https://developer.amazon.com/docs/login-with-amazon/documentation-overview.html), when the Alexa app isn&#39;t installed on their device.

## Supports


- iOS 12.0 or greater.

- Xcode 13.0

- Swift 5+

  

## Installation

- Run `pod install` from  ESPRainMaker folder in the terminal.

- After pod installation open ESPRainMaker.xcworkspace project.

- Build and run the project.


## Additional Settings

Settings associated with provisioning a device can be modified in the `Configuration.plist` file under `Provision Settings` dictionary. Description of each key can be found below.

| Key      | Type |   Description |
| ----------- | ----------- | --- |
| ESP Transport | String | Possible values: <br>**Both**(Default) : Supports both BLE and SoftAP device provisioning.<br>**SoftAP** : supports only SoftAP device provisioning.<br>**BLE** : supports only BLE device provisioning. |
| BLE Device Prefix | String | Search for BLE devices with this prefix in name. |
| ESP Allow Prefix Search | Bool | Prefix search allows you to filter available BLE device list based on prefix value.  |
| ESP Security Mode | String | Possible values: <br>**Secure**(Default) : for secure/encrypted communication between device and app.<br>**Unsecure** : for unsecure/unencrypted communication between device and app.|

## License

  

Licensed under Apache License Version 2.0.
