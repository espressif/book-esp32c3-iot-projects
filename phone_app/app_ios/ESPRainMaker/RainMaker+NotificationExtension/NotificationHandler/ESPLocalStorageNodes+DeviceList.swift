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
//  ESPLocalStorage+DeviceList.swift
//  ESPRainMaker
//

import Foundation

extension ESPLocalStorageNodes {
    // Gives user nodes and devices linked with it in form of a dictionary.
    func getDeviceListDictionary() -> [String:[String]]? {
        if let nodes = fetchNodeDetails() {
            var nodeDictionary:[String:[String]] = [:]
            for node in nodes {
                let array = node.devices?.compactMap({ $0.deviceName })
                nodeDictionary[node.node_id ?? ""] = array
            }
            return nodeDictionary
        }
        return nil
    }
}
