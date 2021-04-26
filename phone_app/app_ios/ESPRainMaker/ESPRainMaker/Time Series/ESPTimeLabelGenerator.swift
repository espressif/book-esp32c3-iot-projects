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
//  ESPTimeLabelGenerator.swift
//  ESPRainMaker
//

import Foundation

struct ESPTimeLabelGenerator {
    
    var tsArgument: ESPTSArguments
    
    func getTimeLabel() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier:"GMT")
        switch tsArgument.timeInterval {
            case .hour:
            formatter.dateFormat = "MMM d, yyyy"
            let labelString = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(tsArgument.duration.startTime)))
            return labelString
            
        case .day:
            formatter.dateFormat = "d MMM yy"
            let labelString = "\(formatter.string(from: Date(timeIntervalSince1970: TimeInterval(tsArgument.duration.startTime)))) - \(formatter.string(from: Date(timeIntervalSince1970: TimeInterval(tsArgument.duration.endTime))))"
            return labelString
        case .week:
            formatter.dateFormat = "d MMM yy"
            let labelString = "\(formatter.string(from: Date(timeIntervalSince1970: TimeInterval(tsArgument.duration.startTime)))) - \(formatter.string(from: Date(timeIntervalSince1970: TimeInterval(tsArgument.duration.endTime))))"
            return labelString
        case .month:
            formatter.dateFormat = "MMM yyy"
            let labelString = "\(formatter.string(from: Date(timeIntervalSince1970: TimeInterval(tsArgument.duration.startTime)))) - \(formatter.string(from: Date(timeIntervalSince1970: TimeInterval(tsArgument.duration.endTime))))"
            return labelString
            default:
                break
        }
        return ""
    }
}
