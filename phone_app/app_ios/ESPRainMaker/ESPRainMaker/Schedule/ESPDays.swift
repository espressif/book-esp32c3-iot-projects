// Copyright 2020 Espressif Systems
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
//  ESPDays.swift
//  ESPRainMaker
//

import Foundation

class ESPDay {
    var day: String
    var selected = false

    init(day: String) {
        self.day = day
    }
}

/// Days information for a schedule is fetched/set as integer. Days integer is converted into 8 bit binary.
/// LSB is Monday. [ N/A | Sunday | Saturday | Friday | Tuesday | Wednesday | Tuesday | Monday ].
/// Eg. 0b00011111 (31) means all weekdays. A value of zero means trigger just once.
/// ESPWeek class provide properties and methods to do these conversion.
class ESPWeek: Codable {
    let daysInWeek: [ESPDay] = [ESPDay(day: "Monday"), ESPDay(day: "Tuesday"), ESPDay(day: "Wednesday"), ESPDay(day: "Thursday"), ESPDay(day: "Friday"), ESPDay(day: "Saturday"), ESPDay(day: "Sunday")]

    init(number: Int) {
        configureWeek(number: number)
    }

    func configureWeek(number: Int) {
        let binaryString = String(number, radix: 2)
        let paddedString = pad(string: binaryString, toSize: 8)
        // Reverse the 8 bit converted string to match with the position of days.
        let characters = Array(paddedString.reversed())
        // If a bit is 1 that implies corrosponding day is selected, 0 for otherwise.
        for i in 0 ... 6 {
            if characters[i] == "1" {
                daysInWeek[i].selected = true
            } else {
                daysInWeek[i].selected = false
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case week
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(getDecimalConversionOfSelectedDays(), forKey: .week)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let weekInInt = try container.decodeIfPresent(Int.self, forKey: .week) ?? 0
        configureWeek(number: weekInInt)
    }

    /// Method to convert the selected days into integer.
    ///
    /// - Returns: Decimal conversion of the selected days.
    func getDecimalConversionOfSelectedDays() -> Int {
        var binaryString = ""
        // Check if a day is selected and put its binary value as 1 on 8 character length.
        for item in daysInWeek {
            if item.selected {
                binaryString = "1" + binaryString
            } else {
                binaryString = "0" + binaryString
            }
        }
        // Convert binary string into integer
        let value = Int(binaryString, radix: 2) ?? 0
        return value
    }

    /// Method to generate short description on the basis of selected days of schedule.
    ///
    /// - Returns:Short description for selected days.
    func getShortDescription() -> String {
        var summary: [String] = []
        // If all days are selected then return daily.
        if getDecimalConversionOfSelectedDays() == 127 {
            summary = ["Daily"]
            return summary.compactMap { $0 }.joined(separator: ",")
        }
        for i in 0 ... 6 {
            let item = daysInWeek[i]
            if item.selected {
                summary.append(String(item.day.prefix(3)))
            }
        }
        // Configure description according to the days selected
        var desc = summary.compactMap { $0 }.joined(separator: ", ")
        if desc == "Sat, Sun" {
            desc = "Weekends"
        } else if desc == "Mon, Tue, Wed, Thu, Fri" {
            desc = "Weekdays"
        }
        return desc
    }

    // Method has to be converted from 8 bit integer so adding extra bit.
    private func pad(string: String, toSize: Int) -> String {
        var padded = string
        for _ in 0 ..< (toSize - string.count) {
            padded = "0" + padded
        }
        return padded
    }
}
