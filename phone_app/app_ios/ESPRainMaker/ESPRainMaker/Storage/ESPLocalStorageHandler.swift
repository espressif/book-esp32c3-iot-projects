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
//  ESPLocalStorageHandler.swift
//  ESPRainMaker
//

import Foundation

extension ESPLocalStorageKeys {
    static let scheduleDetails = "com.espressif.schedule.details"
    static let nodeGroups = "com.espressif.node.groups"
}

/// Class to manage persistent storage of user data
struct ESPLocalStorageHandler: ESPNodesStorageProtocol, ESPSchedulesStorageProtocol, ESPNodeGroupsStorageProtocol, ESPNotificationsStoreProtocol {

    let scheduleHandler = ESPLocalStorageSchedules(nil)
    // Initiates handlers for shared local storage.
    let nodesHandler = ESPLocalStorageNodes(ESPLocalStorageKeys.suiteName)
    let nodeGroupHandler = ESPLocalStorageNodeGroups(ESPLocalStorageKeys.suiteName)
    let notificationHandler = ESPNotificationsStore(ESPLocalStorageKeys.suiteName)
    
    // Check saveNodeDetails: of ESPLocalStorageNodes.
    func saveNodeDetails(nodes: [Node]?) {
        nodesHandler.saveNodeDetails(nodes: nodes)
    }

    /// Method to fetch locally stored node details for current user.
    ///
    /// - Returns: Array of user associated nodes.
    func fetchNodeDetails() -> [Node]? {
        var nodes:[Node]?
        nodes = nodesHandler.fetchNodeDetails()
        for node in nodes ?? [] {
            if User.shared.localServices.keys.contains(node.node_id ?? "") {
                node.localNetwork = true
            }
        }
        // Fetch schedule details if it is supported
        if Configuration.shared.appConfiguration.supportSchedule {
            ESPScheduler.shared.schedules = fetchSchedules()
            ESPScheduler.shared.getAvailableDeviceWithScheduleCapability(nodeList: nodes ?? [])
        }
        return nodes
    }
    
    // Check saveSchedules: of ESPLocalStorageSchedules.
    func saveSchedules(schedules: [String : ESPSchedule]) {
        scheduleHandler.saveSchedules(schedules: schedules)
    }
    
    // Check fetchSchedules: of ESPLocalStorageSchedules.
    func fetchSchedules() -> [String : ESPSchedule] {
        scheduleHandler.fetchSchedules()
    }
    
    // Check cleanupSchedules: of ESPLocalStorageSchedules.
    func cleanupSchedules() {
        scheduleHandler.cleanupSchedules()
    }
    
    // Check cleanupNodeDetails: of ESPLocalStorageNodes.
    func cleanupNodeDetails() {
        nodesHandler.cleanupNodeDetails()
    }
    
    // Cleans all locally stored information like node details, node groups, etc. for current user.
    func cleanupData() {
        cleanupSchedules()
        cleanupNodeDetails()
        cleanupNodeGroups()
        cleanupNotifications()
    }
    
    // Check saveNodeGroups: of ESPLocalStorageNodeGroups.
    func saveNodeGroups(_ nodeGroups: [NodeGroup]) {
        nodeGroupHandler.saveNodeGroups(nodeGroups)
    }
    
    // Check fetchNodeGroups: of ESPLocalStorageNodeGroups.
    func fetchNodeGroups() -> [NodeGroup]? {
        return nodeGroupHandler.fetchNodeGroups()
    }
    
    // Check cleanupNodeGroups of ESPLocalStorageNodeGroups.
    func cleanupNodeGroups() {
        nodeGroupHandler.cleanupNodeGroups()
    }
    
    // Check getDeliveredESPNotifications of ESPNotificationsStore.
    func getDeliveredESPNotifications() -> [ESPNotifications]? {
        return notificationHandler.getDeliveredESPNotifications()
    }
    
    // Check storeESPNotification: of ESPNotificationsStore.
    func storeESPNotification(notification: ESPNotifications) {
        notificationHandler.storeESPNotification(notification: notification)
    }
    
    // Check cleanupNotifications of ESPNotificationsStore.
    func cleanupNotifications() {
        notificationHandler.cleanupNotifications()
    }
}
