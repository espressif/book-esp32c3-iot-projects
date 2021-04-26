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
//  NodeGroup.swift
//  ESPRainMaker
//

import Foundation

class Group: Decodable {
    var groups: [NodeGroup]
}

class NodeGroup: Codable {
    var group_name: String?
    var group_id: String?
    var type: String?
    var nodes: [String]?
    var sub_groups: [NodeGroup]?
    // Additional parameter for referencing node object
    var nodeList: [Node]?
}

class CreateNodeGroupResponse: Decodable {
    var status: String
    var group_id: String
}
