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
//  ESPRMDeviceType.swift
//  ESPRainMaker
//

import Foundation

enum ESPRMDeviceType: String {
    case switchDevice = "esp.device.switch"
    case lightbulb = "esp.device.lightbulb"
    case fan = "esp.device.fan"
    case thermostat = "esp.device.thermostat"
    case temperatureSensor = "esp.device.temperature-sensor"
    case lock = "esp.device.lock"
    case sensor = "esp.device.sensor"
    case outlet = "esp.device.outlet"
}
