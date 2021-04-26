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
//  ESPKeychainWrappers.swift
//  ESPRainMaker
//

import Foundation

class ESPKeychainWrapper: NSObject {
    
    static let shared = ESPKeychainWrapper()
    
    /**
     Function to store a keychain item
     - parameters:
     - value: Value to store in keychain in `data` format
     - account: Account name for keychain item
     */
    func set(value: String, account: String) throws {
        // If the value exists `update the value`
        let data = Data(value.utf8)
        if try ESPKeychainOperations.shared.exists(account: account) {
            try ESPKeychainOperations.shared.update(value: data, account: account)
        } else {
            // Just insert
            try ESPKeychainOperations.shared.add(value: data, account: account)
        }
    }
    /**
     Function to retrieve an item in ´Data´ format (If not present, returns nil)
     - parameters:
     - account: Account name for keychain item
     - returns: Data from stored item
     */
    func get(account: String) throws -> String? {
        if try ESPKeychainOperations.shared.exists(account: account) {
            if let data = try ESPKeychainOperations.shared.retreive(account: account) {
                let value = String(decoding: data, as: UTF8.self)
                return value
            }
            return nil
        } else {
            throw ESPKeychainErrors.getOperationError
        }
    }
    /**
     Function to delete a single item
     - parameters:
     - account: Account name for keychain item
     */
    func delete(account: String) throws {
        if try ESPKeychainOperations.shared.exists(account: account) {
            return try ESPKeychainOperations.shared.delete(account: account)
        } else {
            throw ESPKeychainErrors.deleteOperationError
        }
    }
    /**
     Function to delete all items
     */
    func deleteAll() throws {
        try ESPKeychainOperations.shared.deleteAll()
    }
}

