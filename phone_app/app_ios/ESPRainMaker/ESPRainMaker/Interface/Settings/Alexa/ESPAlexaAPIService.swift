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

enum ESPEnablementStatus {
    case accessToken
    case refreshToken
    case getAPIEndpoint
    case getStatus
    case enable
    case disable
}

enum ESPAlexaAPIStatus: Error {
    case unauthorized
    case alexaAccessTokenExpired
    case alexaAccessTokenFetched
    case apiEndpointFetched
    case accountLinked
    case accountNotLinked
    case linkDeleted
    case unknownFormat
    case parsingError
    case serverError(Error)
    case errorMessage(message: String = "Unkown Error")
    case httpError(statusCode: Int)
}

protocol ESPAlexaAPIServiceDelegate {
    func getESPAlexaAccessToken(code: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void)
    func getESPAPIEndPoint(completionHandler: @escaping (ESPAlexaAPIStatus)-> Void)
    func getESPLinkingStatus(completionHandler: @escaping (ESPAlexaAPIStatus) -> Void)
    func espEnableSkill(code: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void)
    func espDisableSkill(completionHandler: @escaping (ESPAlexaAPIStatus) -> Void)
}

/// Class alexa API service
class ESPAlexaAPIService: ESPAlexaAPIServiceDelegate {
    
    static let enabled = "enabled"
    static let linked = "linked"
    
    var apiWorker: ESPAlexaAPIWorker!
    
    init() {
        self.apiWorker = ESPAlexaAPIWorker()
    }
    
    /// Call get alexa token service
    /// - Parameters:
    ///   - code: alexa auth code
    ///   - completionHandler: callback to be invoked with AlexaAPIStatus
    func getESPAlexaAccessToken(code: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        let apiEndPoint = ESPAlexaAPIEndpoint.getAlexaAccessToken(
            fetchAccessTokenURL: Configuration.shared.espAlexaConfiguration.fetchAccessTokenURL,
            authCode: code,
            redirectUri: Configuration.shared.espAlexaConfiguration.redirectURI)
        
        self.apiWorker.callAPI(endPoint: apiEndPoint, encoding: JSONEncoding.default) { response in
            let (data, error) = self.parseResponse(response: response)
            if error == nil {
                if self.checkStatusCode(state: .accessToken, response: response, completionHandler: completionHandler) {
                    let decoder = JSONDecoder()
                    if let data = data, let alexaResponse = try? decoder.decode(ESPAlexaResponse.self, from: data), let _ = alexaResponse.accessToken, let _ = alexaResponse.refreshToken, let _ = alexaResponse.expiresIn, let _ = alexaResponse.tokenType {
                        ESPAlexaTokenWorker.shared.saveTokens(data: alexaResponse)
                        completionHandler(.alexaAccessTokenFetched)
                        return
                    }
                    completionHandler(.parsingError)
                }
            } else if let err = error {
                completionHandler(.serverError(err))
            }
        }
    }
    
    /// Get Alexa API endpoints
    /// - Parameter completionHandler: callback to be invoked with AlexaAPIStatus
    func getESPAPIEndPoint(completionHandler: @escaping (ESPAlexaAPIStatus)-> Void) {
        if let accessToken = ESPAlexaTokenWorker.shared.getAccessToken {
            
            let apiEndPoint = ESPAlexaAPIEndpoint.getAPIEndPoint(
                getAPIEndpointURL: Configuration.shared.espAlexaConfiguration.getAPIEndpointURL,
                accessToken: accessToken)
            
            self.apiWorker.callAPI(endPoint: apiEndPoint) { response in
                let (data, error) = self.parseResponse(response: response)
                if error == nil {
                    if !self.checkEnablementStatusCode(response: response, enablementStatus: .getAPIEndpoint, completionHandler: completionHandler) {
                        return
                    }
                    let decoder = JSONDecoder()
                    if let data = data ,let alexaEndpoints = try? decoder.decode(ESPAlexaEndpoints.self, from: data) {
                        if let endpoints = alexaEndpoints.endPoints, endpoints.count > 0 {
                            ESPAlexaTokenWorker.shared.saveEndPoints(data: alexaEndpoints)
                            completionHandler(.apiEndpointFetched)
                            return
                        } else if let message = alexaEndpoints.message {
                            completionHandler(.errorMessage(message: message))
                            return
                        }
                    }
                    completionHandler(.parsingError)
                } else if let err = error {
                    completionHandler(.serverError(err))
                }
            }
        }
    }
    
    
    /// Get linking status
    /// - Parameter completionHandler: callback to be invoked with AlexaAPIStatus
    func getESPLinkingStatus(completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        if let accessToken = ESPAlexaTokenWorker.shared.getAccessToken, let urlEndPoints = ESPAlexaTokenWorker.shared.getAlexaURLEndPoints, urlEndPoints.count > 0 {
            self.getLinkingStatusForMultipleEndpoints(endPoints: urlEndPoints, index: 0, accessToken: accessToken, completionHandler: completionHandler)
        } else {
            completionHandler(.errorMessage())
        }
    }
    
