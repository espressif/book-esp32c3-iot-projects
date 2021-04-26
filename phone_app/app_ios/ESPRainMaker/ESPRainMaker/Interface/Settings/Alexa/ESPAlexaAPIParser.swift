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
//  ESPAlexaAPIParser.swift
//  ESPRainMaker
//

import Foundation

class ESPAlexaAPIParser {
    
    static let shared = ESPAlexaAPIParser()
    
    var alexaProperties = [String: String]()
    var rainmakerProperties = [String: String]()
    
    func parseURL(_ url: String, state: ESPEnableSkillState) -> Bool {
        let formattedURL = url.replacingOccurrences(of: "\(Configuration.shared.espAlexaConfiguration.redirectURI)?", with: "")
        let components: [String] = formattedURL.components(separatedBy: "&")
        var properties = [String: String]()
        for index in 0..<components.count {
            let component  = components[index]
            let values = component.components(separatedBy: "=")
            if values.count > 1 {
                properties[values[0]] = values[1]
            }
        }
        if let savedURLState = UserDefaults.standard.value(forKey: ESPAlexaServiceConstants.alexaState) as? String, url.contains(savedURLState) {
            UserDefaults.standard.removeObject(forKey: ESPAlexaServiceConstants.alexaState)
            if state == .rainMakerAuthCode {
                self.rainmakerProperties = properties
            } else {
                self.alexaProperties = properties
            }
            return true
        }
        return false
    }
    
    func getAlexaAuthCode() -> String? {
        if let code = self.alexaProperties[ESPAlexaServiceConstants.code] {
            return code
        }
        return nil
    }
    
    func getRainmakerAuthCode() -> String? {
        if let code = self.rainmakerProperties[ESPAlexaServiceConstants.code] {
            return code
        }
        return nil
    }
    
    func getAlexaErrorDescription() -> String? {
        if let errorCode = self.alexaProperties[ESPAlexaServiceConstants.error.lowercased()] {
            if let result = ESPAlexaAPIErrorDescription.errorDescriptions[errorCode] {
                return result
            }
        }
        return nil
    }
}

class ESPAlexaAPIErrorDescription {
    
    static let errorDescriptions = ["invalid_request": "We are experiencing a problem connecting with Alexa to link your account. Please try again later.",
                                    "unauthorized_client": "We are experiencing a problem connecting with Alexa to link your account. Please try again later.",
                                    "access_denied": "",
                                    "unsupported_response_type": "We are experiencing a problem connecting with Alexa to link your account. Please try again later.",
                                    "invalid_scope": "We are experiencing a problem connecting with Alexa to link your account. Please try again later.",
                                    "server_error": "Sorry, Alexa encountered an unexpected error while trying to link your account. Please try again.",
                                    "temporarily_unavailable": "Sorry, Alexa encountered a momentary error while trying to link your account. Please try again later."]
}
