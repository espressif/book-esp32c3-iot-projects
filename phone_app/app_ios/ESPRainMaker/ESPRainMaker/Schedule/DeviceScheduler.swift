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
//  DeviceExtension.swift
//  ESPRainMaker
//

import Foundation

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