    /// Get linking status using multiple endpoints
    /// - Parameters:
    ///   - endPoints: array of endpoints
    ///   - index: index for api endpoint to be used from the array
    ///   - accessToken: access token
    ///   - completionHandler: callback to be invoked with AlexaAPIStatus
    private func getLinkingStatusForMultipleEndpoints(endPoints: [String], index: Int, accessToken: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        self.getLinkingStatusForSingleEndpoint(forEndpoint: endPoints[index], forAccessToken: accessToken) { status in
            switch status {
            case .accountLinked, .alexaAccessTokenExpired, .accountNotLinked, .unauthorized:
                completionHandler(status)
            default:
                if index == endPoints.count-1 {
                    completionHandler(status)
                } else {
                    self.getLinkingStatusForMultipleEndpoints(endPoints: endPoints, index: index+1, accessToken: accessToken, completionHandler: completionHandler)
                }
            }
        }
    }
    
    /// Get linking status for an Alexa URL endpoint
    /// - Parameters:
    ///   - endPoint: URL endpoint
    ///   - accessToken: access token
    ///   - completionHandler: callback to be invoked with AlexaAPIStatus
    private func getLinkingStatusForSingleEndpoint(forEndpoint endPoint: String, forAccessToken accessToken: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        let apiEndPoint = ESPAlexaAPIEndpoint.getLinkingStatus(
            accessToken: accessToken,
            urlEndpoint: endPoint,
            skillId: Configuration.shared.espAlexaConfiguration.skillId)
        
        self.apiWorker.callAPI(endPoint: apiEndPoint) { response in
            let (data, error) = self.parseResponse(response: response)
            if !self.checkEnablementStatusCode(response: response, enablementStatus: .getStatus, completionHandler: completionHandler) {
                return
            }
            if error == nil {
                let decoder = JSONDecoder()
                if let data = data, let obj = try? decoder.decode(ESPAlexaWelcome.self, from: data) {
                    if obj.status?.lowercased() == ESPAlexaAPIService.enabled, obj.accountLink?.status?.lowercased() == ESPAlexaAPIService.linked {
                        completionHandler(.accountLinked)
                    } else {
                        completionHandler(.unknownFormat)
                    }
                    return
                } else {
                    completionHandler(.parsingError)
                }
            } else {
                if let err = error {
                    completionHandler(.serverError(err))
                }
            }
        }
    }
    
    /// API to enable app to app linking
    /// - Parameters:
    ///   - code: rainmaker auth code
    ///   - completionHandler: callback to be invoked with AlexaAPIStatus
    func espEnableSkill(code: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        if let accessToken = ESPAlexaTokenWorker.shared.getAccessToken, let urlEndPoints = ESPAlexaTokenWorker.shared.getAlexaURLEndPoints, urlEndPoints.count > 0 {
            self.enableSkillForMultipleEndpoints(apiEndPoints: urlEndPoints, index: 0, code: code, accessToken: accessToken, completionHandler: completionHandler)
        } else {
            completionHandler(.errorMessage())
        }
    }
    
    /// API to enable app to app linking with multiple endpoints
    /// - Parameters:
    ///   - apiEndPoints: apiEndpoints array
    ///   - index: index for api endpoint to be used from the array
    ///   - code: rainmaker auth code
    ///   - accessToken: access token
    ///   - completionHandler: callback to be invoked with AlexaAPIStatus
    private func enableSkillForMultipleEndpoints(apiEndPoints: [String], index: Int, code: String, accessToken: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        self.enableSkillForSingleEndpoint(code: code, endPoint: apiEndPoints[index], accessToken: accessToken) { status in
            switch status {
            case .accountLinked, .alexaAccessTokenExpired, .accountNotLinked, .unauthorized:
            completionHandler(status)
            default:
                if index == apiEndPoints.count-1 {
                    completionHandler(status)
                } else {
                    self.enableSkillForMultipleEndpoints(apiEndPoints: apiEndPoints, index: index+1, code: code, accessToken: accessToken, completionHandler: completionHandler)
                }
            }
        }
    }
    
