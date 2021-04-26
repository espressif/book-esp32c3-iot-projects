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
//  ESPNodeAlertEvent.swift
//  ESPRainMaker
//

import Foundation

// Class associated with node alert event.
class ESPNodeAlertEvent: ESPNotificationEvent {
    /// Modifies notification content to display alert message from node.
    ///
    /// - Returns: Modified notification object.
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        modifiedNotification.body = "Alert received from a device."
        // Gets message body of node alert from the payload.
        if let messageBody = eventData[ESPNotificationKeys.messageBodyKey] as? String {
            let data = messageBody.data(using: .utf8)!
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                    // Checks if alert key is present.
                    if let alertString = json["esp.alert.str"] as? String {
                        // Notification body will have value of the alert key.
                        modifiedNotification.body = alertString
                    } else {
                        // Gets node id from the event data.
                        if let nodeId = eventData[ESPNotificationKeys.nodeIDKey] as? String {
                            // Created message body from device parameter reported in the alert.
                            let node = ESPLocalStorageNodes(ESPLocalStorageKeys.suiteName).getNode(nodeID: nodeId)
                            if let modifiedMessage = createNotificationMessageFrom(node: node, json: json) {
                                modifiedNotification.body = modifiedMessage
                            }
                        }
                    }
                }
            }
            catch {
               print(error)
               return modifiedNotification
            }
        }
        // Saves notification in local storage.
        notificationStore.storeESPNotification(notification: modifiedNotification)
        // Returns modified notification.
        return modifiedNotification
    }
    
    
    private func createNotificationMessageFrom(node: Node?, json: [String: Any]) -> String? {
        var reportedParams:[String] = []
        for key in json.keys {
            // Gets device for which alert is received.
            let device = node?.devices?.first(where: { $0.name == key})
            if let reportedJSON = json[key] as? [String: Any] {
                for paramKey in reportedJSON.keys {
                    var paramValue:String?
                    let deviceParam = device?.params?.first(where: { $0.name == paramKey})
                    // Check data type for the value received in the alert.
                    switch deviceParam?.dataType?.lowercased() {
                    case "int":
                        if let intParam = reportedJSON[paramKey] as? Int {
                            paramValue = "\(intParam)"
                        }
                    case "bool":
                        if let boolParam = reportedJSON[paramKey] as? Bool {
                            paramValue = boolParam ? "true":"false"
                        }
                    case "float":
                        if let floatParam = reportedJSON[paramKey] as? Float {
                            paramValue = "\(floatParam)"
                        }
                    case "string":
                        if let stringParam = reportedJSON[paramKey] as? String {
                            paramValue = stringParam
                        }
                    default:
                        if let intParam = reportedJSON[paramKey] as? Int {
                            paramValue = "\(intParam)"
                        } else if let boolParam = reportedJSON[paramKey] as? Bool {
                            paramValue = "\(boolParam)"
                        } else if let floatParam = reportedJSON[paramKey] as? Float {
                            paramValue = "\(floatParam)"
                        } else if let stringParam = reportedJSON[paramKey] as? String {
                            paramValue = stringParam
                        }
                    }
                    if let paramString = paramValue {
                        reportedParams.append("\(device?.deviceName ?? key) reported \(paramKey): \(paramString).")
                    }
                }
            }
        }
        if reportedParams.count > 0 {
            return reportedParams.joined(separator: " ")
        }
        return nil
    }
}
