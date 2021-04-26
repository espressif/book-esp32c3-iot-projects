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
//  ESPTSArguments+NextDuration.swift
//  ESPRainMaker
//

import Foundation

extension ESPTSArguments {
    func getNextDuration() -> ESPDuration {
        switch timeInterval {
        case .hour:
            let espDuration = ESPDuration(startTime: duration.startTime + UInt(ESPChartsConstant.dayTimeStamp), endTime: duration.endTime + UInt(ESPChartsConstant.dayTimeStamp))
            return espDuration
        case .day:
            let espDuration = ESPDuration(startTime: duration.endTime + 1, endTime: duration.endTime + UInt(ESPChartsConstant.weekTimestamp))
            return espDuration
        case .week:
            let espDuration = ESPDuration(startTime: duration.endTime + 1, endTime: duration.endTime + UInt(ESPChartsConstant.dayTimeStamp * 28))
            return espDuration
        case .month:
            // Get next month date
            let startDate = Date(timeIntervalSince1970: TimeInterval(duration.endTime + UInt(ESPChartsConstant.dayTimeStamp)))
            let calendar = Calendar.gmtCalendar()
            // Get next month start date
            let monthStartDate = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: startDate)))!
            let nextYearDate = calendar.date(byAdding: .month, value: 11, to: monthStartDate)!
            // Get next month end date
            let monthEndDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: nextYearDate)
            // Get next 12 months duration
            let espDuration = ESPDuration(startTime: UInt(monthStartDate.timeIntervalSince1970 ), endTime: UInt(monthEndDate!.timeIntervalSince1970))
            return espDuration
        default:
            return duration
        }
    }
}
