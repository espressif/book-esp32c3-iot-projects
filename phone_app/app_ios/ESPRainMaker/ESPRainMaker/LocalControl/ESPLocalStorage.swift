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
//  ESPLocalStorage.swift
//  ESPRainMaker
//

import Foundation

/// Class to manage persistent storage of user node details
class ESPLocalStorage {
    static let shared = ESPLocalStorage()

    /// Method to save current node groups information locally
    ///
    func saveNodeGroupInfo() {
        do {
            let encoded = try JSONEncoder().encode(NodeGroupManager.shared.nodeGroup)
            UserDefaults.standard.setValue(encoded, forKey: Constants.nodeGroups)
        } catch {
            print(error)
        }
    }

    /// Method to fetch locally stored node group information for current user.
    ///
    /// - Returns: Array of node groups.
    func fetchNodeGroups() -> [NodeGroup] {
        var groupsList: [NodeGroup] = []
        do {
            if let groupData = UserDefaults.standard.object(forKey: Constants.nodeGroups) as? Data {
                groupsList = try JSONDecoder().decode([NodeGroup].self, from: groupData)
            }
            return groupsList
        } catch {
            print(error)
            return groupsList
        }
    }

    /// Method to save current schedule information locally
    ///
    func saveSchedules() {
        do {
            let encoded = try JSONEncoder().encode(ESPScheduler.shared.schedules)
            UserDefaults.standard.setValue(encoded, forKey: Constants.scheduleDetails)
        } catch {
            print(error)
        }
    }

    /// Method to fetch locally stored schedule information for current user.
    ///
    /// - Returns: Dictionary of schedules with unique id as key.
    func fetchSchedules() -> [String: ESPSchedule] {
        var scheduleList: [String: ESPSchedule] = [:]
        do {
            if let scheduleData = UserDefaults.standard.object(forKey: Constants.scheduleDetails) as? Data {
                scheduleList = try JSONDecoder().decode([String: ESPSchedule].self, from: scheduleData)
            }
            return scheduleList
        } catch {
            print(error)
            return scheduleList
        }
    }

    /// Method to save node details of an user locally.
    ///
    /// - Parameters:
    ///   - nodes: List of user nodes.
    func saveNodeDetails(nodes: [Node]?) {
        if let nodeList = nodes {
            let encoded = try! JSONEncoder().encode(nodeList)
            UserDefaults.standard.setValue(encoded, forKey: Constants.nodeDetails)
        }
    }

    /// Method to fetch locally stored node details for current user.
    ///
    /// - Returns: Array of user associated nodes.
    func fetchNodeDetails() -> [Node]? {
        if let nodeDetailsData = UserDefaults.standard.object(forKey: Constants.nodeDetails) as? Data {
            do {
                var nodes: [Node] = []
                nodes = try JSONDecoder().decode([Node].self, from: nodeDetailsData)
                for node in nodes {
                    if User.shared.localServices.keys.contains(node.node_id ?? "") {
                        node.localNetwork = true
                    }
                }
                // Fetch schedule details if it is supported
                if Configuration.shared.appConfiguration.supportSchedule {
                    ESPScheduler.shared.schedules = fetchSchedules()
                    ESPScheduler.shared.getAvailableDeviceWithScheduleCapability(nodeList: nodes)
                }
                return nodes
            } catch {
                return nil
            }
        }
        return nil
    }
}
