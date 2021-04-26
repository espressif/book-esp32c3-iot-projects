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
//  ESPServerParams.swift
//  ESPRainMaker
//

import Foundation

class ESPServerTrustParams {
    
    static let shared = ESPServerTrustParams()
    
    var fileName: String?
    var baseURLDomain: String = ""
    var authURLDomain: String = ""
    var claimURLDomain: String = ""
    
    func setParams(fileName: String?,
                   baseURLDomain: String,
                   authURLDomain: String,
                   claimURLDomain: String) {
        self.fileName = fileName
        self.baseURLDomain = baseURLDomain
        self.authURLDomain = authURLDomain
        self.claimURLDomain = claimURLDomain
    }
}

class ESPURLParams {
    
    static let shared = ESPURLParams()
    
    var baseURL: String = ""
    var authURL: String = ""
    var redirectURL: String = ""
    var appClientID: String?
    
    func setURLs(baseURL: String,
                 authURL: String,
                 redirectURL: String,
                 appClientID: String?) {
        self.baseURL = baseURL
        self.authURL = authURL
        self.redirectURL = redirectURL
        self.appClientID = appClientID
    }
}
