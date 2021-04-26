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
//  ESPLocalStorageNodes.swift
//  ESPRainMaker
//

import Foundation

protocol ESPNodesStorageProtocol {
    func saveNodeDetails(nodes: [Node]?)
    func fetchNodeDetails() -> [Node]?
    func cleanupNodeDetails()
}

class ESPLocalStorageNodes: ESPLocalStorage, ESPNodesStorageProtocol {
    
    /// Method to save node details of an user locally.
    ///
    /// - Parameters:
    ///   - nodes: List of user nodes.
    func saveNodeDetails(nodes: [Node]?) {
        if let nodeList = nodes {
            do {
                let encoded = try JSONEncoder().encode(nodeList)
                saveDataInUserDefault(data: encoded, key: ESPLocalStorageKeys.nodeDetails)
            } catch  {
                print(error)
            }
        }
    }

    /// Method to fetch locally stored node details for current user.
    ///
    /// - Returns: Array of user associated nodes.
    func fetchNodeDetails() -> [Node]? {
        if let nodeDetailsData = getDataFromSharedUserDefault(key: ESPLocalStorageKeys.nodeDetails) {
            do {
                var nodes: [Node] = []
                nodes = try JSONDecoder().decode([Node].self, from: nodeDetailsData)
                return nodes
            } catch {
                return nil
            }
        }
        return nil
    }
    
    /// Method to clean up all node details.
    func cleanupNodeDetails() {
        cleanupData(forKey: ESPLocalStorageKeys.nodeDetails)
    }
    
}
