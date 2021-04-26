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
//  ESPUserService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPUserLogic {
    
    func updateUserName(name: String)
    func fetchUserDetails()
}

class ESPUserService: ESPUserLogic {
    
    var url: String
    var apiParser: ESPAPIParser
    var apiWorker: ESPAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    
    var presenter: ESPUserPresentationLogic?
    
    convenience init(presenter: ESPUserPresentationLogic? = nil) {
        self.init(url: ESPURLParams.shared.baseURL,
                  apiParser: ESPAPIParser(),
                  apiWorker: ESPAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    private init(url: String,
         apiParser: ESPAPIParser,
         apiWorker: ESPAPIWorker,
         sessionWorker: ESPExtendUserSessionWorker,
         presenter: ESPUserPresentationLogic? = nil) {
        self.url = url
        self.apiParser = apiParser
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    //TODO: to be added when update user name feature is added in app
    /// Update user name
    /// - Parameter name: new user name
    func updateUserName(name: String) {
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken, token.count > 0 {
                self.apiWorker.callAPI(endPoint: .updateUsername(url: self.url, name: name, accessToken: token), encoding: JSONEncoding.default) {
                    data, error in
                    
                }
            }
            
        }
    }
    
    /// Fetch user details
    func fetchUserDetails() {
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken, token.count > 0 {
                self.apiWorker.callAPI(endPoint: .fetchUserDetails(url: self.url, accessToken: token), encoding: JSONEncoding.default) {
                    data, error in
                    self.apiParser.parseUserDetailsResponse(data, withError: error) { umError in
                        self.presenter?.userDetailsFetched(error: umError)
                        return
                    }
                }
            } else {
                self.presenter?.userDetailsFetched(error: error)
            }
        }
    }

}
