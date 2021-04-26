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
//  ESPTSArguments+PrevDuration.swift
//  ESPRainMaker
//

import Foundation

extension ESPTSArguments {
    func getPreviousDuration() -> ESPDuration {
        switch timeInterval {
        case .hour:
            let espDuration = ESPDuration(startTime: duration.startTime - UInt(ESPChartsConstant.dayTimeStamp), endTime: duration.endTime - UInt(ESPChartsConstant.dayTimeStamp))
            return espDuration
        case .day:
            let espDuration = ESPDuration(startTime: duration.startTime - UInt(ESPChartsConstant.weekTimestamp), endTime: duration.startTime - 1)
            return espDuration
        case .week:
            let espDuration = ESPDuration(startTime: duration.startTime - UInt(ESPChartsConstant.dayTimeStamp * 28), endTime: duration.startTime - 1)
            return espDuration
        case .month:
            let calendar = Calendar.gmtCalendar()
            // Get previous month date
            let startDate = Date(timeIntervalSince1970: TimeInterval(duration.startTime - UInt(ESPChartsConstant.dayTimeStamp)))
            // Get previous month start date
            let monthStartDate = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: startDate)))!
            // Get previous month end date
            let monthEndDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStartDate)
            let previousYearDate = calendar.date(byAdding: .month, value: -11, to: monthStartDate)
            // Get previous duration of 12 months
            let espDuration = ESPDuration(startTime: UInt(previousYearDate?.timeIntervalSince1970 ?? 0), endTime: UInt(monthEndDate!.timeIntervalSince1970))
            return espDuration
        default:
            return duration
        }
    }
}
