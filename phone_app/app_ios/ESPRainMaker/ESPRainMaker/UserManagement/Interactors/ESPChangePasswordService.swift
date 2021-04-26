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
//  ESPChangePasswordService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPChangePasswordLogic {
    func changePassword(oldPassword: String, newPassword: String)
}

class ESPChangePasswordService: ESPChangePasswordLogic, ESPNoRefreshTokenLogic {
    
    var url: String = ESPURLParams.shared.baseURL
    var apiWorker: ESPAPIWorker = ESPAPIWorker()
    var apiParser: ESPAPIParser = ESPAPIParser()
    var sessionWorker: ESPExtendUserSessionWorker = ESPExtendUserSessionWorker()
    
    var presenter: ESPChangePasswordPresentationLogic?
    
    convenience init(presenter: ESPChangePasswordPresentationLogic? = nil) {
        self.init(url: ESPURLParams.shared.baseURL,
                  apiWorker: ESPAPIWorker(),
                  apiParser: ESPAPIParser(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    private init(url: String,
                 apiWorker: ESPAPIWorker,
                 apiParser: ESPAPIParser,
                 sessionWorker: ESPExtendUserSessionWorker,
                 presenter: ESPChangePasswordPresentationLogic?) {
        self.url = url
        self.apiWorker = apiWorker
        self.apiParser = apiParser
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    /// Change user password
    /// - Parameters:
    ///   - oldPassword: old password
    ///   - newPassword: new password
    func changePassword(oldPassword: String, newPassword: String) {
        sessionWorker.checkUserSession() { accessToken, sessionError in
            if let token = accessToken {
                self.apiWorker.callAPI(endPoint: .changePassword(url: self.url, old: oldPassword, new: newPassword, accessToken: token), encoding: JSONEncoding.default) { data, error in
                    self.apiParser.parseResponse(data, withError: error) { umError in
                        self.presenter?.passwordChanged(withError: umError)
                    }
                }
            } else {
                if !self.apiParser.isRefreshTokenValid(serverError: sessionError) {
                    if let error = sessionError {
                        self.noRefreshSignOutUser(error: error)
                    }
                } else {
                    self.presenter?.passwordChanged(withError: sessionError)
                }
            }
        }
    }
}
