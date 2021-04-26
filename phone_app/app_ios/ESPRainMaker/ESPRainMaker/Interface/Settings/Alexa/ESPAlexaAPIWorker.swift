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
//  AlexaAPIWorker.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

class ESPAlexaAPIWorker {
    
    var session: Session!
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        session = Session(configuration: configuration)
        session.sessionConfiguration.timeoutIntervalForRequest = 10
        session.sessionConfiguration.timeoutIntervalForResource = 10
    }
    
    public func callAPI(endPoint: ESPAlexaAPIEndpoint,
                 encoding: ParameterEncoding = URLEncoding.default,
                 completionHandler: @escaping (AFDataResponse<Data?>) -> Void) {
        
        callAPI(url: endPoint.url,
                method: endPoint.method,
                parameters: endPoint.params,
                encoding: encoding,
                headers: endPoint.headers,
                completionHandler: completionHandler)
    }
    
    /// Method to make API call
    /// - Parameters:
    ///   - url: url endpoint
    ///   - method: HTTP method
    ///   - parameters: request body
    ///   - encoding: data encoding
    ///   - headers: HTTP headers
    ///   - completionHandler: callback on getting response
    private func callAPI(url: URLConvertible,
                 method: HTTPMethod,
                 parameters: Parameters? = nil,
                 encoding: ParameterEncoding = URLEncoding.default,
                 headers: HTTPHeaders? = nil,
                 completionHandler: @escaping (AFDataResponse<Data?>) -> Void) {
        
        session.request(url,
                        method: method,
                        parameters: parameters,
                        encoding: encoding,
                        headers: headers)
            .response { response in
                completionHandler(response)
            }
    }
}
