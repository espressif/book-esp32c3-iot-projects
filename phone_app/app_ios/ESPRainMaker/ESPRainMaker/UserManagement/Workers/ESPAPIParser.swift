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
//  ESPAPIParser.swift
//  ESPRainMaker
//

import Foundation

protocol ESPAPIParserDelegate {
    
    func parseExtendSessionResponse(_ data: Data?, error: Error?, completion: @escaping (String?, ESPAPIError?) -> Void)
    func parseUserDetailsResponse(_ data: Data?, withError error: Error?, completion: @escaping (ESPAPIError?) -> Void)
    func parseResponse(_ data: Data?, withError error: Error?, completion: @escaping (ESPAPIError?) -> Void)
    func parseRequestToken(url: URL?) -> String?
    func isRefreshTokenValid(serverError: ESPAPIError?) -> Bool
}

class ESPAPIParser {
    
    /// Parse extend session response
    /// - Parameters:
    ///   - data: response data
    ///   - error: response error
    ///   - completion: completion handler with access token string and error
    func parseExtendSessionResponse(_ data: Data?, error: Error?, completion: @escaping (String?, ESPAPIError?) -> Void) {
        let tokenWorker = ESPTokenWorker.shared
        if error == nil {
            if let data = data {
                if let umSessionResponse = getESPSessionResponse(data: data) {
                    if umSessionResponse.gotAccessToken {
                        tokenWorker.saveTokenData(umSessionResponse)
                        if let _ = tokenWorker.migrationEmail {
                            tokenWorker.deleteMigrationEmail()
                        }
                        completion(tokenWorker.accessTokenString, nil)
                    } else {
                        if let umError = getESPAPIError(response: umSessionResponse) {
                            completion(nil, umError)
                        }
                    }
                } else {
                    //parsing error
                    completion(nil, .parsingError())
                }
            }
        } else {
            //server error
            completion(nil, .serverError(error!))
        }
    }
    
    /// Parse API response data for user details
    /// - Parameters:
    ///   - data: response data
    ///   - error: response error
    ///   - completion: completion handler with error
    func parseUserDetailsResponse(_ data: Data?, withError error: Error?, completion: @escaping (ESPAPIError?) -> Void) {
        if error == nil {
            if let data = data {
                if let userDetails = getESPUserDetails(data: data) {
                    if userDetails.status?.lowercased() != "failure" {
                        if let userString = String(data: data, encoding: .utf8) {
                            ESPTokenWorker.shared.saveUserDetails(userString)
                        }
                        completion(nil)
                    } else {
                        let sessionResponse = ESPSessionResponse(status: userDetails.status, errorCode: userDetails.errorCode, description: userDetails.description)
                        if let umError = getESPAPIError(response: sessionResponse) {
                            completion(umError)
                            return
                        }
                        completion(.parsingError())
                    }
                } else {
                    //parsing error
                    completion(.parsingError())
                }
            }
        } else {
            //server error
            completion(.serverError(error!))
        }
    }
    
    /// Parse API response data
    /// - Parameters:
    ///   - data: response data
    ///   - error: response error
    ///   - completion: completion handler with error
    func parseResponse(_ data: Data?, withError error: Error?, completion: @escaping (ESPAPIError?) -> Void) {
        if error == nil {
            if let data = data {
                if let umSessionResponse = getESPSessionResponse(data: data), let status = umSessionResponse.status {
                    if status.lowercased() == "success" {
                        completion(nil)
                    } else {
                        if let umError = getESPAPIError(response: umSessionResponse) {
                            completion(umError)
                        }
                    }
                } else {
                    //parsing error
                    completion(.parsingError())
                }
            }
        } else {
            //server error
            completion(.serverError(error!))
        }
    }
    
    /// Parse request token for third party login
    /// - Parameter url: redirect url from thrid party login
    /// - Returns: thrid party code
    func parseRequestToken(url: URL?) -> String? {
        if let responseURL = url?.absoluteString {
            let components = responseURL.components(separatedBy: "#")
            for item in components {
                if item.contains("code") {
                    let tokens = item.components(separatedBy: "&")
                    for token in tokens {
                        if token.contains("code") {
                            let idTokenInfo = token.components(separatedBy: "=")
                            if idTokenInfo.count > 1 {
                                let code = idTokenInfo[1]
                                return code
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Check if refresh token is valid
    /// - Parameter serverError: error from API
    /// - Returns: true if valid else false
    func isRefreshTokenValid(serverError: ESPAPIError?) -> Bool {
        if let error = serverError {
            switch error {
            case .noRefreshToken:
                return false
            case .errorCode(let code, _):
                if ESPErrorCodeDescription.logOutUserCodes.contains(code) {
                    return false
                }
            default:
                break
            }
        }
        return true
    }
    
    private func getESPUserDetails(data: Data) -> ESPUserDetails? {
        let decoder = JSONDecoder()
        if let userDetails = try? decoder.decode(ESPUserDetails.self, from: data) {
            return userDetails
        }
        return nil
    }
    
    private func getESPSessionResponse(data: Data) -> ESPSessionResponse? {
        let decoder = JSONDecoder()
        if let espSessionResponse = try? decoder.decode(ESPSessionResponse.self, from: data) {
            return espSessionResponse
        }
        return nil
    }
    
    private func getESPAPIError(response: ESPSessionResponse) -> ESPAPIError? {
        if let errorCode = response.errorCode {
            //error code
            var errorCodeDesc: String = ""
            if let desc = response.description {
                errorCodeDesc = desc
            } else {
                errorCodeDesc = ESPErrorCodeDescription(code: "\(errorCode)").errorDescription
            }
            return .errorCode(code: "\(errorCode)", description: errorCodeDesc)
        } else if let desc = response.description, desc.count > 0 {
            //error description
            return .errorDescription(desc)
        }
        return nil
    }
}
