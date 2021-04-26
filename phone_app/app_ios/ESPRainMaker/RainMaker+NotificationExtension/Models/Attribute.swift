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
//  Attribute.swift
//  ESPRainMaker
//

import Foundation

class Attribute: Codable {
    var name: String?
    var value: Any?

    enum CodingKeys: String, CodingKey {
        case name
        case value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }

    init() {}
}

class Param: Attribute {
    var uiType: String?
    var properties: [String]?
    var bounds: [String: Any]?
    var attributeKey: String?
    var dataType: String?
    var type: String?
    var selected = false
    var canUseDeviceServices = false
    var valid_strs: [String]?

    enum CodingKeys: String, CodingKey {
        case uiType = "ui_type"
        case properties
        case bounds
        case attributeKey
        case dataType = "data_type"
        case type
        case canUseDeviceServices
        case value
        case valid_strs
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uiType, forKey: .uiType)
        try container.encode(properties, forKey: .properties)
        try container.encode(bounds as? [String: Float], forKey: .bounds)
        try container.encode(dataType, forKey: .dataType)
        try container.encode(type, forKey: .type)
        try container.encode(canUseDeviceServices, forKey: .canUseDeviceServices)
        try container.encode(attributeKey, forKey: .attributeKey)
        try container.encode(valid_strs, forKey: .valid_strs)

        if let primitiveDataType = dataType {
            if primitiveDataType.lowercased() == "int" {
                try container.encode(value as? Int, forKey: .value)
            } else if primitiveDataType.lowercased() == "float" {
                try container.encode(value as? Float, forKey: .value)
            } else if primitiveDataType.lowercased() == "bool" {
                try container.encode(value as? Bool, forKey: .value)
            } else {
                try container.encode(value as? String, forKey: .value)
            }
        }

        try super.encode(to: encoder)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        properties = try container.decode([String]?.self, forKey: .properties)
        dataType = try container.decode(String?.self, forKey: .dataType)
        type = try container.decode(String?.self, forKey: .type)
        bounds = try container.decodeIfPresent([String: Float].self, forKey: .bounds)
        uiType = try container.decodeIfPresent(String.self, forKey: .uiType)
        attributeKey = try container.decodeIfPresent(String.self, forKey: .attributeKey)
        canUseDeviceServices = try container.decodeIfPresent(Bool.self, forKey: .canUseDeviceServices) ?? false
        valid_strs = try container.decodeIfPresent([String].self, forKey: .valid_strs)

        try super.init(from: decoder)

        if let primitiveDataType = dataType {
            if primitiveDataType.lowercased() == "int" {
                value = try container.decodeIfPresent(Int.self, forKey: .value)
            } else if primitiveDataType.lowercased() == "float" {
                value = try container.decodeIfPresent(Float.self, forKey: .value)
            } else if primitiveDataType.lowercased() == "bool" {
                value = try container.decodeIfPresent(Bool.self, forKey: .value)
            } else {
                value = try container.decodeIfPresent(String.self, forKey: .value)
            }
        }
    }

    override init() {
        super.init()
    }

    init(param: Param) {
        super.init()
        name = param.name
        value = param.value
        uiType = param.uiType
        properties = param.properties
        bounds = param.bounds
        attributeKey = param.attributeKey
        dataType = param.dataType
        type = param.type
        selected = param.selected
        canUseDeviceServices = param.canUseDeviceServices
        valid_strs = param.valid_strs
    }
}
