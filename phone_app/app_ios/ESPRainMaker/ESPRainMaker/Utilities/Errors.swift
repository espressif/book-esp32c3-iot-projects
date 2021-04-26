// Copyright 2020 Espressif Systems
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
//  Error.swift
//  ESPRainMaker
//
//  Created by Vikas Chandra on 09/10/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

enum InputValidationError: String {
    case outOfBound = "Input value is out of bound"
    case invalid = "Input value is inavlid"
    case other = "Unrecognized error"
}

enum ESPNetworkError: Error {
    case keyNotPresent
    case emptyToken
    case serverError(_ description: String = "Oops!! Something went bad. Please try again after sometime")
    case noData
    case emptyConfigData
    case localServerError(ESPLocalServiceError)
    case noNetwork
    case unknownError
    case parsingError(_ description: String = "Unable to parse data.")

    var description: String {
        switch self {
        case let .serverError(description):
            return description
        case .keyNotPresent:
            return "Key not present."
        case .emptyToken:
            return "Authorization Error. Please Refresh. If it does not work, please sign-in again."
        case .emptyConfigData:
            return "Node info is not present"
        case let .localServerError(localError):
            return localError.description
        case .noNetwork:
            return "Not connected to network."
        case let .parsingError(description):
            return description
        case .unknownError:
            return "Unknown error."
        case .noData:
            return "Data not present"
        }
    }
}
