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
//  ESPLogoutService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPLogoutLogic {
    func logoutUser()
}

class ESPLogoutService: ESPLogoutLogic {
    
    var url: String
    var apiWorker: ESPAPIWorker
    var apiParser: ESPAPIParser
    
    var presenter: ESPLogoutUserPresentationLogic?
    
    convenience init(presenter: ESPLogoutUserPresentationLogic? = nil) {
        self.init(url: ESPURLParams.shared.baseURL,
                  apiWorker: ESPAPIWorker(),
                  apiParser: ESPAPIParser(),
                  presenter: presenter)
    }
    
    private init(url: String,
                 apiWorker: ESPAPIWorker,
                 apiParser: ESPAPIParser,
                 presenter: ESPLogoutUserPresentationLogic?) {
        self.url = url
        self.apiWorker = apiWorker
        self.apiParser = apiParser
        self.presenter = presenter
    }
    
    /// Logout user
    func logoutUser() {
        apiWorker.callAPI(endPoint: .logoutUser(url: self.url), encoding: JSONEncoding.default) { data, error in
            self.apiParser.parseResponse(data, withError: error) { umError in
                self.presenter?.userLoggedOut(withError: umError)
            }
        }
    }
}
