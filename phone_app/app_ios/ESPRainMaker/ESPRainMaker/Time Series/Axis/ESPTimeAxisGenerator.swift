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
//  ESPTimeAxisGenerator.swift
//  ESPRainMaker
//

import Foundation
import SwiftCharts

// Generates Time Axis(X-Axis) for the chart display.
struct ESPTimeAxisGenerator {
    
    var timeInterval: ESPTimeInterval
    var startTime: Double
    var endTime: Double
    var label: String
    var timezone: String?
    
    /// Method to get X-Axis for the Chart display..
    ///
    /// - Returns: ChartAxisModel instance of SwiftCharts library..
    func getTimeXAxis() -> ChartAxisModel {
        
        // Set label according to timeInterval and device type.
        var labelSettings: ChartLabelSettings!
        switch timeInterval {
            case .month:
                if Utility.isIPhone() {
                    labelSettings = ChartLabelSettings(font: UIFont.systemFont(ofSize: 10.0, weight: .semibold))
                } else {
                    labelSettings = ChartLabelSettings(font: UIFont.systemFont(ofSize: 12.0, weight: .semibold))
                }
            default:
                labelSettings = ChartLabelSettings(font: ESPChartSettings.defaultLabel)
        }
        
        var firstModalValue = startTime
        var lastModalValue = endTime
            
        // Set X-Axis multiplier according to the time interval.
        var chartAxisValueGenerator: ChartAxisValuesGenerator?
        switch timeInterval {
            case .minute:
                chartAxisValueGenerator = ChartAxisGeneratorMultiplier(ESPChartsConstant.minuteTimestamp)
            case .hour:
                let daytimeStamp = startTime.getStartEndDate()
                firstModalValue = daytimeStamp.startDateTS
                lastModalValue = daytimeStamp.endDateTS
                chartAxisValueGenerator = ChartAxisGeneratorMultiplier(ESPChartsConstant.hourTimeStamp * 6)
            case .day:
                chartAxisValueGenerator = ChartAxisGeneratorMultiplier(ESPChartsConstant.dayTimeStamp)
                lastModalValue = lastModalValue - ESPChartsConstant.dayTimeStamp
            case .week:
                chartAxisValueGenerator = ChartAxisGeneratorMultiplier(ESPChartsConstant.weekTimestamp)
            case .month:
                chartAxisValueGenerator = ChartAxisGeneratorMultiplier(ESPChartsConstant.dayTimeStamp * 32)
            case .year:
                chartAxisValueGenerator = ChartAxisGeneratorMultiplier(ESPChartsConstant.weekTimestamp)
        }
        
        // Generate label for X-Axis.
        let labelsGeneratorX = ChartAxisLabelsGeneratorFunc {scalar in
            return ChartAxisLabel(text: getxAxisLabel(scalar: scalar), settings: labelSettings)
        }
        
        // Create ChartAxisModel for X-Axis.
        let xModel = ChartAxisModel(firstModelValue: firstModalValue, lastModelValue: lastModalValue, axisTitleLabels: [ChartAxisLabel(text:label, settings: labelSettings)], axisValuesGenerator: chartAxisValueGenerator!, labelsGenerator: labelsGeneratorX, leadingPadding: .fixed(ESPChartSettings.xAxisLeadingPadding), trailingPadding: .fixed(ESPChartSettings.xAxisTrailingPadding))
            
            
        return xModel
    }
    
    // Method to get fromatted string from timestamp.
    private func getxAxisLabel(scalar: Double) -> String {
        let xAxisFormatter = ESPXAxisNameFormater(timeInterval: timeInterval, timezone: timezone)
        return "\(xAxisFormatter.stringForValue(scalar))"
    }
}
