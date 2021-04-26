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
//  ESPConfiguration.swift
//  ESPRainMaker
//

import Foundation

class ESPConfiguration {
    
    var appGroupID:String!
    
    init() {
        guard let configDictionary = getCustomPlist() else {
            fatalError("Configuration.plist file is not present. Please check the documents for more information.")
        }
        appGroupID = configDictionary["App Group"] as? String ?? ""
    }
    
    func getCustomPlist() -> [String: Any]? {
        if let path = Bundle.main.path(forResource: "Configuration", ofType: "plist") {
            do {
                let url = URL(fileURLWithPath: path)
                let data = try Data(contentsOf: url)
                if let configPlist = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: Any] {
                    return configPlist
                }
            } catch {
                return nil
            }
        }
        return nil
    }
}
