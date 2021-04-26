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
//  Utility.swift
//  ESPRainMaker
//

import CoreBluetooth
import Foundation
import MBProgressHUD
import Network
import Reachability
import SystemConfiguration.CaptiveNetwork
import Toast_Swift
import UIKit

class Utility {
    static var deviceNamePrefix = Configuration.shared.espProvSetting.bleDevicePrefix
    static let allowPrefixFilter = Bundle.main.infoDictionary?[Constants.allowFilteringByPrefix] as? Bool ?? false
    static let baseUrl = Bundle.main.infoDictionary?[Constants.wifiBaseUrl] as? String ?? Constants.wifiBaseUrlDefault
    static var activeSSID = ""

    var deviceName = ""
    var configPath: String = Constants.configPath
    var versionPath: String = Constants.versionPath
    var scanPath: String = Constants.scanPath
    var sessionPath: String = Constants.sessionPath
    var associationPath: String = Constants.associationPath
    var peripheralConfigured = false
    var sessionCharacteristic: CBCharacteristic!
    var configUUIDMap: [String: CBCharacteristic] = [:]
    var deviceVersionInfo: NSDictionary?

    /// Method to store SSID of connected WI-Fi before provisioning
    ///
    class func setActiveSSID() {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    if let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String {
                        Utility.activeSSID = ssid
                    }
                }
            }
        }
    }

    /// This method can be invoked from any ViewController and will present MBProgressHUD loader with the given message
    ///
    /// - Parameters:
    ///   - message: Text to be showed inside the loader
    ///   - view: View in which loader is added
    class func showLoader(message: String, view: UIView) {
        DispatchQueue.main.async {
            let loader = MBProgressHUD.showAdded(to: view, animated: true)
            loader.mode = MBProgressHUDMode.indeterminate
            loader.label.text = message
            loader.isUserInteractionEnabled = false
        }
    }

    /// This method hide the MBProgressHUD loader and can be invoked from any ViewController
    ///
    class func hideLoader(view: UIView) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: view, animated: true)
        }
    }

    class func showToastMessage(view: UIView, message: String = "", duration: TimeInterval = ToastManager.shared.duration) {
        DispatchQueue.main.async {
            view.makeToast(message, duration: duration, position: ToastManager.shared.position, title: nil, image: nil, style: ToastManager.shared.style, completion: nil)
        }
    }
}
