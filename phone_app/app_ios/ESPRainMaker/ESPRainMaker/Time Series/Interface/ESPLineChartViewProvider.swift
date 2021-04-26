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
//  ESPLineChartViewProvider.swift
//  ESPRainMaker
//

import Foundation
import SwiftCharts

struct ESPLineChartViewProvider {
    
    var tsArguments: ESPTSArguments
    var lineChartPoints: [ChartPoint]!
    var frame: CGRect
    var timezone: String?
    
    /// Method to get instance of Line Chart object.
    ///
    /// - Returns: `Chart` object with line plotting.
    func lineChart() -> Chart {
        
        // Configure X-Axis for different time duration
        var xModel: ChartAxisModel!
        switch tsArguments.timeInterval {
            case .week:
            xModel = ESPTimeAxisGenerator(timeInterval: tsArguments.timeInterval, startTime: Double(lineChartPoints[0].x.scalar), endTime: Double(tsArguments.duration.endTime), label: "", timezone: timezone).getTimeXAxis()
            case .hour:
                xModel = ESPTimeAxisGenerator(timeInterval: tsArguments.timeInterval, startTime: Double(tsArguments.duration.startTime), endTime: Double(tsArguments.duration.endTime), label: "", timezone: timezone).getTimeXAxis()
            default:
                xModel = ESPTimeAxisGenerator(timeInterval: tsArguments.timeInterval, startTime: Double(tsArguments.duration.startTime), endTime: Double(tsArguments.duration.endTime), label: "", timezone: timezone).getTimeXAxis()
        }
        
        // Prepare Y-Axis using Chart data.
        var yValues:[Double] = []
        for data in lineChartPoints {
            yValues.append(data.y.scalar)
        }
        let yModel = ESPYAxisGenerator(range: (yValues.min() ?? 0,yValues.max() ?? 50)).getYAxis()
        
        // Set Chart properties
        let chartFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height - 100.0)
        let chartSettings = Env.iPad ? ESPChartSettings.iPadChartSettings:ESPChartSettings.iPhoneChartSettings
        // Generate axes layers and calculate chart inner frame, based on the axis models
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer, coordsSpace.chartInnerFrame)
        
        let lineModel = ChartLineModel(chartPoints: lineChartPoints, lineColors: [AppConstants.shared.getBGColor()], lineWidth: 3, animDuration: 1, animDelay: 0)
        let chartPointsLineLayer = ChartPointsLineLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, lineModels: [lineModel], pathGenerator: CatmullPathGenerator())
        
        let settings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.black, linesWidth: 0.1)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxisLayer: xAxisLayer, yAxisLayer: yAxisLayer, settings: settings)
        
        let chart = Chart(
            frame: chartFrame,
            innerFrame: innerFrame,
            settings: chartSettings,
            layers: [
                xAxisLayer,
                yAxisLayer,
                guidelinesLayer,
                chartPointsLineLayer
            ]
        )
        
        return chart
        
    }
}
