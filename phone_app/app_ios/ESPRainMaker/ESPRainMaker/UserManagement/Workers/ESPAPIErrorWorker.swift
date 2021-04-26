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
//  ESPAPIErrorWorker.swift
//  ESPRainMaker
//

import Foundation

enum ESPAPIError: Error {
    
    case serverError(Error)
    case errorCode(code: String, description: String)
    case errorDescription(String)
    case parsingError(error: String = "Response parsing failed")
    case noRefreshToken
}

struct ESPErrorCodeDescription {
    
    static let emailNotVerifiedKey = "101015"
    static let logOutUserCodes: [String] = ["101025",
                             "119006",
                             "100007",
                             "101017"]
    
    static let errorDictionary: [String: String] =
        ["100006": "Invalid request body",
         "101001": "User name is missing",
         "101002": "Email-id is not in correct format",
         "101003": "Password or verification code is missing",
         "101004": "Password must be atleast 8 characters long. It should contain atleast one uppercase, one lowercase character and a number",
         "101006": "User account already exist",
         "101007": "User name or password is not as per specified policy",
         "101009": "Incorrect user name or password",
         "101011": "User name already verified",
         "101012": "Verification code is incorrect",
         "101019": "Attempt limit exceeded, please try after some time",
         "101025": "User does not exist",
         "100001": "Error in fetching user details",
         "101028": "Error occurred while updating user",
         "101026": "Getting user-id from user name failed",
         "101027": "Error occurred while fetching user profile picture and name",
         "100008": "Error in fetching tenant context details",
         "119005": "Verification code is incorrect",
         "119006": "User does not exist",
         "119007": "Verification code is missing",
         "119001": "Error occurred while storing user delete request",
         "119003": "Error occurred while getting user delete request",
         "119004": "Failed to delete user",
         "119008": "Sending verification code failed",
         "119009": "Failed to initiate user delete request",
         "101015": "Email address is not verified",
         "101016": "Login failed",
         "101017": "Refresh token failed",
         "100002": "API Version is not supported",
         "101036": "Error, Invalid logout_all value specified. [Valid values are true/false]",
         "100007": "Either User Id or User Email needs to be provided",
         "101018": "New Password is missing",
         "101020": "Change password failed",
         "101030": "Verification code is missing",
         "101031": "Forgot password request failed",
         "101032": "Password is missing"
        ]
    
    private var errorKey: String
    
    init(code: String) {
        errorKey = code
    }
    
    /// Return error description for error code
    var errorDescription: String {
        if let description = ESPErrorCodeDescription.errorDictionary[errorKey], description.count > 0 {
            return description
        }
        return "Unknown Error"
    }
    
    /// Get error key for description
    /// - Parameter desc: error description
    /// - Returns: key for description
    static func getErrorKey(desc: String) -> String? {
        for key in errorDictionary.keys {
            if let val = errorDictionary[key], val == desc {
                return key
            }
        }
        return nil
    }
}
