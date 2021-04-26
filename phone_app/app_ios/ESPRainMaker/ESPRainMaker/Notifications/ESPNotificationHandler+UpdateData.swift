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
//  ESPNotificationHandler+UpdateData.swift
//  ESPRainMaker
//

import Foundation

extension ESPNotificationHandler {
    
    // Method to update node connection status with notification payload.
    func updateData() {
        switch eventType {
        case .nodeConnected, .nodeDisconnected:
            // Gets node id from the event data.
            if let nodeId = eventData[ESPNotificationKeys.nodeIDKey] as? String, let node = User.shared.associatedNodeList?.first(where: { $0.node_id == nodeId }) {
                // Updated node status.
                node.isConnected = eventType == .nodeConnected
                if let connectivityJSON = eventData[ESPNotificationKeys.connectivityKey] as? [String:Any], let timestamp = connectivityJSON[ESPNotificationKeys.timestampKey] as? Int {
                    node.timestamp = timestamp
                }
                // Triggered local notification to let classes update their UI elements.
                NotificationCenter.default.post(Notification(name: Notification.Name(Constants.reloadCollectionView)))
                NotificationCenter.default.post(Notification(name: Notification.Name(Constants.reloadParamTableView)))
            }
        case .nodeDissassociated:
            // Triggered local notification to update device list.
            NotificationCenter.default.post(Notification(name: Notification.Name(Constants.refreshDeviceList)))
        default:
            return
        }
    }
}
