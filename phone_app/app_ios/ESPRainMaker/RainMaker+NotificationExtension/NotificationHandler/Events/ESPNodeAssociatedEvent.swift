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
//  ESPNodeAssociatedEvent.swift
//  ESPRainMaker
//

import Foundation

// Class associated with node associated event.
class ESPNodeAssociatedEvent: ESPNotificationEvent {
    /// Modifies notification content to display message of devices added.
    ///
    /// - Returns: Modified notification object.
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        modifiedNotification.body = "New device(s) are added. Tap to view."
        // Gets node id from the event data.
        if let nodes = eventData[ESPNotificationKeys.nodesKey] as? [String] {
            var devices: [String]?
            // Gets list of devices that's the node is linked with.
            if let nodeDeviceMapping = ESPLocalStorageNodes(ESPLocalStorageKeys.suiteName).getDeviceListDictionary() {
                for node in nodes {
                    if let nodeDevices = nodeDeviceMapping[node] {
                        devices = (devices ?? []) + nodeDevices
                    }
                }
            }
            // Customised message to make it more user friendly.
            if let deviceList = devices, deviceList.count > 0 {
                if deviceList.count == 1 {
                    // Customised message to make it more user friendly.
                    if deviceList.count > 1 {
                        modifiedNotification.body = "\(deviceList.joined(separator: ", ")) are added."
                    } else {
                        modifiedNotification.body = "\(deviceList[0]) is added."
                    }
                }
            }
        }
        // Saves notification in local storage.
        notificationStore.storeESPNotification(notification: modifiedNotification)
        // Returns modified notification.
        return modifiedNotification
    }
}
