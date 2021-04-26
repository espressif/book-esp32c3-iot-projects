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
//  ScheduleSceneActionAllowedProtocol.swift
//  ESPRainMaker
//

import Foundation

enum DeviceServiceType {
    case schedule
    case scene
    case none
}

protocol ScheduleSceneActionAllowedProtocol {
    func setupSelections()
    func isCellEnabled(cellType: DeviceServiceType, device: Device) -> Bool
}

extension ScheduleSceneActionAllowedProtocol {
    
    func isCellEnabled(cellType: DeviceServiceType, device: Device) -> Bool {
        var isAllowed = true
        switch cellType {
        case .scene:
            switch device.sceneAction {
            case .allowed:
                isAllowed = true
            default:
                isAllowed = false
            }
        case .schedule:
            switch device.scheduleAction {
            case .allowed:
                isAllowed = true
            default:
                isAllowed = false
            }
        default:
            break
        }
        return isAllowed
    }
}
