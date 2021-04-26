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
//  ESPIdProviderLoginService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire
import SafariServices

protocol ESPIdProviderLoginLogic {
    func loginWith(idProvider: String)
    func requestToken(code: String)
}

class ESPIdProviderLoginService: ESPIdProviderLoginLogic {
    
    var authURL: String
    var redirectURL: String
    var appClientID: String?
    var apiWorker: ESPAPIWorker
    var apiParser: ESPAPIParser
    var presenter: ESPIdProviderLoginPresenter?
    
    var session: SFAuthenticationSession!
    
    convenience init(presenter: ESPIdProviderLoginPresenter?) {
        self.init(authURL: ESPURLParams.shared.authURL,
                  redirectURL: ESPURLParams.shared.redirectURL,
                  appClientID: ESPURLParams.shared.appClientID,
                  apiWorker: ESPAPIWorker(),
                  apiParser: ESPAPIParser(),
                  presenter: presenter)
    }
    
    private init(authURL: String,
                 redirectURL: String,
                 appClientID: String?,
                 apiWorker: ESPAPIWorker,
                 apiParser: ESPAPIParser,
                 presenter: ESPIdProviderLoginPresenter?) {
        self.authURL = authURL
        self.redirectURL = redirectURL
        self.appClientID = appClientID
        self.apiWorker = apiWorker
        self.apiParser = apiParser
        self.presenter = presenter
    }
    
    
    /// Login with third party login
    /// - Parameter idProvider: thrid party login provider
    func loginWith(idProvider: String) {
        var url = self.authURL+"/authorize?identity_provider="+idProvider+"&redirect_uri="+self.redirectURL+"&response_type=CODE&client_id="
        if let clientId = self.appClientID {
            url+=clientId
        }
        session = SFAuthenticationSession(url: URL(string: url)!, callbackURLScheme: self.redirectURL) { url, error in
            if error != nil {
                return
            }
            if let code = self.apiParser.parseRequestToken(url: url) {
                self.requestToken(code: code)
                return
            }
            self.presenter?.loginFailed()
        }
        session.start()
    }
    
    /// Request access token
    /// - Parameter code: code to retrieve access token
    func requestToken(code: String) {
        apiWorker.callAPI(endPoint: .requestToken(authURL: self.authURL, redirectURL: self.redirectURL, code: code, appClientId: self.appClientID), encoding: URLEncoding.default) { data, error in
            if error == nil {
                if let jsonData = data {
                    let decoder = JSONDecoder()
                    if let requestToken = try? decoder.decode(RequestToken.self, from: jsonData) {
                        self.presenter?.loginSuccess(requestToken: requestToken)
                    }
                }
            }
        }
    }
}

struct RequestToken: Codable {
    
    var idToken: String?
    var accessToken: String?
    var refreshToken: String?
    var expiresIn: Int?
    var tokenType: String?
    
    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}


