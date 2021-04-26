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
//  ESPYAxisGenerator.swift
//  ESPRainMaker
//

import Foundation
import SwiftCharts

// Generates Y-Axis for the chart display.
struct ESPYAxisGenerator {
    // Range of Y-Axis values
    var range: (firstValue: Double, lastValue: Double)
    
    /// Method to get Y-Axis for the Chart display.
    ///
    /// - Returns: ChartAxisModel of SwiftCharts library.
    func getYAxis() -> ChartAxisModel {
        
        let labelSettings = ChartLabelSettings(font: ESPChartSettings.defaultLabel)
        
        // Default multiplier
        var multiplier = 5.0
        // Set multiplier depending on the range of value
        if (range.lastValue - range.firstValue)/5.0 > 18.0 {
            multiplier = (range.lastValue - range.firstValue)/18.0
        }
        
        // Generate Y-Axis label
        let generator = ChartAxisGeneratorMultiplier(multiplier)
        let labelsGenerator = ChartAxisLabelsGeneratorFunc {scalar in
            return ChartAxisLabel(text: "\(scalar.roundToDecimal(2))", settings: labelSettings)
        }
        // Generate Y-Axis model
        let yModel = ChartAxisModel(firstModelValue: range.firstValue - multiplier, lastModelValue: range.lastValue + 5.0, axisTitleLabels: [], axisValuesGenerator: generator, labelsGenerator: labelsGenerator)
        
        return yModel
    }
    
}
