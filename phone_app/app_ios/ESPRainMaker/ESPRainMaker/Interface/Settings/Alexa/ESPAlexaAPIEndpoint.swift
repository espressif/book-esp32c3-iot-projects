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
//  ESPAlexaAPIService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

enum ESPAlexaAPIEndpoint {
        
    //Get Alexa access token
    case getAlexaAccessToken(fetchAccessTokenURL: String, authCode: String, redirectUri: String)
    
    //Get Alexa API Endpoint
    case getAPIEndPoint(getAPIEndpointURL: String, accessToken: String)
    
    //Get Linking Status
    case getLinkingStatus(accessToken: String, urlEndpoint: String, skillId: String)
    
    //Enable linking Alexa skill
    case enableSkill(skillId: String, authCode: String, redirectURI: String, accessToken: String, urlEndPoint: String, stage: String)
    
    //Disable linking Alexa skill
    case disableSkill(accessToken: String, urlEndPoint: String, skillId: String)
    
    //Get Alexa access token using refresh token
    case getAccessTokenWithRefreshToken(useRefreshTokenURL: String, clientId: String, refreshToken: String, clientSecret: String)
    
    var method: HTTPMethod {
        
        switch self {
        case .getAlexaAccessToken, .enableSkill, .getAccessTokenWithRefreshToken:
            return .post
            
        case .getAPIEndPoint, .getLinkingStatus:
            return .get
            
        case .disableSkill:
            return .delete
        }
    }
    
    var headers: HTTPHeaders {
        
        switch self {
        case .getAlexaAccessToken:
            return [ESPAlexaServiceConstants.contentType: ESPAlexaServiceConstants.textPlain,
                    ESPAlexaServiceConstants.charSet: ESPAlexaServiceConstants.utf8]
            
        case .getAPIEndPoint(_, let accessToken), .getLinkingStatus(let accessToken, _, _), .enableSkill(_, _, _, let accessToken, _, _), .disableSkill(let accessToken, _, _):
            return [ESPAlexaServiceConstants.contentType: ESPAlexaServiceConstants.applicationJSON,
                    ESPAlexaServiceConstants.authorization: "\(ESPAlexaServiceConstants.bearer) \(accessToken)"]
            
        case .getAccessTokenWithRefreshToken:
            return [ESPAlexaServiceConstants.contentType: ESPAlexaServiceConstants.applicationFormURLEncoded]
        }
    }
    
    var url: String {
        
        switch self {
        case .getAlexaAccessToken(let baseURL, _, _), .getAccessTokenWithRefreshToken(let baseURL, _, _, _), .getAPIEndPoint(let baseURL, _):
            return baseURL
            
        case .getLinkingStatus(_, let urlEndPoint, let skillId), .enableSkill(let skillId, _, _, _, let urlEndPoint, _), .disableSkill(_, let urlEndPoint, let skillId):
            return "https://\(urlEndPoint)/v1/users/~current/skills/\(skillId)/enablement"
        }
    }
    
    var params: Parameters? {
        
        switch self {
        case .getAlexaAccessToken(_, let authCode, let redirectUri):
            return [ESPAlexaServiceConstants.code: authCode,
                    ESPAlexaServiceConstants.redirectURI: redirectUri]
            
        case .getAPIEndPoint, .getLinkingStatus, .disableSkill:
            return nil
            
        case .enableSkill(_, let authCode, let redirectURI, _, _, let stage):
            return [ESPAlexaServiceConstants.stage: stage,
                    ESPAlexaServiceConstants.accountLinkRequest: [ESPAlexaServiceConstants.paramRedirectURI: redirectURI,
                        ESPAlexaServiceConstants.paramAuthCode: authCode,
                        ESPAlexaServiceConstants.type: ESPAlexaServiceConstants.paramValAuthCode]]
            
        case .getAccessTokenWithRefreshToken(_, let clientId, let refreshToken, let clientSecret):
            return [ESPAlexaServiceConstants.grantType: ESPAlexaServiceConstants.refreshToken,
                    ESPAlexaServiceConstants.clientId: clientId,
                    ESPAlexaServiceConstants.refreshToken: refreshToken,
                    ESPAlexaServiceConstants.clientSecret: clientSecret]
        }
    }
}
