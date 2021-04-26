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
//  ESPCreateUserService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPCreateUserLogic {
    func createNewUser(name: String, password: String) //POST
    func confirmUser(name: String, verificationCode: String) //POST
}

class ESPCreateUserService: ESPCreateUserLogic {
    
    var url: String
    var apiWorker: ESPAPIWorker
    var apiParser: ESPAPIParser
    
    var presenter: ESPCreateUserPresentationLogic?
    
    convenience init(presenter: ESPCreateUserPresentationLogic? = nil) {
        self.init(url: ESPURLParams.shared.baseURL,
                  apiWorker: ESPAPIWorker(),
                  apiParser: ESPAPIParser(),
                  presenter: presenter)
    }
    
    private init(url: String,
         apiWorker: ESPAPIWorker,
         apiParser: ESPAPIParser,
         presenter: ESPCreateUserPresentationLogic? = nil) {
        self.url = url
        self.apiWorker = apiWorker
        self.apiParser = apiParser
        self.presenter = presenter
    }
    
    /// API to sign up user
    /// - Parameters:
    ///   - name: user name
    ///   - password: password
    func createNewUser(name: String, password: String) {
        apiWorker.callAPI(endPoint: .createNewUser(url: self.url, name: name, password: password), encoding: JSONEncoding.default) { data, error in
            self.apiParser.parseResponse(data, withError: error) { umError in
                self.presenter?.verifyUser(withName: name, andPassword: password, withError: umError)
            }
        }
    }
    
    /// Confirm user sign up
    /// - Parameters:
    ///   - name: user name
    ///   - verificationCode: verification code
    func confirmUser(name: String, verificationCode: String) {
        apiWorker.callAPI(endPoint: .confirmUser(url: self.url, name: name, verificationCode: verificationCode), encoding: JSONEncoding.default) { data, error in
            self.apiParser.parseResponse(data, withError: error) { umError in
                self.presenter?.userVerified(withError: umError)
            }
        }
    }
}
