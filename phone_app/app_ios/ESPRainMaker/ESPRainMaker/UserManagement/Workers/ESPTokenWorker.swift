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
//  ESPTokenWorker.swift
//  ESPRainMaker
//

import Foundation
import JWTDecode

protocol ESPTokenWorkerDelegate {
    func saveKeys(idTokenKey: String, accessTokenKey: String, refreshTokenKey: String, providerKey: String, userDetailsKey: String)
    func saveTokenData(_ data: ESPSessionResponse?)
    func save(value: Any?, key: String)
    func delete(key: String)
    func deleteAll()
    var accessTokenString: String? { get }
    var refreshTokenString: String? { get }
    var idTokenString: String? { get }
    var accessToken: AccessToken? { get }
    var idToken: IdToken? { get }
    func saveMigrationEmail(email: String)
    func deleteMigrationEmail()
    var migrationEmail: String? { get }
}

class ESPTokenWorker: ESPTokenWorkerDelegate {
    
    static let shared = ESPTokenWorker()
    
    let tokenQueue = DispatchQueue(label: "com.espressif.userToken.queue", attributes: .concurrent)
    
    private var idTokenKey = "com.espressif.idTokenKey"
    private var accessTokenKey = "com.espressif.accessTokenKey"
    private var refreshTokenKey = "com.espressif.refreshTokenKey"
    private var providerKey = "com.espressif.providerTokenKey"
    private var userDetailsKey = "com.espressif.userDetails"
    
    private let emailMigrationKey = "com.espressif.migrationEmailKey"
    
    /// Update keys for tokens
    /// - Parameters:
    ///   - idTokenKey: id token key
    ///   - accessTokenKey: access token key
    ///   - refreshTokenKey: refresh token key
    ///   - providerKey: provider token key
    ///   - userDetailsKey: user details key
    func saveKeys(idTokenKey: String,
                  accessTokenKey: String,
                  refreshTokenKey: String,
                  providerKey: String,
                  userDetailsKey: String) {
        self.idTokenKey = idTokenKey
        self.accessTokenKey = accessTokenKey
        self.refreshTokenKey = refreshTokenKey
        self.providerKey = providerKey
        self.userDetailsKey = userDetailsKey
    }
    
    /// Save extend session/login API response in keychain
    /// - Parameter data: session/login API response data
    func saveTokenData(_ data: ESPSessionResponse?) {
        //Save token data
        if let response = data, let status = response.status, status.lowercased() == "success" {
            //Token response is successful
            tokenQueue.async(flags: .barrier) {
                self.save(value: response.accessToken as Any?, key: self.accessTokenKey)
                self.save(value: response.refreshToken as Any?, key: self.refreshTokenKey)
                self.save(value: response.idToken, key: self.idTokenKey)
            }
        }
    }
    
    /// Save User detials response in keychain
    /// - Parameter data: session/login API response data
    func saveUserDetails(_ data: String?) {
        //Save token data
        if let data = data {
            //Token response is successful
            tokenQueue.async(flags: .barrier) {
                self.save(value: data as Any?, key: self.userDetailsKey)
            }
        }
    }
    
    /// Returns user details for user from keychain
    var userDetails: ESPUserDetails? {
        tokenQueue.sync {
            if let str = try? ESPKeychainWrapper.shared.get(account: self.userDetailsKey) {
                if let data = str.data(using: .utf8), let details = try? JSONDecoder().decode(ESPUserDetails.self, from: data) {
                    return details
                }
            }
            return nil
        }
    }
    
    /// Return access token string from keychain
    var accessTokenString: String? {
        tokenQueue.sync {
            do {
                if let accessToken = try ESPKeychainWrapper.shared.get(account: accessTokenKey), accessToken.count > 0, isAccessTokenValid(token: accessToken) {
                    return accessToken
                }
            } catch {
                print(error.localizedDescription)
            }
            return nil
        }
    }
    
