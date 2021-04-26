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
//  ESPRMDeviceType+GetImage.swift
//  ESPRainMaker
//

import Foundation
import UIKit

extension ESPRMDeviceType {
    func getImageFromDeviceType() -> UIImage? {
        switch self {
        case .switchDevice:
            return UIImage(named: "switch")
        case .lightbulb:
            return UIImage(named: "light")
        case .fan:
            return UIImage(named: "fan")
        case .thermostat:
            return UIImage(named: "thermostat")
        case .temperatureSensor:
            return UIImage(named: "temperature_sensor")
        case .lock:
            return UIImage(named: "lock")
        case .sensor:
            return UIImage(named: "sensor_icon")
        case .outlet:
            return UIImage(named: "outlet")
        }
    }
}
