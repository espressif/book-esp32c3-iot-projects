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
//  ESPExtendUserSessionWorker.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPExtendUserSessionLogic {
    func checkUserSession(_ completion: @escaping (String?, ESPAPIError?) -> Void)
    func getIdToken(_ completion: @escaping (String?, ESPAPIError?) -> Void)
}

/// Called to retrieve access token for user
class ESPExtendUserSessionWorker {
    
    let url: String = ESPURLParams.shared.baseURL
    let apiWorker: ESPAPIWorker = ESPAPIWorker()
    let tokenWorker = ESPTokenWorker.shared
    let apiParser: ESPAPIParser = ESPAPIParser()
    
    /// Method checks for access token for user.
    /// If token is valid calls completion handler with access token string. Else calls extend user session API,
    /// and then calls completion handler with access token if successfully retrieved.
    /// Else calls completion handler with error,
    /// - Parameter completion: called after token is retrieved or error is met
    func checkUserSession(_ completion: @escaping (String?, ESPAPIError?) -> Void) {
        guard let accessToken = tokenWorker.accessTokenString, accessToken.count > 0 else {
            self.extendSession() { accessToken, umError in
                completion(accessToken, umError)
            }
            return
        }
        completion(accessToken, nil)
    }
    
    /// Check for refresh token, call extend session API and return token/error via completion handler
    /// - Parameter completion: called after token is retrieved or error is met
    private func extendSession(_ completion: @escaping (String?, ESPAPIError?) -> Void) {
        if let refreshToken = tokenWorker.refreshTokenString, refreshToken.count > 0 {
            var mail = ""
            if let email = tokenWorker.migrationEmail, email.count > 0 {
                mail = email
            } else if let idToken = tokenWorker.idToken, let email = idToken.email, email.count > 0 {
                mail = email
            }
            if mail.count > 0 {
                apiWorker.callAPI(endPoint: .extendSession(url: self.url, name: mail, refreshToken: refreshToken), encoding: JSONEncoding.default) { data, error in
                    self.apiParser.parseExtendSessionResponse(data, error: error, completion: completion)
                }
            } else {
                completion(nil, .noRefreshToken)
            }
        } else {
            //No refresh token
            completion(nil, .noRefreshToken)
        }
    }
}


