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
//  ESPXAxisNameFormater.swift
//  ESPRainMaker
//

import Foundation

// Format timestamp to relative date format based on time interval.
struct ESPXAxisNameFormater {
    
    var timeInterval: ESPTimeInterval
    var timezone: String?
    
    /// Method to convert timestamp into String based on selected time interva..
    ///
    /// - Returns: String conversion of the timestamp.
    func stringForValue( _ value: Double) -> String {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        
        switch timeInterval {
        case .minute:
            formatter.dateFormat = "hh:mm a"
        case .hour:
            formatter.dateFormat = "hh a"
        case .day:
            formatter.dateFormat = "EE"
        case .week:
            formatter.dateFormat = "dd/MM"
        case .month:
            formatter.dateFormat = "MMM"
        case .year:
            formatter.dateFormat = "YYYY"
        }
        
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        if let timeZone = timezone {
            formatter.timeZone = TimeZone(identifier: timeZone)
        }
        return formatter.string(from: Date(timeIntervalSince1970: value))
    }

}
