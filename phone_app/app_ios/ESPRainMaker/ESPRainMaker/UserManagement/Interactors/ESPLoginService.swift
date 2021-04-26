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
//  ESPLoginService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPLoginLogic {
    func loginUser(name: String, password: String)
}

class ESPLoginService: ESPLoginLogic {
    
    var url: String
    var apiWorker: ESPAPIWorker
    var apiParser: ESPAPIParser
    
    var presenter: ESPLoginPresentationLogic?
    
    convenience init(presenter: ESPLoginPresentationLogic? = nil) {
        self.init(url: ESPURLParams.shared.baseURL,
                  apiWorker: ESPAPIWorker(),
                  apiParser: ESPAPIParser(),
                  presenter: presenter)
    }
    
    private init(url: String,
                 apiWorker: ESPAPIWorker,
                 apiParser: ESPAPIParser,
                 presenter: ESPLoginPresentationLogic? = nil) {
        self.url = url
        self.apiWorker = apiWorker
        self.apiParser = apiParser
        self.presenter = presenter
    }
    
    /// Login user API
    /// - Parameters:
    ///   - name: user name
    ///   - password: password
    func loginUser(name: String, password: String) {
        apiWorker.callAPI(endPoint: .loginUser(url: self.url, name: name, password: password), encoding: JSONEncoding.default) { data, error in
            self.apiParser.parseExtendSessionResponse(data, error: error) { _, umError in
                self.presenter?.loginCompleted(withError: umError)
            }
        }
    }
}



