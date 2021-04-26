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
//  ESPTimeDurationSegment.swift
//  ESPRainMaker
//

import Foundation

enum ESPTimeDurationSegment: String, CaseIterable {
    case day = "1D"
    case week = "7D"
    case month = "4W"
    case year = "1Y"
    
    func getTimeIntterval() -> ESPTimeInterval {
        switch self {
        case .day:
            return .hour
        case .week:
            return .day
        case .month:
            return .week
        case .year:
            return .month
        }
    }
}
