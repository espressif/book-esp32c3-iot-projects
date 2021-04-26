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
//  ESPCloudResponse.swift
//  ESPRainMaker
//

import Foundation

class ESPCloudResponse: Codable {
    var node_id: String?
    var status: String
    var error_code: Int?
    var description: String
}

enum ESPCloudResponseStatus: Error {
    case emptyConfigData
    case emptyResultCount
    case emptyToken
    case userIDNotPresent
    case emptyNodeList
    case success
    case failure
    case unknown
}

class ESPCloudResponseParser {
    
    /// Method returns list of nodes for which param API succeeded and failed
    /// - Parameter response: List of nodes returned from param API
    /// - Returns: tuple with list of nodes for which param API succeeded and failed
    func getNodesWithStatus(response: [ESPCloudResponse]) -> (successResponse: [ESPCloudResponse], failureResponse: [ESPCloudResponse]) {
        var nodesSuccess = [ESPCloudResponse]()
        var nodesFailed = [ESPCloudResponse]()
        for node in response {
            if node.status.lowercased() == "success" {
                nodesSuccess.append(node)
            } else {
                nodesFailed.append(node)
            }
        }
        return (nodesSuccess, nodesFailed)
    }
}

