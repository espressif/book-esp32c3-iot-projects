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
//  ESPChartDataProvider.swift
//  ESPRainMaker
//

import Foundation
import SwiftCharts

struct ESPChartDataProvider {
   
    var tsData: ESPTSData?
    
    /// Method to get points to plot chart data from the time series API response.
    ///
    /// - Returns: Array of ChartPoint instances.
    func getTuples() -> [ChartPoint]? {
        guard let data = tsData, let params = data.params, let values = params[0].values else {
            return nil
        }
        var chartPoints:[ChartPoint] = []
        for value in values {
            chartPoints.append(ChartPoint(x: ChartAxisValueDouble(value.ts!), y: ChartAxisValueDouble(value.val!.roundToDecimal(2))))
        }
        return chartPoints
    }
}
