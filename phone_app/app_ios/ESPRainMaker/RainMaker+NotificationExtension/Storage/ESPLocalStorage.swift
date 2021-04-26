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
//  ESPLocalStorage.swift
//  ESPRainMaker
//

import Foundation

// Class that manages the local storage in the app.
class ESPLocalStorage: ESPLocalStorageProtocol {
    
    // Shared user defaults.
    let sharedUserDefaults: UserDefaults?
    
    init(_ suiteName: String?) {
        sharedUserDefaults = UserDefaults(suiteName: suiteName)
    }
    
    /// Method to save data in shared user default.
    ///
    /// - Parameters:
    ///   - data: Data that needs to be saved.
    ///   - key: Key against which data will be stored.
    func saveDataInUserDefault(data: Data, key: String) {
        sharedUserDefaults?.setValue(data, forKey: key)
    }
    
    /// Method to get data from shared user default.
    ///
    /// - Parameters:
    ///   - key: Key against which data is stored.
    /// - Returns: Data.
    func getDataFromSharedUserDefault(key: String) -> Data? {
        return sharedUserDefaults?.object(forKey: key) as? Data
    }
    
    /// Method to clean up data for a particular key.
    ///
    /// - Parameters:
    ///   - forKey: Key for which data will cleaned up.
    func cleanupData(forKey: String) {
        sharedUserDefaults?.removeObject(forKey: forKey)
    }
}
