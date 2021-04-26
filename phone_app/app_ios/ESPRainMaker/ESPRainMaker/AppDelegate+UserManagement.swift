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
//  AppDelegate+UserManagement.swift
//  ESPRainMaker
//

import Foundation

extension AppDelegate: ESPServerTokenProtocol {
    
    // MARK: - Server Trust and URL Configuration
    
    /// Set server trust params for SSL pinning
    func setServerParams() {
        ESPServerTrustParams.shared.setParams(fileName: "amazonRootCA",
         baseURLDomain: Configuration.shared.awsConfiguration.baseURL.getDomain(),
         authURLDomain: Configuration.shared.awsConfiguration.authURL.getDomain(),
         claimURLDomain: Configuration.shared.awsConfiguration.claimURL.getDomain())
        
        ESPURLParams.shared.setURLs(baseURL: Configuration.shared.getAWSBaseURL(),
            authURL: Configuration.shared.awsConfiguration.authURL,
            redirectURL: Configuration.shared.awsConfiguration.redirectURL,
            appClientID: Configuration.shared.awsConfiguration.appClientId)
    }
    
    /// Set keys for id, access and refresh token keys
    func setESPTokenKeys() {
        ESPTokenWorker.shared.saveKeys(idTokenKey: Constants.idTokenKey,
                                       accessTokenKey: Constants.accessTokenKey,
                                       refreshTokenKey: Constants.refreshTokenKey,
                                       providerKey: Constants.providerKey,
                                       userDetailsKey: Constants.userDetailsKey)
    }
    
    /*
     Migrate from app store app to current version.
     If 3rd party login is used, then refresh token will be moved from UserDefaults,
     to keychain and then it will be used to fetch new user access token.
     */
    func migrateCode() {
        if let data = UserDefaults.standard.value(forKey: Constants.refreshTokenKey) as? [String: Any], let refreshToken = data["token"] {
            ESPTokenWorker.shared.save(value: refreshToken as Any, key: Constants.refreshTokenKey)
            ESPTokenWorker.shared.saveProvider(provider: ServiceProvider.other.rawValue)
            if let json = UserDefaults.standard.value(forKey: Constants.userInfoKey) as? [String: Any], let email = json[UserInfo.emailKey] as? String, email.count > 0 {
                ESPTokenWorker.shared.saveMigrationEmail(email: email)
                UserDefaults.standard.removeObject(forKey: Constants.userInfoKey)
            }
            UserDefaults.standard.removeObject(forKey: Constants.refreshTokenKey)
        }
    }
}
