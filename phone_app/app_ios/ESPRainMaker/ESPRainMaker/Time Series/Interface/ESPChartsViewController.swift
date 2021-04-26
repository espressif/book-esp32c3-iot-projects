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
//  ESPChartsViewController.swift
//  ESPRainMaker
//

import UIKit
import SwiftCharts



class ESPChartsViewController: UIViewController {

    let tsManager = ESPTimeSeriesAPIManager()
    var param: Param!
    var device: Device!
    var espTSArguments = ESPTSArguments(aggregate: .avg, timeInterval: .hour)
    var chart: Chart?
    
    // IBOutlets
    @IBOutlet var durationSegmentControl: UISegmentedControl!
    @IBOutlet var aggregrateSegmentControl: UISegmentedControl!
    @IBOutlet var chartTypeSegmentControl: UISegmentedControl!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var aggregateLabel: UILabel!
    @IBOutlet var timeIntervalLabel: UILabel!
    @IBOutlet weak var chartContainerView: UIView!
    @IBOutlet var noChartDataLabel: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up segment control
        configureSegements()
        setSegmentAppearance()
        
        // Add screen title
        titleLabel.text = param.name ?? ""
        // Customise chart appearance
        chartContainerView.addDropShadow()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadChart()
    }
    
    
    // MARK: - IBActions

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func segmentChange(sender: UISegmentedControl) {
        let timeIntervalString = sender.titleForSegment(at: sender.selectedSegmentIndex)
        let segmentDuration = ESPTimeDurationSegment.init(rawValue: timeIntervalString ?? "1D")
        espTSArguments.timeInterval = segmentDuration?.getTimeIntterval() ?? .hour
        espTSArguments.setLatestDuration()
        checkNextButtonVisibility()
        loadChart()
    }
    
    @IBAction func aggregateSegmentChange(sender: UISegmentedControl) {
        if let aggregateString = sender.titleForSegment(at: sender.selectedSegmentIndex), let aggregrate = ESPAggregate(rawValue: aggregateString) {
            espTSArguments.aggregate = aggregrate
            switch aggregrate {
                case .max, .min, .avg, .count:
                    durationSegmentControl.setEnabled(true, forSegmentAt: ESPTimeDurationSegment.allCases.count - 1)
                case .latest, .raw:
                    durationSegmentControl.setEnabled(false, forSegmentAt: ESPTimeDurationSegment.allCases.count - 1)
                if espTSArguments.timeInterval == .year {
                    durationSegmentControl.selectedSegmentIndex = 0
                }
            }
            loadChart()
        }
    }
    
    
    @IBAction func chartTypeSegmentChange(sender: UISegmentedControl) {
        let aggregateString = sender.titleForSegment(at: sender.selectedSegmentIndex)
        switch aggregateString {
            case "Bar":
            espTSArguments.chartType = .barChart
            case "Line":
                espTSArguments.chartType = .lineChart
            default:
                break
        }
        loadChart()
    }

    @IBAction func getNextIntervalData(_ sender: Any) {
        espTSArguments.duration = espTSArguments.getNextDuration()
        loadChart()
        checkNextButtonVisibility()
    }
    
    @IBAction func getPreviousIntervalData(_ sender: Any) {
        espTSArguments.duration = espTSArguments.getPreviousDuration()
        loadChart()
        checkNextButtonVisibility()
    }
    
    // MARK: - Private Methods
    
    // Method to plot chart
    private func loadChart() {
        self.chart?.clearView()
        clearLabels()
        // Disable user interaction for current view controller till data for specified period is fetched.
        scrollView.isUserInteractionEnabled = false
        // Start loading chart
        Utility.showLoader(message: "", view: chartContainerView)
        let espChartViewProvider = ESPChartViewProvider(tsArguments: espTSArguments, device: device, param: param)
        let timeLabelGenerator = ESPTimeLabelGenerator(tsArgument: espTSArguments)
        dateLabel.text = timeLabelGenerator.getTimeLabel()
        espChartViewProvider.getChartView(frame: chartContainerView.frame) { chart, chartPoints in
            DispatchQueue.main.async { [self] in
                // Enable user interaction
                self.scrollView.isUserInteractionEnabled = true
                Utility.hideLoader(view: self.chartContainerView)
                guard let chartView = chart?.view else {
                    return
                }
                self.setLabelText(chartPoint: chartPoints)
                self.provideConstraints(onView: chartView)
                self.chart = chart
            }
        }
    }
    
    // Set constraint for chart display
    private func provideConstraints(onView: UIView) {
        onView.backgroundColor = .white
        chartContainerView.addSubview(onView)
    }
    
    // Clears label for chart related info
    private func clearLabels() {
        valueLabel.text = ""
        aggregateLabel.text = ""
        timeIntervalLabel.text = ""
    }
    
    // Method to configure segment control
    private func configureSegements() {
        // Configure segments for time duration
        durationSegmentControl.removeAllSegments()
        for (index, element) in ESPTimeDurationSegment.allCases.enumerated() {
            durationSegmentControl.insertSegment(withTitle: element.rawValue, at: index, animated: false)
        }
        durationSegmentControl.selectedSegmentIndex = 0
        
        // Configure segments for data aggregate
        aggregrateSegmentControl.removeAllSegments()
        for (index, element) in ESPAggregate.allCases.enumerated() {
            aggregrateSegmentControl.insertSegment(withTitle: element.rawValue, at: index, animated: false)
        }
        aggregrateSegmentControl.selectedSegmentIndex = 0
        
        // Configure segments for chart type
        chartTypeSegmentControl.removeAllSegments()
        for (index, element) in ESPChartType.allCases.enumerated() {
            chartTypeSegmentControl.insertSegment(withTitle: element.rawValue, at: index, animated: false)
        }
        chartTypeSegmentControl.selectedSegmentIndex = 0
    }
    
    // Method to customise segment appearance
    private func setSegmentAppearance() {
        // Set appearance for time duration segments
        durationSegmentControl.selectedSegmentIndex = 0
        let currentBGColor = AppConstants.shared.getBGColor()
        durationSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .bold)], for: .normal)
        durationSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20.0, weight: .heavy)], for: .selected)
        durationSegmentControl.backgroundColor = currentBGColor
        
        // Set appearance for aggregate segments
        aggregrateSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .heavy)], for: .selected)
        aggregrateSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .bold)], for: .normal)
        aggregrateSegmentControl.backgroundColor = .white
        aggregrateSegmentControl.borderColor = currentBGColor
        aggregrateSegmentControl.borderWidth = 1.0
        if #available(iOS 13.0, *) {
            aggregrateSegmentControl.selectedSegmentTintColor = currentBGColor
        } else {
            // Fallback on earlier versions
            aggregrateSegmentControl.tintColor = currentBGColor
        }
        let backgroundImage = UIImage.getColoredRectImageWith(color: UIColor.white.cgColor, andSize: aggregrateSegmentControl.bounds.size)
        let selectedImage = UIImage.getColoredRectImageWith(color: currentBGColor.cgColor, andSize: aggregrateSegmentControl.bounds.size)
        aggregrateSegmentControl.setBackgroundImage(backgroundImage, for: .normal, barMetrics: .default)
        aggregrateSegmentControl.setBackgroundImage(selectedImage, for: .selected, barMetrics: .default)
        
        // Set appearance for chart type segment
        chartTypeSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .heavy)], for: .selected)
        chartTypeSegmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: .bold)], for: .normal)
        chartTypeSegmentControl.backgroundColor = .white
        chartTypeSegmentControl.borderColor = currentBGColor
        chartTypeSegmentControl.borderWidth = 1.0
        if #available(iOS 13.0, *) {
            chartTypeSegmentControl.selectedSegmentTintColor = currentBGColor
        } else {
            // Fallback on earlier versions
            chartTypeSegmentControl.tintColor = currentBGColor
        }
    }
    
    // Method to set data information below chart display
    private func setLabelText(chartPoint: [ChartPoint]?) {
        if let chartPoints = chartPoint {
            // Show data based on aggregate
            switch espTSArguments.aggregate {
            case .min:
                // Get minimum value from all data points
                if let min = chartPoints.min(by: { $0.y.scalar < $1.y.scalar}) {
                    valueLabel.text = "\(min.y.scalar)"
                }
                aggregateLabel.text = "Min " + (param.name ?? "")
            case .max:
                // Get maximum value for all data points
                if let max = chartPoints.max(by: { $0.y.scalar < $1.y.scalar}) {
                    valueLabel.text = "\(max.y.scalar)"
                }
                aggregateLabel.text = "Max " + (param.name ?? "")
            case .latest:
                // Get latest value from all data points
                if let latest = chartPoints.last?.y {
                    valueLabel.text = "\(latest.scalar)"
                }
                aggregateLabel.text = "Latest " + (param.name ?? "")
            case .count:
                // Get total count of data points
                valueLabel.text = "\(chartPoints.count)"
                aggregateLabel.text = (param.name ?? "") + " num of records."
            case .avg:
                // Calculate average of sum of data points
                let sum = chartPoints.map({ $0.y.scalar}).reduce(0, +)
                let avg = (sum/Double(chartPoints.count)).roundToDecimal(2)
                valueLabel.text = "\(avg)"
                aggregateLabel.text = "Avg " + (param.name ?? "")
            default:
                break
            }
            
            timeIntervalLabel.text = espTSArguments.timeInterval.getStringInfo()
        }
    }
    
    // Checks if next button should be visible based on current duration
    private func checkNextButtonVisibility() {
        let endDate = Date(timeIntervalSince1970: TimeInterval(espTSArguments.duration.endTime))
        if Calendar.gmtCalendar().isDateInToday(endDate) || endDate > Date() {
            nextButton.isHidden = true
        } else {
            nextButton.isHidden = false
        }
    }
    

}

