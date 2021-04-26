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
//  UserInfo.swift
//  ESPRainMaker
//

import Foundation
import JWTDecode

enum ServiceProvider: String {
    case other
    case cognito
}

struct UserInfo {
    // UserInfo keys
    static let usernameKey = "username"
    static let emailKey = "email"
    static let userIdKey = "userID"
    static let providerKey = "provider"

    var username: String
    var email: String
    var userID: String
    var loggedInWith: ServiceProvider

    /// Create UserInfo object derived from persistent storage
    ///
    /// - Returns:
    ///   - Userinfo object that contains information about the currently signed-in user
    static func getUserInfo() -> UserInfo {
        var userInfo = UserInfo(username: "", email: "", userID: "", loggedInWith: .cognito)
        if let idToken = ESPTokenWorker.shared.idTokenString, let json = try? decode(jwt: idToken) {
            userInfo.username = json.cognitoUsername ?? ""
            userInfo.email = json.email ?? ""
            userInfo.userID = json.customUserId ?? ""
            if let loggedInWith = ESPTokenWorker.shared.provider {
                userInfo.loggedInWith = ServiceProvider(rawValue: loggedInWith)!
            }
        }
        return userInfo
    }

    /// Save Userinfo of currently signed-in user into persistent storage.
    /// This info is required when new app session is started.
    ///
    func saveUserInfo() {
        ESPTokenWorker.shared.saveProvider(provider: loggedInWith.rawValue)
    }
}
