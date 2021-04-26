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
//  UMExtendUserSessionWorker.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol UMExtendUserSessionLogic {
    func checkUserSession(_ completion: @escaping (String?, UMAPIError?) -> Void)
    func getIdToken(_ completion: @escaping (String?, UMAPIError?) -> Void)
}

/// Called to retrieve access token for user
class UMExtendUserSessionWorker {
    
    var url: String
    let apiWorker = UMAPIWorker()
    let tokenWorker = UMTokenWorker.shared
    let apiParser = UMAPIParser()
    
    init(url: String) {
        self.url = url
    }
    
    /// Method checks for access token for user.
    /// If token is valid calls completion handler with access token string. Else calls extend user session API,
    /// and then calls completion handler with access token if successfully retrieved.
    /// Else calls completion handler with error,
    /// - Parameter completion: called after token is retrieved or error is met
    func checkUserSession(_ completion: @escaping (String?, UMAPIError?) -> Void) {
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
    private func extendSession(_ completion: @escaping (String?, UMAPIError?) -> Void) {
        if let refreshToken = tokenWorker.refreshTokenString, refreshToken.count > 0, let idToken = tokenWorker.idToken, let email = idToken.email, email.count > 0 {
            apiWorker.callAPI(endPoint: .extendSession(url: self.url, name: email, refreshToken: refreshToken), encoding: JSONEncoding.default) { data, error in
                self.apiParser.parseExtendSessionResponse(data, error: error, completion: completion)
            }
        } else {
            //No refresh token
            completion(nil, .noRefreshToken)
        }
    }
}


