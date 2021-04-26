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
//  SharingRequest.swift
//  ESPRainMaker
//

import Foundation

class SharingRequests: Codable {
    var sharing_requests: [SharingRequest]?
    var next_request_id: String?
    var next_user_name: String?
}

class SharingRequest: Codable {
    var request_id: String
    var request_status: String?
    var request_timestamp: Double?
    var node_ids: [String]?
    var user_name: String?
    var primary_user_name: String?
    var metadata: [String]?

    init(requestID: String) {
        request_id = requestID
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        request_id = try container.decode(String.self, forKey: .request_id)
        request_status = try container.decodeIfPresent(String.self, forKey: .request_status)
        request_timestamp = try container.decodeIfPresent(Double.self, forKey: .request_timestamp)
        node_ids = try container.decodeIfPresent([String].self, forKey: .node_ids)
        user_name = try container.decodeIfPresent(String.self, forKey: .user_name)
        primary_user_name = try container.decodeIfPresent(String.self, forKey: .primary_user_name)

        if let dictionary: [String: Any] = try container.decodeIfPresent([String: Any].self, forKey: .metadata) {
            if let deviceList = dictionary["devices"] as? [[String: String]] {
                metadata = []
                for device in deviceList {
                    if let deviceName = device["name"] {
                        metadata!.append(deviceName)
                    }
                }
            }
        }
    }
}

class CreateSharingResponse: Codable {
    var status: String
    var request_id: String
    var description: String
}
