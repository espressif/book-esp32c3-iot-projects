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
//  ESPLocalStorageNodeGroups.swift
//  ESPRainMaker
//

import Foundation

// Protocol for managing local storage of user created node groups.
protocol ESPNodeGroupsStorageProtocol {
    func saveNodeGroups(_ nodeGroups: [NodeGroup])
    func fetchNodeGroups() -> [NodeGroup]?
    func cleanupNodeGroups()
}

class ESPLocalStorageNodeGroups: ESPLocalStorage, ESPNodeGroupsStorageProtocol {
    
    /// Method to store array of node groups locally.
    ///
    /// - Parameters:
    ///   - nodeGroups: User created node groups.
    func saveNodeGroups(_ nodeGroups: [NodeGroup]) {
        do {
            let encoded = try JSONEncoder().encode(nodeGroups)
            UserDefaults.standard.setValue(encoded, forKey: ESPLocalStorageKeys.nodeGroups)
        } catch {
            print(error)
        }
    }
    
    /// Method to fetch locally stored node groups of current user.
    ///
    /// - Returns: Array of node groups.
    func fetchNodeGroups() -> [NodeGroup]? {
        var groupsList: [NodeGroup] = []
        do {
            if let groupData = UserDefaults.standard.object(forKey: ESPLocalStorageKeys.nodeGroups) as? Data {
                groupsList = try JSONDecoder().decode([NodeGroup].self, from: groupData)
            }
            return groupsList
        } catch {
            print(error)
            return groupsList
        }
    }
    
    // Method to clean all node groups information from local storage.
    func cleanupNodeGroups() {
        cleanupData(forKey: ESPLocalStorageKeys.nodeGroups)
    }
}
