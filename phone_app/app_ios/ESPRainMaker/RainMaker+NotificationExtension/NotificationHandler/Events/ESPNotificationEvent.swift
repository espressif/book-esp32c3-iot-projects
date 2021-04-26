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
//  ESPNotificationEvent.swift
//  ESPRainMaker
//

import Foundation

// Abstract class defining notification event properties and methods.
class ESPNotificationEvent: ESPNotificationProtocol {
    // Data associated with the event.
    var eventData: [String : Any]
    // Notification object created from the payload.
    var notification: ESPNotifications
    // Notification local storage handler
    let notificationStore = ESPNotificationsStore(ESPLocalStorageKeys.suiteName)
    
    init(_ eventDataObject: [String:Any], _ notificationObject: ESPNotifications) {
        eventData = eventDataObject
        notification = notificationObject
    }
    
    /// Method that provide modified message for a notification event.
    ///
    /// - Returns: Modified notification object.
    func modifiedContent() -> ESPNotifications? {
        return nil
    }
}
