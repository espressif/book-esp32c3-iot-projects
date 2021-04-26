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
//  ESPAggregate.swift
//  ESPRainMaker
//

import Foundation

enum ESPChartType: String, CaseIterable {
    case barChart = "Bar"
    case lineChart = "Line"
}

enum ESPAggregate: String, CaseIterable {
    case avg
    case min
    case max
    case count
    case latest
    case raw
}

enum ESPTimeInterval: String, CaseIterable {
    case minute
    case hour
    case day
    case week
    case month
    case year
}

struct ESPDuration {
    var startTime: UInt
    var endTime: UInt
    
    static func getDefaultDuration() -> (startDateTS: UInt, endDateTS: UInt) {
        let currentDate = Date()
        let calendar = Calendar.gmtCalendar()
        let dateAtMidnight = calendar.startOfDay(for: currentDate)

        //For End Date
        var components = DateComponents()
        components.day = 1
        components.second = -1
        let dateAtEnd = Calendar.gmtCalendar().date(byAdding: components, to: dateAtMidnight)
        return (UInt(dateAtMidnight.timeIntervalSince1970), UInt(dateAtEnd!.timeIntervalSince1970))
    }
}

struct ESPTSArguments {
    var aggregate: ESPAggregate
    var timeInterval: ESPTimeInterval
    var duration: ESPDuration
    var chartType: ESPChartType
    
    init(aggregate: ESPAggregate, timeInterval: ESPTimeInterval, duration: ESPDuration? = nil, chartType: ESPChartType? = nil) {
        self.aggregate = aggregate
        self.timeInterval = timeInterval
        if let chartType = chartType {
            self.chartType = chartType
        } else {
            self.chartType = .barChart
        }
        if let duration = duration {
            self.duration = duration
        } else {
            let defaultDuration = ESPDuration.getDefaultDuration()
            self.duration = ESPDuration(startTime: defaultDuration.startDateTS, endTime: defaultDuration.endDateTS)
        }
    }
    
    mutating func setLatestDuration() {
        let defautltDuration = ESPDuration.getDefaultDuration()
        switch timeInterval {
        case .minute:
            break
        case .hour:
            duration = ESPDuration(startTime: defautltDuration.startDateTS, endTime: defautltDuration.endDateTS)
        case .day:
            duration = ESPDuration(startTime: defautltDuration.endDateTS - UInt(ESPChartsConstant.weekTimestamp) + 1, endTime: defautltDuration.endDateTS)
        case .week:
            duration = ESPDuration(startTime: defautltDuration.endDateTS - UInt(ESPChartsConstant.dayTimeStamp * 28) + 1, endTime: defautltDuration.endDateTS)
        case .month:
            let currentDate = Date()
            let calendar = Calendar.gmtCalendar()
            let monthStartDate = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: currentDate)))!
            let monthEndDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStartDate)
            let previousYearDate = calendar.date(byAdding: .month, value: -11, to: monthStartDate)
            duration = ESPDuration(startTime: UInt(previousYearDate?.timeIntervalSince1970 ?? 0), endTime: UInt(monthEndDate!.timeIntervalSince1970))
        case .year:
            let currentDate = Date()
            let hourEarlierData = Calendar.gmtCalendar().date(byAdding: .year, value: -4, to: currentDate)
            duration = ESPDuration(startTime: UInt(hourEarlierData?.timeIntervalSince1970 ?? 0), endTime: UInt(currentDate.timeIntervalSince1970))
        }
    }
    
}


