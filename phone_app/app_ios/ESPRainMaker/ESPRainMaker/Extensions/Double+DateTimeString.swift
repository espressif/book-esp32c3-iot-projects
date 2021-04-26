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
//  Double+DateTimeString.swift
//  ESPRainMaker
//

extension Double {
    
    // Method to get time and date in required format for display.
    func dateTimeString() ->  (date: String, time: String) {
        
        let date = Date(timeIntervalSince1970: self/1000)
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "dd-MMM-YYYY"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm:ss a"
        
        return (date: dateStringFormatter.string(from: date), time: timeFormatter.string(from: date))
    }
}