    /// Enable skill for api endpoint
    /// - Parameters:
    ///   - code: rainmaker auth code
    ///   - endPoint: alexa api endpoint
    ///   - accessToken: alexa access token
    ///   - completionHandler: callback to be invoked with AlexaAPIStatus
    private func enableSkillForSingleEndpoint(code: String, endPoint: String, accessToken: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        let apiEndPoint = ESPAlexaAPIEndpoint.enableSkill(
            skillId: Configuration.shared.espAlexaConfiguration.skillId,
            authCode: code,
            redirectURI: Configuration.shared.espAlexaConfiguration.redirectURI,
            accessToken: accessToken,
            urlEndPoint: endPoint,
            stage: Configuration.shared.espAlexaConfiguration.skillStage)
        
        apiWorker.callAPI(endPoint: apiEndPoint, encoding: JSONEncoding.default) { response in
            let (data, error) = self.parseResponse(response: response)
            if !self.checkEnablementStatusCode(response: response, enablementStatus: .enable, completionHandler: completionHandler) {
                return
            }
            if error == nil {
                let decoder = JSONDecoder()
                if let data = data, let obj = try? decoder.decode(ESPAlexaWelcome.self, from: data) {
                    if obj.status?.lowercased() == ESPAlexaAPIService.enabled, obj.accountLink?.status?.lowercased() == ESPAlexaAPIService.linked {
                        completionHandler(.accountLinked)
                    } else {
                        completionHandler(.unknownFormat)
                    }
                    return
                }
                completionHandler(.parsingError)
            } else {
                if let err = error {
                    completionHandler(.serverError(err))
                }
            }
        }
    }
    
    /// API to enable app to app linking
    /// - Parameters:
    ///   - code: rainmaker auth code
    ///   - completionHandler: callback to be invoked with AlexaAPIStatus
    func espDisableSkill(completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        if let accessToken = ESPAlexaTokenWorker.shared.getAccessToken, let urlEndPoints = ESPAlexaTokenWorker.shared.getAlexaURLEndPoints, urlEndPoints.count > 0 {
            self.disableSkillForMultipleEndpoints(endPoints: urlEndPoints, index: 0, accessToken: accessToken, completionHandler: completionHandler)
        } else {
            completionHandler(.errorMessage())
        }
    }
    
    /// API to disable app to app linking with multiple endpoints
    /// - Parameters:
    ///   - apiEndPoints: apiEndpoints array
    ///   - index: index for api endpoint to be used from the array
    ///   - accessToken: alexa access token
    ///   - completionHandler: callback to be invoked with AlexaAPIStatus
    private func disableSkillForMultipleEndpoints(endPoints: [String], index: Int, accessToken: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        self.disableSkillForSingleEndpoint(endPoint: endPoints[index], accessToken: accessToken) { status in
            switch status {
            case .linkDeleted, .alexaAccessTokenExpired, .accountLinked, .accountNotLinked, .unauthorized:
            completionHandler(status)
            default:
                if index == endPoints.count - 1 {
                    completionHandler(status)
                } else {
                    self.disableSkillForMultipleEndpoints(endPoints: endPoints, index: index+1, accessToken: accessToken, completionHandler: completionHandler)
                }
            }
        }
    }
    
    /// Disable skill for api endpoint
    /// - Parameters:
    ///   - endPoint: alexa api endpoint
    ///   - accessToken: alexa access token
    ///   - completionHandler: callback to be invoked with AlexaAPIStatus
    private func disableSkillForSingleEndpoint(endPoint: String, accessToken: String, completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        
        let apiEndPoint = ESPAlexaAPIEndpoint.disableSkill(
            accessToken: accessToken,
            urlEndPoint: endPoint,
            skillId: Configuration.shared.espAlexaConfiguration.skillId)
        
        apiWorker.callAPI(endPoint: apiEndPoint) { response in
            let (_, error) = self.parseResponse(response: response)
            if !self.checkEnablementStatusCode(response: response, enablementStatus: .disable, completionHandler: completionHandler) {
                return
            }
            if let error = error {
                completionHandler(.serverError(error))
            }
        }
    }
    
