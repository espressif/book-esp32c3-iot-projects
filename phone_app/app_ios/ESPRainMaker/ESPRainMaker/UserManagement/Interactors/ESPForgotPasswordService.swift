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
//  ESPForgotPasswordService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPForgotPasswordLogic {
    func requestForgotPassword(name: String)
}

class ESPForgotPasswordService: ESPForgotPasswordLogic {
    
    var url: String
    var apiWorker: ESPAPIWorker
    var apiParser: ESPAPIParser
    
    var presenter: ESPForgotPasswordPresentationLogic?
    
    convenience init(presenter: ESPForgotPasswordPresentationLogic? = nil) {
        self.init(url: ESPURLParams.shared.baseURL,
                  apiWorker: ESPAPIWorker(),
                  apiParser: ESPAPIParser(),
                  presenter: presenter)
    }
    
    private init(url:String,
         apiWorker: ESPAPIWorker,
         apiParser: ESPAPIParser,
         presenter: ESPForgotPasswordPresentationLogic? = nil) {
        self.url = url
        self.apiWorker = apiWorker
        self.apiParser = apiParser
        self.presenter = presenter
    }
    
    /// Request forgot password
    /// - Parameter name: user name
    func requestForgotPassword(name: String) {
        apiWorker.callAPI(endPoint: .requestForgotPassword(url: self.url, name: name), encoding: JSONEncoding.default) { data, error in
            self.apiParser.parseResponse(data, withError: error) { umError in
                self.presenter?.requestedForgotPassword(withError: umError)
            }
        }
    }
    
    /// Confirm new password
    /// - Parameters:
    ///   - name: user name
    ///   - password: new password
    ///   - verificationCode: verification code
    func confirmForgotPassword(name: String, password: String, verificationCode: String) {
        apiWorker.callAPI(endPoint: .confirmForgotPassword(url: self.url, name: name, password: password, verificationCode: verificationCode), encoding: JSONEncoding.default) { data, error in
            self.apiParser.parseResponse(data, withError: error) { umError in
                self.presenter?.confirmForgotPassword(withError: umError)
            }
        }
    }
}
