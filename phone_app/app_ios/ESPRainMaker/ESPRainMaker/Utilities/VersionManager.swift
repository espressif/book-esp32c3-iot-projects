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
//  VersionManager.swift
//  ESPRainMaker
//
//  Created by Vikas Chandra on 10/12/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Alamofire
import Foundation

class VersionManager {
    /// A singleton class that manages Version related info of app
    static let shared = VersionManager()

    let currentAppVersion = "1.0"
    let currentAPIVersion = "v1"

    private let supportedVersionURL = Configuration.shared.awsConfiguration.baseURL + "/" + "apiversions"
    private var appStoreURL = "itms-apps://"

    private var mainWindow: UIWindow?
    private lazy var alertWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level.alert
        return window
    }()

    private init() {}

    /// Check App store if any new version of this app is avaiable for download.
    ///
    /// - Parameters:
    ///   - callback: handler called after response is recieved with version and status as argument
    private func checkAppStore(callback: ((_ versionAvailable: Bool?, _ version: String?) -> Void)? = nil) {
        let ourBundleId = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
        AF.request("https://itunes.apple.com/lookup?bundleId=" + ourBundleId).responseJSON { response in
            var isNew: Bool?
            var versionStr: String?

            switch response.result {
            case let .success(value):
                if let json = value as? NSDictionary,
                   let results = json["results"] as? NSArray,
                   let entry = results.firstObject as? NSDictionary,
                   let appVersion = entry["version"] as? String
                {
                    let currentVersion = Constants.appVersion
                    if let storeURL = entry["trackViewUrl"] as? String {
                        self.appStoreURL = storeURL
                    }
                    let compareVersion = currentVersion.compare(appVersion, options: .numeric)
                    isNew = false
                    if compareVersion == .orderedAscending {
                        isNew = true
                    }
                    versionStr = appVersion
                }
                callback?(isNew, versionStr)
            case let .failure(error):
                print(error)
            }
        }
    }

    /// Perform check if current api version is supported.
    ///
    /// - Parameters:
    ///   - callback: handler called after response of supported api version is recieved
    private func checkIfAPIVersionIsSupported(callback: @escaping (Bool) -> Void) {
        AF.request(supportedVersionURL).responseJSON { response in
            switch response.result {
            case let .success(value):
                if let json = value as? [String: Any], let supportedVersion = json["supported_versions"] as? [String] {
                    if !supportedVersion.contains(self.currentAPIVersion) {
                        callback(false)
                        return
                    }
                }
            case let .failure(error):
                print(error)
            }
            callback(true)
        }
    }

    /// Main method to check if new App store version of the app is available.
    /// Or if current api version is supported or not.
    /// Show appropriate alert message acoording to the need of update.
    ///
    func checkForAppUpdate() {
        checkAppStore { isAvailable, version in
            if let available = isAvailable {
                if available {
                    self.checkIfAPIVersionIsSupported { isSupported in
                        if isSupported {
                            if let versionStrings = UserDefaults.standard.value(forKey: Constants.ignoreVersionKey) as? [String], let updatedVersion = version {
                                if versionStrings.contains(updatedVersion) {
                                    return
                                }
                            }
                            let ignoreAction = UIAlertAction(title: "Ignore", style: .default) { _ in
                                var ignoreVersions: [String] = []
                                if let versionStrings = UserDefaults.standard.value(forKey: Constants.ignoreVersionKey) as? [String] {
                                    ignoreVersions.append(contentsOf: versionStrings)
                                }
                                if let updatedVersion = version {
                                    ignoreVersions.append(updatedVersion)
                                }
                                UserDefaults.standard.setValue(ignoreVersions, forKey: Constants.ignoreVersionKey)
                            }
                            let updateAction = UIAlertAction(title: "Update", style: .default) { _ in
                                self.goToAppStore()
                            }
                            let remindAction = UIAlertAction(title: "Remind me", style: .default) { _ in
                            }
                            self.showAlert(title: "Update", message: "A new version of this app is available on App Store to download.", actions: [updateAction, ignoreAction, remindAction])
                        } else {
                            let updateAction = UIAlertAction(title: "Update", style: .default) { _ in
                                self.goToAppStore()
                            }
                            self.showAlert(title: "Update", message: "A new version of this app is available on App Store to download.", actions: [updateAction])
                        }
                    }
                }
            }
        }
    }

    private func goToAppStore() {
        if let url = URL(string: appStoreURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    func showAlert(title: String, message: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for item in actions {
            alertController.addAction(item)
        }
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

            topController.present(alertController, animated: true, completion: nil)
        }
    }
}
