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
//  ESPNotificationsStore.swift
//  ESPRainMaker
//

import Foundation

// Protocol for managing local storage of notifications.
protocol ESPNotificationsStoreProtocol {
    func getDeliveredESPNotifications() -> [ESPNotifications]?
    func storeESPNotification(notification: ESPNotifications)
    func cleanupNotifications()
}

class ESPNotificationsStore: ESPLocalStorage, ESPNotificationsStoreProtocol {
    
    var notificationLimit: Int
    
    init(_ suiteName: String?, _ limit: Int = 200) {
        notificationLimit = limit
        super.init(suiteName)
    }
    
    /// Method to fetch locally stored notifications for current user.
    ///
    /// - Returns: Array of ESPNotifications object.
    func getDeliveredESPNotifications() -> [ESPNotifications]? {
        if let notificationData = getDataFromSharedUserDefault(key: ESPLocalStorageKeys.notificationStore) {
            do {
                var storedNotifications: [ESPNotifications] = []
                storedNotifications = try JSONDecoder().decode([ESPNotifications].self, from: notificationData)
                storedNotifications.sort(by: { $0.timestamp > $1.timestamp})
                return storedNotifications
            } catch {
                print(error)
                return nil
            }
        }
        return nil
    }
    
    /// Method to save notification locally.
    ///
    /// - Parameters:
    ///   - notification: ESPNotifications object.
    func storeESPNotification(notification: ESPNotifications) {
        do {
            var notifications:[ESPNotifications] = []
            notifications.append(contentsOf: getDeliveredESPNotifications() ??  [])
            notifications.insert(notification, at: 0)
            notifications = Array(notifications.prefix(notificationLimit))
            let encoded = try JSONEncoder().encode(notifications)
            saveDataInUserDefault(data: encoded, key: ESPLocalStorageKeys.notificationStore)
        } catch {
            print(error)
        }
    }
    
    /// Method to clean all notifications from local storage.
    func cleanupNotifications() {
        cleanupData(forKey: ESPLocalStorageKeys.notificationStore)
    }
}
