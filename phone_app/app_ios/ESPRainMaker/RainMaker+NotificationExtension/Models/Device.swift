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
//  Device.swift
//  ESPRainMaker
//

import Foundation

class Device: Codable {
    var name: String?
    var type: String?
    var attributes: [Attribute]?
    var params: [Param]?
    var node: Node?
    var primary: String?
    var collapsed: Bool = true
    var selectedParams = 0
    var deviceName = ""
    var deviceNameParam = ""
    var scheduleActionStatus: ScheduleActionStatus?
    var sceneActionStatus: SceneActionStatus?

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case primary
        case params
        case attributes
        case deviceName
        case deviceNameParam
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)

        try container.encode(primary, forKey: .primary)
        try container.encode(params, forKey: .params)
        try container.encode(attributes, forKey: .attributes)
        // Additional properties
        try container.encode(deviceName, forKey: .deviceName)
        try container.encode(deviceNameParam, forKey: .deviceNameParam)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        type = try container.decode(String?.self, forKey: .type)
        primary = try container.decode(String?.self, forKey: .primary)
        params = try container.decode([Param]?.self, forKey: .params)
        attributes = try container.decodeIfPresent([Attribute].self, forKey: .attributes)
        //  Additional params
        deviceName = try container.decodeIfPresent(String.self, forKey: .deviceName) ?? ""
        deviceNameParam = try container.decodeIfPresent(String.self, forKey: .deviceNameParam) ?? ""
    }

    func getDeviceName() -> String? {
        if let deviceNameParam = params?.first(where: { param -> Bool in
            param.type == "esp.param.name"
        }) {
            if let name = deviceNameParam.value as? String {
                return name
            }
        }
        return name
    }

    func isReachable() -> Bool {
        if node?.isConnected ?? false || node?.localNetwork ?? false {
            return true
        }
        return false
    }

    init() {}

    required init(name: String?, type: String?, node: Node?, deviceName: String?) {
        self.name = name
        self.type = type
        self.node = node
        self.deviceName = deviceName ?? name ?? ""
    }

    convenience init(device: Device) {
        self.init(name: device.name, type: device.type, node: device.node, deviceName: device.deviceName)
    }
}

/// Enum denotes the schedule actions available for device.
/// .allowed: device scheduling is allowed
/// .deviceOffline: device is not connected to cloud
/// .maxScheduleReached: max schedules created for node
enum ScheduleActionStatus {
    
    case allowed
    case deviceOffline
    case maxScheduleReached(Int)
    
    /// Returns string for device based on its scheduling status
    var description: String {
        switch self {
        case .allowed:
            return ""
        case .deviceOffline:
            return "Offline"
        case .maxScheduleReached(let maxCount):
            return "Max supported count \(maxCount) reached"
        }
    }
}


/// Protocol defines computed properties for the device as per its scheduling status

protocol DeviceScheduler {
    var isDeviceSchedulingAllowed: Bool { get }
    var isDeviceScheduled: Bool { get }
    var scheduleAction: ScheduleActionStatus { get }
}

extension Device: DeviceScheduler {
    /// Returns true if scheduling is allowed for the node the device is associated with
    var isDeviceSchedulingAllowed: Bool {
        if let node = node {
            return node.isSchedulingAllowed
        }
        return false
    }
    
    /// Returns true if device is already scheduled
    var isDeviceScheduled: Bool {
        if selectedParams > 0 {
            return true
        }
        return false
    }
    
    /// Returns the scheduling status of a device [.allowed, .deviceOffline, .maxScheduleReached]
    var scheduleAction: ScheduleActionStatus {
        if let scheduleAction = scheduleActionStatus {
            return scheduleAction
        }
        scheduleActionStatus = .allowed
        if let node = node, !node.isConnected {
            scheduleActionStatus = .deviceOffline
        } else if !isDeviceScheduled, !isDeviceSchedulingAllowed {
            if let maxCount = self.node?.maxSchedulesCount {
                scheduleActionStatus = .maxScheduleReached(maxCount)
            }
        }
        return scheduleActionStatus!
    }
}

/// Enum denotes the schedule actions available for device.
/// .allowed: scene creation/edit is allowed
/// .deviceOffline: device is not connected to cloud
/// .maxScheduleReached: max scenes created for node
enum SceneActionStatus {
    
    case allowed
    case deviceOffline
    case maxSceneReached(Int)
    
    /// Returns string for device based on its scene status
    var description: String {
        switch self {
        case .allowed:
            return ""
        case .deviceOffline:
            return "Offline"
        case .maxSceneReached(let maxCount):
            return "Max supported count \(maxCount) reached"
        }
    }
}


/// Protocol defines computed properties for the device as per its scene status
protocol DeviceSceneHandler {
    var isDeviceSceneAllowed: Bool { get }
    var isDeviceSceneEnabled: Bool { get }
    var sceneAction: SceneActionStatus { get }
}

extension Device: DeviceSceneHandler {
    /// Returns true if scene feature is allowed for the node the device is associated with
    var isDeviceSceneAllowed: Bool {
        if let node = node {
            return node.isSceneAllowed
        }
        return false
    }
    
    /// Returns true if device already is included in a scene
    var isDeviceSceneEnabled: Bool {
        if selectedParams > 0 {
            return true
        }
        return false
    }
    
    /// Returns the scene status of a device [.allowed, .deviceOffline, .maxSceneReached]
    var sceneAction: SceneActionStatus {
        if let status = sceneActionStatus {
            return status
        }
        sceneActionStatus = .allowed
        if let node = node, !node.isConnected {
            sceneActionStatus = .deviceOffline
        } else if !isDeviceSceneAllowed, !isDeviceSceneEnabled {
            if let maxCount = self.node?.maxScenesCount {
                sceneActionStatus = .maxSceneReached(maxCount)
            }
        }
        return sceneActionStatus!
    }
}
