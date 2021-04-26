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
//  ESPNodeSharingAddEvent.swift
//  ESPRainMaker
//

import Foundation

// Class associated with node sharing add event.
class ESPNodeSharingAddEvent: ESPNotificationEvent {
    /// Modifies notification content to display message of new device sharing request.
    ///
    /// - Returns: Modified notification object.
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        // Gets primary user email that initiated the sharing request.
        if let primaryUser = eventData[ESPNotificationKeys.primaryUserNameKey] as? String {
            var devices: [String]?
            // Gets metadata information from the event data.
            if let metadata = eventData[ESPNotificationKeys.metadataKey] as? [String:Any], let devicesInfo = metadata[ESPNotificationKeys.devicesKeys] as? [[String:String]] {
                // Gets list of shared devices from metadata.
                for device in devicesInfo {
                    if let name = device[ESPNotificationKeys.nameKey] {
                        devices = (devices ?? []) + [name]
                    }
                }
            }
            // Customised message to make it more user friendly.
            modifiedNotification.body = "\(primaryUser) wants to share \(devices?.combinedStringForDevices() ?? "device(s)") with you. Tap to accept or decline."
        }
        // Returns modified notification.
        return modifiedNotification
    }
}
