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
//  ESPBarChartViewProvider.swift
//  ESPRainMaker
//

import Foundation
import SwiftCharts

struct ESPBarChartViewProvider {
    var tsArguments: ESPTSArguments
    var frame: CGRect
    var barChartPoints: [ChartPoint]!
    var timezone:String?
    
    /// Method to get instance of Bar Chart object.
    ///
    /// - Returns: `Chart` object with Bar plotting.
    func barsChart() -> Chart {
        
        let barViewGenerator = {(chartPointModel: ChartPointLayerModel, layer: ChartPointsViewsLayer, chart: Chart) -> UIView? in
            let bottomLeft = layer.modelLocToScreenLoc(x: 0, y: 0)
            
            let barWidth = self.calculateBarWidth()
            
            let settings = ChartBarViewSettings(animDuration: 0.5)
            
            let (p1, p2): (CGPoint, CGPoint) = {
                return (CGPoint(x: chartPointModel.screenLoc.x, y: bottomLeft.y), CGPoint(x: chartPointModel.screenLoc.x, y: chartPointModel.screenLoc.y))
            }()
            let chartPointViewBar = ChartPointViewBar(p1: p1, p2: p2, width: barWidth, bgColor: AppConstants.shared.getBGColor(), settings: settings)
            chartPointViewBar.cornerRadius = 4.0
            chartPointViewBar.addGradientLayer()
            return chartPointViewBar
        }
        
        // Set Chart properties
        let chartFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height - 100.0)
        var chartSettings = Env.iPad ? ESPChartSettings.iPadChartSettings:ESPChartSettings.iPhoneChartSettings
        chartSettings.zoomPan.panEnabled = true
        chartSettings.zoomPan.zoomEnabled = true
        
        // Configure X-Axis for different time duration
        var xModel: ChartAxisModel!
        switch tsArguments.timeInterval {
            case .week:
                xModel = ESPTimeAxisGenerator(timeInterval: tsArguments.timeInterval, startTime: Double(barChartPoints[0].x.scalar), endTime: Double(tsArguments.duration.endTime), label: "", timezone: timezone).getTimeXAxis()
            case .hour:
                xModel = ESPTimeAxisGenerator(timeInterval: tsArguments.timeInterval, startTime: Double(tsArguments.duration.startTime), endTime: Double(tsArguments.duration.endTime), label: "", timezone: timezone).getTimeXAxis()
            default:
                xModel = ESPTimeAxisGenerator(timeInterval: tsArguments.timeInterval, startTime: Double(tsArguments.duration.startTime), endTime: Double(tsArguments.duration.endTime), label: "", timezone: timezone).getTimeXAxis()
        }
        
        // Prepare Y-Axis using Chart data.
        var yValues:[Double] = []
        for data in barChartPoints {
            yValues.append(data.y.scalar)
        }
        let yModel = ESPYAxisGenerator(range: (yValues.min() ?? 0,yValues.max() ?? 50)).getYAxis()

        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer, coordsSpace.chartInnerFrame)
        
        let chartPointsLayer = ChartPointsViewsLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, chartPoints: barChartPoints, viewGenerator: barViewGenerator)
        
        let settings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.black, linesWidth: 0.1)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxisLayer: xAxisLayer, yAxisLayer: yAxisLayer, settings: settings)
        
        return Chart(
            frame: chartFrame,
            innerFrame: innerFrame,
            settings: chartSettings,
            layers: [
                xAxisLayer,
                yAxisLayer,
                guidelinesLayer,
                chartPointsLayer
            ]
        )
    }
    
    /// Method to calculate width of each Bar in chart.
    ///
    /// - Returns: Width of each Bar in chart.
    private func calculateBarWidth() -> CGFloat {
        
        var barWidth = 20.0
        if Env.iPad {
            barWidth = 25.0
        }
        
        let chartWidth = frame.width - 100.0
        
        switch tsArguments.timeInterval {
            case .hour:
                barWidth = min(chartWidth/CGFloat(barChartPoints.count), chartWidth/24.0)
            case .day:
                barWidth = min(chartWidth/CGFloat(barChartPoints.count), 20.0)
            case .month:
            barWidth = min(chartWidth/CGFloat(barChartPoints.count), chartWidth/14.0)
           default:
                break
        }
        return barWidth
    }
}
