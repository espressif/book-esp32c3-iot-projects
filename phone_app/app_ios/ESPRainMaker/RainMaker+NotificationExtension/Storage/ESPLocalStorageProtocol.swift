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
//  ESPLocalStorageProtocol.swift
//  ESPRainMaker
//

import Foundation

struct ESPLocalStorageKeys {
    static let suiteName = ESPConfiguration().appGroupID
    static let nodeDetails = "com.espressif.node.details"
    static let notificationStore = "com.espressif.notifications.store"
}

protocol ESPLocalStorageProtocol {
    func saveDataInUserDefault(data: Data, key: String)
    func getDataFromSharedUserDefault(key: String) -> Data?
    func cleanupData(forKey: String)
}