    /// Return refresh token string from keychain
    var refreshTokenString: String? {
        tokenQueue.sync {
            do {
                if let refreshToken = try ESPKeychainWrapper.shared.get(account: refreshTokenKey), refreshToken.count > 0 {
                    return refreshToken
                }
            } catch {
                print(error.localizedDescription)
            }
            return nil
        }
    }
    
    //Get id token string from storage
    var idTokenString: String? {
        tokenQueue.sync {
            do {
                if let idTokenString = try ESPKeychainWrapper.shared.get(account: idTokenKey), idTokenString.count > 0 {
                    return idTokenString
                }
            } catch {
                print(error.localizedDescription)
            }
            return nil
        }
    }
    
    //Get id token from storage
    var idToken: IdToken? {
        tokenQueue.sync {
            if let idToken = idTokenString, idToken.count > 0, let jwt = try? decode(jwt: idToken) {
                return IdToken(jwt: jwt)
            }
            return nil
        }
    }
    
    //Get access token from storage is valid
    var accessToken: AccessToken? {
        tokenQueue.sync {
            if let accessTokenString = accessTokenString, accessTokenString.count > 0, let jwt = try? decode(jwt: accessTokenString) {
                return AccessToken(jwt: jwt)
            }
            return nil
        }
    }
    
    //Get login provider from keychain
    var provider: String? {
        tokenQueue.sync {
            if let provider = try? ESPKeychainWrapper.shared.get(account: providerKey) {
                return provider
            }
            return nil
        }
    }
    
    /// Save login provider in keychain
    /// - Parameter provider: login provider raw value
    func saveProvider(provider: String) {
        self.save(value: provider, key: self.providerKey)
    }
    