    /// Call alexa API service to get access token from refresh token
    /// - Parameter completionHandler: callback to be invoked with AlexaAPIStatus
    func getESPAlexaAccessTokenWithRefreshToken(completionHandler: @escaping (ESPAlexaAPIStatus) -> Void) {
        if let refreshToken = ESPAlexaTokenWorker.shared.getRefreshToken {
            
            let apiEndpoint = ESPAlexaAPIEndpoint.getAccessTokenWithRefreshToken(
                useRefreshTokenURL: Configuration.shared.espAlexaConfiguration.useRefreshTokenURL,
                clientId: Configuration.shared.espAlexaConfiguration.appClientId,
                refreshToken: refreshToken,
                clientSecret: Configuration.shared.espAlexaConfiguration.appClientSecret)
            
            apiWorker.callAPI(endPoint: apiEndpoint) { response in
                let (data, error) = self.parseResponse(response: response)
                if error == nil {
                    if self.checkStatusCode(state: .refreshToken, response: response, completionHandler: completionHandler) {
                        let decoder = JSONDecoder()
                        if let data = data, let alexaResponse = try? decoder.decode(ESPAlexaResponse.self, from: data), let _ = alexaResponse.accessToken, let _ = alexaResponse.refreshToken, let _ = alexaResponse.expiresIn, let _ = alexaResponse.tokenType {
                            ESPAlexaTokenWorker.shared.saveTokens(data: alexaResponse)
                            completionHandler(.alexaAccessTokenFetched)
                            return
                        }
                        completionHandler(.parsingError)
                    }
                } else if let error = error {
                    completionHandler(.serverError(error))
                }
            }
        }
    }
    
    /// Chedk API response status code for enablement APIs
    /// - Parameters:
    ///   - response: response from alexa enablement APIs
    ///   - enablementStatus: enablement request type
    ///   - completionHandler: completionHandler
    /// - Returns: true if API is successful and false otherwise
    private func checkEnablementStatusCode(response: AFDataResponse<Data?>, enablementStatus: ESPEnablementStatus, completionHandler: (ESPAlexaAPIStatus) -> Void) -> Bool {
        
        if let statusCode = response.response?.statusCode {
            if statusCode == 200 {
                if enablementStatus == .getStatus {
                    return true
                }
            } else if statusCode == 201, enablementStatus == .enable {
                return true
            } else if statusCode == 204, enablementStatus == .disable {
                completionHandler(.linkDeleted)
                return false
            } else if statusCode == 401 {
                completionHandler(.alexaAccessTokenExpired)
                return false
            } else if statusCode == 400 {
                completionHandler(.unauthorized)
                return false
            } else if statusCode == 403 {
                completionHandler(.alexaAccessTokenExpired)
                return false
            } else if statusCode == 404, enablementStatus == .getStatus {
                completionHandler(.accountNotLinked)
                return false
            }
        }
        return true
    }
    
    /// Chedk API response status code for get alexa token APIs
    /// - Parameters:
    ///   - response: response from get alexa  token APIs
    ///   - completionHandler: completionHandler
    /// - Returns: true if API is successful and false otherwise
    private func checkStatusCode(state: ESPEnablementStatus, response: AFDataResponse<Data?>, completionHandler: (ESPAlexaAPIStatus) -> Void) -> Bool {
        
        if let statusCode = response.response?.statusCode {
            if statusCode == 200 {
                return true
            } else if statusCode == 400, state == .refreshToken {
                completionHandler(.unauthorized)
                return false
            } else if statusCode == 403 {
                completionHandler(.unauthorized)
                return false
            } else {
                completionHandler(.httpError(statusCode: statusCode))
                return false
            }
        }
        return true
    }

    
    /// Parse AFDataResponse
    /// - Parameter response: API response
    /// - Returns: tuple consisting data and error
    func parseResponse(response: AFDataResponse<Data?>) -> (Data?, Error?) {
        switch response.result {
        case .success(let data):
            return (data, nil)
        case .failure(let error):
            return (nil, error)
        }
    }
}
