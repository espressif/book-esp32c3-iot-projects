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
//  NetworkMonitor.swift
//  ESPRainMaker
//

import Foundation
import Network

/// Class to observe change in internet connectivity.
class ESPNetworkMonitor {
    static let shared = ESPNetworkMonitor()

    var isConnectedToNetwork = false
    var isConnectedToWifi = false

    private let monitor = NWPathMonitor()

    /// Set internet connectivity status based on API response.
    ///
    func setNetworkConnection(connected: Bool) {
        if isConnectedToNetwork != connected {
            isConnectedToNetwork = connected
            NotificationCenter.default.post(Notification(name: Notification.Name(Constants.networkUpdateNotification)))
        }
    }

    /// Start monitoring change in network connectivity.
    ///
    func startMonitoring() {
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)

        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.isConnectedToNetwork = true
            } else {
                self.isConnectedToNetwork = false
            }
            if path.usesInterfaceType(.wifi) {
                self.isConnectedToWifi = true
            } else {
                self.isConnectedToWifi = false
            }

            NotificationCenter.default.post(Notification(name: Notification.Name(Constants.networkUpdateNotification)))
        }
    }
}
