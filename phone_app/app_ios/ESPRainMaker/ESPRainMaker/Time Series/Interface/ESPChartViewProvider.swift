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
//  ESPChartViewProvider.swift
//  ESPRainMaker
//

import Foundation
import SwiftCharts

struct ESPChartViewProvider {
    
    var tsArguments: ESPTSArguments
    let tsManager = ESPTimeSeriesAPIManager()
    var device: Device
    var param: Param

    func getChartView(frame: CGRect, completionHandler: @escaping (Chart?, [ChartPoint]?) -> Void) {
        fetchTSData { tsData in
            DispatchQueue.main.async {
                let chartData = ESPChartDataProvider(tsData: tsData)
                switch tsArguments.chartType {
                    case .lineChart:
                    var lineChartViewProvider = ESPLineChartViewProvider(tsArguments: tsArguments, frame: frame, timezone: nil)
                    if let tuples = chartData.getTuples(), tuples.count > 0 {
                        lineChartViewProvider.lineChartPoints = tuples
                        completionHandler(lineChartViewProvider.lineChart(), tuples)
                    }
                    completionHandler(nil, nil)
                    case .barChart:
                    let barChartData = ESPChartDataProvider(tsData: tsData)
                    var barChartViewProvider = ESPBarChartViewProvider(tsArguments: tsArguments, frame: frame, timezone: nil)
                    if let tuples = barChartData.getTuples(), tuples.count > 0 {
                        barChartViewProvider.barChartPoints = tuples
                        completionHandler(barChartViewProvider.barsChart(), tuples)
                    }
                    completionHandler(nil, nil)
                }
            }
        }
    }
    
    private func fetchTSData(completionHandler: @escaping (ESPTSData?) -> Void) {
        tsManager.fetchTSDataFor(nodeID: device.node?.node_id ?? "", paramName: (device.name ?? "") + "." + (param.name ?? ""), aggregate: tsArguments.aggregate.rawValue, timeInterval:tsArguments.timeInterval.rawValue, startTime: tsArguments.duration.startTime, endTime: tsArguments.duration.endTime) { tsData in
            completionHandler(tsData)
        }
    }
}
