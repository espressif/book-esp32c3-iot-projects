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
//  ESPAPIEndPoint.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

enum ESPAPIEndPoint {
    
    case createNewUser(url: String, name: String, password: String)
    case confirmUser(url: String, name: String, verificationCode: String)
    case loginUser(url: String, name: String, password: String)
    case extendSession(url: String, name: String, refreshToken: String)
    case updateUsername(url: String, name: String, accessToken: String)
    case fetchUserDetails(url: String, accessToken: String)
    case changePassword(url: String, old: String, new: String, accessToken: String)
    case requestForgotPassword(url: String, name: String)
    case confirmForgotPassword(url: String, name: String, password: String, verificationCode: String)
    case logoutUser(url: String)
    case requestToken(authURL: String, redirectURL: String, code: String, appClientId: String?)
    
    
    /// Returns URL string for the corresponding API endpoint
    var url: String {
        switch self {
        case .createNewUser(let url, _, _), .confirmUser(let url, _, _), .updateUsername(let url, _, _), .fetchUserDetails(let url, _):
            return "\(url)/user"
            
        case .loginUser(let url, _,_):
            return "\(url)/login"
            
        case .extendSession(let url, _,_):
            return "\(url)/login"
            
        case .logoutUser(let url):
            return "\(url)/logout"
            
        case .changePassword(let url, _, _, _):
            return "\(url)/password"
            
        case .requestForgotPassword(let url, _), .confirmForgotPassword(let url, _, _, _):
            return "\(url)/forgotpassword"
            
        case .requestToken(let authURL, _, _, _):
            return "\(authURL)/token"
        }
    }
    
    /// Returns URL string for the corresponding API endpoint
    var headers: HTTPHeaders {
        
        switch self {
        case .createNewUser(_,_,_), .confirmUser(_,_,_), .loginUser(_,_,_), .extendSession(_,_,_), .logoutUser:
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON]
            
        case .updateUsername(_, _, accessToken: let accessToken), .fetchUserDetails(_, accessToken: let accessToken):
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON,
                    ESPAPIKeys.authorization: accessToken]
            
        case .requestForgotPassword(_, _), .confirmForgotPassword(_,_,_,_):
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON]
            
        case .changePassword(_,_,_, accessToken: let accessToken):
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON,
                    ESPAPIKeys.authorization: accessToken]
            
        case .requestToken:
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationURLEncoded]
        }
    }
    
    
    var method: HTTPMethod {
        
        switch self {
        case .createNewUser(_,_,_), .confirmUser(_,_,_), .loginUser(_,_,_), .extendSession(_,_,_), .logoutUser(_):
            return .post
            
        case .updateUsername(_,_,_), .requestForgotPassword(_,_), .confirmForgotPassword(_,_,_,_), .changePassword(_,_,_,_):
            return .put
            
        case .fetchUserDetails(_,_):
            return .get
            
        case .requestToken:
            return .post
        }
    }
    
    
    var parameters: Parameters? {
        
        switch self {
        case .createNewUser(_, name: let userName, password: let password):
            return [ESPAPIKeys.userName: userName,
                    ESPAPIKeys.password: password]
            
        case .confirmUser(_, name: let userName, verificationCode: let verificationCode):
            return [ESPAPIKeys.userName: userName,
                    ESPAPIKeys.verificationCode: verificationCode]
            
        case .loginUser(_, name: let userName, password: let password):
            return [ESPAPIKeys.userName: userName,
                    ESPAPIKeys.password: password]
            
        case .extendSession(_, name: let userName, refreshToken: let refreshToken):
            return [ESPAPIKeys.userName: userName,
                    ESPAPIKeys.refreshToken: refreshToken]
            
        case .updateUsername(_, let name, _):
            return [ESPAPIKeys.name: name]
        
        case .requestForgotPassword(_, name: let name):
            return [ESPAPIKeys.userName: name]
            
        case .logoutUser(_), .fetchUserDetails(_,_):
            return nil
        
        case .confirmForgotPassword(_, name: let name, password: let password, verificationCode: let verificationCode):
            return [ESPAPIKeys.userName: name,
                    ESPAPIKeys.password: password,
                    ESPAPIKeys.verificationCode: verificationCode]
            
        case .changePassword(_, old: let old, new: let new, _):
            return [ESPAPIKeys.password: old,
                    ESPAPIKeys.newPassword: new]
            
        case .requestToken(_, let redirectURL, let code, let appClientId):
            if let clientId = appClientId {
                return [ESPAPIKeys.grantType: ESPAPIKeys.authorizationCode,
                        ESPAPIKeys.clientId: clientId,
                        ESPAPIKeys.code: code,
                        ESPAPIKeys.redirctURI: redirectURL]
            } else {
                return [ESPAPIKeys.grantType: ESPAPIKeys.authorizationCode,
                        ESPAPIKeys.code: code,
                        ESPAPIKeys.redirctURI: redirectURL]
            }
        }
    }
    
    
    var description: String {
        
        switch self {
        case .createNewUser(_,_,_):
            return "createNewUser"
        case .confirmUser(_,_,_):
            return "confirmUser"
        case .loginUser(_,_,_):
            return "loginUser"
        case .extendSession(_,_,_):
            return "extendSession"
        case .updateUsername(_,_,_):
            return "updateUsername"
        case .fetchUserDetails(_,_):
            return "fetchUserDetails"
        case .changePassword(_,_,_,_):
            return "changePassword"
        case .requestForgotPassword(_,_):
            return "requestForgotPassword"
        case .confirmForgotPassword(_,_,_,_):
            return "confirmForgotPassword"
        case .logoutUser(_):
            return "logoutUser"
        case .requestToken(_,_,_,_):
            return "requestToken"
        }
    }
}

struct ESPAPIKeys {
    
    static let contentType = "Content-Type"
    static let applicationJSON = "application/json"
    static let applicationURLEncoded = "application/x-www-form-urlencoded"
    static let authorization = "Authorization"
    
    static let name = "name"
    static let userName = "user_name"
    static let password = "password"
    static let newPassword = "newpassword"
    static let verificationCode = "verification_code"
    static let refreshToken = "refreshtoken"
    
    static let grantType = "grant_type"
    static let authorizationCode = "authorization_code"
    static let code = "code"
    static let redirctURI = "redirect_uri"
    static let clientId = "client_id"
}