    /// Save value for key in keychain
    /// - Parameters:
    ///   - value: value to be saved
    ///   - key: corresponding key
    func save(value: Any?, key: String) {
        tokenQueue.async(flags: .barrier) {
            if let value = value as? String {
                do {
                    try ESPKeychainWrapper.shared.set(value: value, account: key)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    /// Delete value for key from keychain
    /// - Parameter key: key to be deleted
    func delete(key: String) {
        tokenQueue.async(flags: .barrier) {
            do {
                try ESPKeychainWrapper.shared.delete(account: key)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    /// Delete all values saved in keychain
    func deleteAll() {
        tokenQueue.async(flags: .barrier) {
            do {
                try ESPKeychainWrapper.shared.delete(account: self.accessTokenKey)
                try ESPKeychainWrapper.shared.delete(account: self.refreshTokenKey)
                try ESPKeychainWrapper.shared.delete(account: self.idTokenKey)
                try ESPKeychainWrapper.shared.delete(account: self.providerKey)
                try ESPKeychainWrapper.shared.delete(account: self.userDetailsKey)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    //MARK: Private Methods
    
    //Check if access token is valid or not
    private func isAccessTokenValid(token: String) -> Bool {
        if let jwt = try? decode(jwt: token), let expiryTime = jwt.expiresAt, expiryTime.timeIntervalSince(Date()) > 0 {
            return true
        }
        clearAccessToken()
        return false
    }
    
    /// Method to save email from local storage in keychain for migration
    /// - Parameter email: 3rd party email
    func saveMigrationEmail(email: String) {
        do {
            try ESPKeychainWrapper.shared.set(value: email, account: emailMigrationKey)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Delete migration email
    func deleteMigrationEmail() {
        do {
            try ESPKeychainWrapper.shared.delete(account: emailMigrationKey)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Get migration email from keychain
    var migrationEmail: String? {
        do {
            if let email = try ESPKeychainWrapper.shared.get(account: emailMigrationKey) {
                return email
            }
        } catch {
            return nil
        }
        return nil
    }
    
    //Clear access token and expiry time
    private func clearAccessToken() {
        do {
            try ESPKeychainWrapper.shared.delete(account: accessTokenKey)
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct ESPUserDetails: Codable {
    
    var userId: String?
    var userName: String?
    var superAdmin: Bool?
    var pictureUrl: String?
    var name: String?
    var mfa: Bool?
    var phoneNumber: String?
    var status: String?
    var errorCode: Int?
    var description: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case superAdmin = "super_admin"
        case pictureUrl = "picture_url"
        case name = "name"
        case mfa = "mfa"
        case phoneNumber = "phone_number"
        case status = "status"
        case errorCode = "error_code"
        case description = "description"
    }
}

/// Structure of response to login/extend session API response
struct ESPSessionResponse: Codable {
    
    var status: String?
    var errorCode: Int?
    var description: String?
    var idToken: String?
    var accessToken: String?
    var refreshToken: String?
    
    var gotAccessToken: Bool {
        if let status = status, status.lowercased() == "success", let accessToken = accessToken, accessToken.count > 0 {
            return true
        }
        return false
    }
    
    enum CodingKeys: String, CodingKey {
        case status, description
        case errorCode = "error_code"
        case idToken = "idtoken"
        case accessToken = "accesstoken"
        case refreshToken = "refreshtoken"
    }
}

/// Decoded access token
struct AccessToken {
    
    var sub: String?
    var eventId: String?
    var tokenUse: String?
    var scope: String?
    var authTime: Date?
    var iss: String?
    var exp: Date?
    var iat: Date?
    var jti: String?
    var clientId: String?
    var username: String?
    
    init(jwt: JWT) {
        sub = jwt.subject
        eventId = jwt.event_id
        tokenUse = jwt.token_use
        scope = jwt.scope
        authTime = jwt.auth_time
        iss = jwt.issuer
        exp = jwt.expiresAt
        iat = jwt.issuedAt
        jti = jwt.jti
        clientId = jwt.client_id
        username = jwt.username
    }
}

/// Decoded Id token
struct IdToken {
    
    var sub: String?
    var emailVerified: Bool?
    var customMaintainer: String?
    var customAdmin: String?
    var iss: String?
    var customUserId: String?
    var cognitoUsername: String?
    var aud: String?
    var eventId: String?
    var tokenUse: String?
    var authTime: Date?
    var exp: Date?
    var iat: Date?
    var email: String?
    
    init(jwt: JWT) {
        sub = jwt.subject
        emailVerified = jwt.email_verified
        customMaintainer = jwt.customMaintainer
        customAdmin = jwt.customAdmin
        iss = jwt.issuer
        customUserId = jwt.customUserId
        cognitoUsername = jwt.cognitoUsername
        aud = jwt.audience?.last
        eventId = jwt.event_id
        tokenUse = jwt.token_use
        authTime = jwt.auth_time
        exp = jwt.expiresAt
        iat = jwt.issuedAt
        email = jwt.email
    }
}

extension JWT {
    
    var event_id: String? {
        return self.body["event_id"] as? String
    }
    var token_use: String? {
        return self.body["token_use"] as? String
    }
    var scope: String? {
        return self.body["scope"] as? String
    }
    var auth_time: Date? {
        if let auth_time = self.body["auth_time"] as? Int, auth_time > 0 {
            return Date(timeIntervalSince1970: TimeInterval(auth_time))
        }
        return nil
    }
    var jti: String? {
        return self.body["jti"] as? String
    }
    var client_id: String? {
        return self.body["client_id"] as? String
    }
    var username: String? {
        return self.body["username"] as? String
    }
    var email_verified: Bool? {
        return self.body["email_verified"] as? Bool
    }
    var customMaintainer: String? {
        return self.body["custom:maintainer"] as? String
    }
    var customAdmin: String? {
        return self.body["custom:maintainer"] as? String
    }
    var customUserId: String? {
        return self.body["custom:user_id"] as? String
    }
    var cognitoUsername: String? {
        return self.body["cognito:username"] as? String
    }
    var email: String? {
        return self.body["email"] as? String
    }
}
