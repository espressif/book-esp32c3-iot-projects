// Copyright 2022 Espressif Systems
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
//  ESPScene.swift
//  ESPRainMaker
//

import Foundation

/// Instance of this class contain a single Scene.
class ESPScene: Codable {
    var id: String!
    var name: String?
    var info: String?
    var actions: [String: [Device]] = [:]
    var operation: ESPOperation?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case info
        case actions
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(info, forKey: .info)
        try container.encode(actions, forKey: .actions)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        info = try container.decodeIfPresent(String.self, forKey: .info)
        actions = try container.decodeIfPresent([String: [Device]].self, forKey: .actions) ?? [:]
    }

    init() {}
}
