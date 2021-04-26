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
//  ESPNodeSharingDeclinedEvent.swift
//  ESPRainMaker
//

import Foundation

// Class associated with node sharing declined event.
class ESPNodeSharingDeclinedEvent: ESPNotificationEvent {
    /// Modifies notification content to display message of devices sharing declined.
    ///
    /// - Returns: Modified notification object.
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        // Gets secondary user email that declined the sharing request.
        if let secondaryUser = eventData[ESPNotificationKeys.secondaryUserNameKey] as? String, let nodes = eventData[ESPNotificationKeys.nodesKey] as? [String] {
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
            modifiedNotification.body = "\(secondaryUser) declined sharing request for \(devices?.combinedStringForDevices() ?? "device(s)")."
        }
        // Saves notification in local storage.
        notificationStore.storeESPNotification(notification: modifiedNotification)
        // Returns modified notification.
        return modifiedNotification
    }
}
