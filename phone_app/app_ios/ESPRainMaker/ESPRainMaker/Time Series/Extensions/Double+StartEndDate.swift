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
//  Double+StartEndDate.swift
//  ESPRainMaker
//

import Foundation

extension Double {
   
    /// Method to get start time and end time of a day for current timestamp date.
    ///
    /// - Returns: Tuple with dates change to integer timestamp values.
    func getStartEndDate() -> (startDateTS: Double, endDateTS: Double) {
        let currentDate = Date(timeIntervalSince1970: self)
        let calendar = Calendar.current
        let dateAtMidnight = calendar.startOfDay(for: currentDate)

        //For End Date
        var components = DateComponents()
        components.day = 1
        components.second = -1
        let dateAtEnd = Calendar.gmtCalendar().date(byAdding: components, to: dateAtMidnight)
        return (dateAtMidnight.timeIntervalSince1970, dateAtEnd!.timeIntervalSince1970)
    }
}
