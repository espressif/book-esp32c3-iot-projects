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
//  ESPAlexaTokenWorker.swift
//  ESPRainMaker
//

import Foundation

/// Class to store and retrieve Alexa tokens
class ESPAlexaTokenWorker {
    
    static let shared = ESPAlexaTokenWorker()
    
    private let accessTokenKey = "com.alexa.accessToken"
    private let refreshTokenKey = "com.alexa.refreshToken"
    private let expiresInKey = "com.alexa.expiresIn"
    private let tokenTypeKey = "com.alexa.tokenType"
    
    private let urlEndPointsKey = "com.alexa.urlEndPointsKey"
    
    /// Save alexa tokens in user defaults
    /// - Parameter data: Alexa resoponse with tokens
    func saveTokens(data: ESPAlexaResponse) {
        if let val = data.accessToken {
            UserDefaults.standard.set(val, forKey: accessTokenKey)
        }
        if let val = data.refreshToken {
            UserDefaults.standard.set(val, forKey: refreshTokenKey)
        }
        if let val = data.tokenType {
            UserDefaults.standard.set(val, forKey: tokenTypeKey)
        }
        if let val = data.expiresIn {
            let date = Date()
            let expiresIn = Int(date.timeIntervalSince1970) + val
            UserDefaults.standard.set(expiresIn, forKey: expiresInKey)
        }
    }
    
    /// Get AlexaResponse object from UserDefaults
    /// - Returns: AlexaResponse object
    private func getAlexaToken() -> ESPAlexaResponse {
        let accessToken = UserDefaults.standard.value(forKey: accessTokenKey) as? String
        let refreshToken = UserDefaults.standard.value(forKey: refreshTokenKey) as? String
        let expiresIn = UserDefaults.standard.value(forKey: expiresInKey) as? Int
        let tokenType = UserDefaults.standard.value(forKey: tokenTypeKey) as? String
        let value = ESPAlexaResponse(accessToken: accessToken,
                                 refreshToken: refreshToken,
                                 expiresIn: expiresIn,
                                 tokenType: tokenType)
        return value
    }
    
    /// Get Alexa access token if it's not expired
    var getAccessToken: String? {
        let val = self.getAlexaToken()
        if let _ = val.expiresIn {
            let expiresIn = Double(val.expiresIn!)
            let timeIntercalSince = Date().timeIntervalSince1970
            if expiresIn - timeIntercalSince > 0 {
                return val.accessToken
            } else {
                self.clearAccessToken()
            }
        }
        return nil
    }
    
    /// Get Alexa refresh token
    var getRefreshToken: String? {
        let val = self.getAlexaToken()
        if let refreshToken = val.refreshToken {
            return refreshToken
        }
        return nil
    }
    
    /// Save Alexa URL endpoints in UserDefaults
    /// - Parameter data: AlexaEndpoints object
    func saveEndPoints(data: ESPAlexaEndpoints) {
        if let endpoints = data.endPoints, endpoints.count > 0 {
            UserDefaults.standard.set(endpoints, forKey: urlEndPointsKey)
        }
    }
    
    /// Get Alexa URL endpoints from UserDefaults
    var getAlexaURLEndPoints: [String]? {
        if let alexaEndPoints = UserDefaults.standard.value(forKey: urlEndPointsKey) as? [String] {
            return alexaEndPoints
        }
        return nil
    }
    
    /// Clear Alexa access token
    func clearAccessToken() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
    }
    
    /// Clear Alexa URL endpoints
    func clearAlexaURLEndpoints() {
        UserDefaults.standard.removeObject(forKey: urlEndPointsKey)
    }
    
    /// Clear all Alexa tokens and endpoints
    func clearAllClientTokens() {
        clearAlexaURLEndpoints()
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: expiresInKey)
        UserDefaults.standard.removeObject(forKey: tokenTypeKey)
    }
}

struct ESPAlexaResponse: Codable {
    
    var accessToken: String?
    var refreshToken: String?
    var expiresIn: Int?
    var tokenType: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}


struct ESPAlexaEndpoints: Codable {
    
    var endPoints: [String]?
    var message: String?
    
    enum CodingKeys: String, CodingKey {
        case endPoints = "endpoints"
    }
}

struct ESPAlexaEnablementMessage: Codable {
    
    var message: String?
}


// MARK: - Welcome
struct ESPAlexaWelcome: Codable {
    let skill: ESPAlexaSkill?
    let user: ESPAlexaUser?
    let accountLink: ESPAlexaAccountLink?
    let status: String?
    let message: String?
}

// MARK: - AccountLink
struct ESPAlexaAccountLink: Codable {
    let status: String?
}

// MARK: - Skill
struct ESPAlexaSkill: Codable {
    let stage, id: String?
}

// MARK: - User
struct ESPAlexaUser: Codable {
    let id: String?
}

