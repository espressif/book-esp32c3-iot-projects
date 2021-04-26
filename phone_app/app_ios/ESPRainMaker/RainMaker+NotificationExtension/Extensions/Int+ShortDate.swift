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
//  Int+ShortDate.swift
//  ESPRainMaker
//

import Foundation

extension Int {
    // Gives date in formatted string.
    func getShortDate() -> String {
        let date = Date(timeIntervalSince1970: Double(self) / 1000.0)
        let dataFormatter = DateFormatter()
        dataFormatter.timeZone = .current
        if Calendar.current.isDateInToday(date) {
            dataFormatter.dateFormat = "HH:mm"
            return dataFormatter.string(from: date)
        }
        dataFormatter.dateFormat = "dd/MM/yy, HH:mm"
        return dataFormatter.string(from: date)
    }
}
