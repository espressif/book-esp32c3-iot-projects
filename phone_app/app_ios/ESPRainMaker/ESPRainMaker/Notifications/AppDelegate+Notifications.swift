// Copyright 2021 Espressif Systems
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
//  AppDelegate+Notifications.swift
//  ESPRainMaker
//

import Foundation
import UIKit

extension AppDelegate {
    
    // MARK: - Notifications Configuration
    
    func configureRemoteNotifications() {
        registerForAddSharingEventActions()
        requestNotificationAuthorization()
    }
    
    // Method to request notification authorization for type .alert, .badge and .sound.
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            guard granted else { return }
            self?.getNotificationSettings()
        }
    }
    
    // Method to check current notification authorization status of the app
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    // Adds notification category for add sharing event type.
    private func registerForAddSharingEventActions() {
        ESPNotificationsAddSharingCategory.addCategory()
    }
    
    // Method to delete endpoints for current user on logout.
    func disablePlatformApplicationARN() {
        if let deviceToken = self.deviceToken {
            apiManager.genericAuthorizedJSONRequest(url: Constants.pushNotification + "?mobile_device_token=" + deviceToken, parameter: nil, method: .delete) { response, error in
            }
        }
    }

    // MARK: - Callbacks
    
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Retreive device token from deviceToken data.
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        // Send device token SNS to create a new iOS platform endpoint.
        apiManager.genericAuthorizedJSONRequest(url: Constants.pushNotification, parameter: ["platform": "APNS", "mobile_device_token": token], method: .post) { response, error in
            guard let _ = error else {
                // Save device token to use later while signing out.
                self.deviceToken = token
                return
            }
        }
    }
    
    
    // To display message even when app is in foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Parsed the notification payload to get event type information.
        let userInfo:[String:Any] = notification.request.content.userInfo as? [String:Any] ?? [:]
        let notificationHandler = ESPNotificationHandler(userInfo)
        // Update data if event is related with node connection.
        notificationHandler.updateData()
        completionHandler([.alert, .badge, .sound])
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Parsed the notification payload to get event type information.
        let userInfo:[String:Any] = response.notification.request.content.userInfo as? [String:Any] ?? [:]
        let notificationHandler = ESPNotificationHandler(userInfo)
        // Handled event related with other using notification handler.
        notificationHandler.handleEvent(ESPNotificationCategory(rawValue: response.notification.request.content.categoryIdentifier), response.actionIdentifier)
        completionHandler()
    }

    func application(_: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Silent notifications are used to update device params in real time in the app.
        ESPSilentNotificationHandler().handleSilentNotification(userInfo)
        fetchCompletionHandler(.newData)
    }
    
}
