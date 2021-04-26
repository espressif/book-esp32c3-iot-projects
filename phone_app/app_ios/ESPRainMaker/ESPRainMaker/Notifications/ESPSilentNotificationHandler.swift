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
//  ESPSilentNotificationHandler.swift
//  ESPRainMaker
//

import Foundation

// Protocol for handling silent notifications.
protocol ESPSilentNotificationProtocol {
    func handleSilentNotification(_ userInfo: [AnyHashable:Any])
}

struct ESPSilentNotificationHandler: ESPSilentNotificationProtocol {
    
    let dataKey = "data"
    let payloadKey = "payload"
    
    /// Method to handle silent notification in the app.
    ///
    /// - Parameters:
    ///   - userInfo: Payload information in  form of dictionary.
    func handleSilentNotification(_ userInfo: [AnyHashable : Any]) {
        // Parsed the user information to get payload string.
        if let data = userInfo[dataKey] as? [String: Any], let eventDataPayload = data[ESPNotificationKeys.eventDataPayloadKey] as? [String: Any], let eventData = eventDataPayload[ESPNotificationKeys.eventDataKey] as? [String: Any], let nodeID = eventData[ESPNotificationKeys.nodeIDKey] as? String, let payload = eventData[payloadKey] as? String {
            // Converted string into data to allow conversion to json object.
            let data = payload.data(using: .utf8)!
            do {
                // Converted data to json object.
                if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any], let index = User.shared.associatedNodeList?.firstIndex(where: { $0.node_id == nodeID }) {
                    let node = User.shared.associatedNodeList![index]
                    for key in json.keys {
                        // Get devices for which param update is received.
                        for device in node.devices ?? [] {
                            if device.name == key {
                                if let paramDict = json[key] as? [String: Any] {
                                    for paramKey in paramDict.keys {
                                        // Finding param whose value is updated.
                                        for param in device.params ?? [] {
                                            if param.name == paramKey {
                                                // Updated the param value.
                                                param.value = paramDict[paramKey]
                                                // Triggered local notification to let classes update their UI elements.
                                                NotificationCenter.default.post(Notification(name: Notification.Name(Constants.reloadCollectionView)))
                                                NotificationCenter.default.post(Notification(name: Notification.Name(Constants.reloadParamTableView)))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Unable to parse json
                    print("bad json")
                }
            } catch let error as NSError {
                print(error)
            }
        }
    }
}
