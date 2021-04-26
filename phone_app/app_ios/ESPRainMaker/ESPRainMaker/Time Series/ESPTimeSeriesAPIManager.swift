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
//  ESPTimeSeriesAPIManager.swift
//  ESPRainMaker
//

import Foundation

class ESPTimeSeriesAPIManager {
    
    var atleastOnce = true
    
    let tsDataURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/tsdata"
    lazy var apiManager = ESPAPIManager()
    var dataSource: ESPTSDataList?
    
    /// Method to fetch time series data using API.
    ///
    /// - Parameters:
    ///   - nodeID: Node ID of device whose params data need to be fetched.
    ///   - paramName: Name of device parameter.
    ///   - aggregate: Aggregate for a certain time duration like avgerage, minimum, maximum , etc.
    ///   - timeInterval: Time interval aggregate like hour, day, week , etc.
    ///   - startTime: Timestamp for start of duration.
    ///   - endTime: Timestamp for end of duration.
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func fetchTSDataFor(nodeID: String, paramName: String, aggregate: String? = nil, timeInterval: String? = nil, startTime: UInt? = nil, endTime: UInt? = nil, completionHandler: @escaping (ESPTSData?) -> Void ) {
        
        var url = tsDataURL + "?node_id=\(nodeID)&param_name=\(paramName)"
        if let aggregate = aggregate {
            url.append("&aggregate=\(aggregate)")
        }
        if let timeInterval = timeInterval {
            url.append("&time_interval=\(timeInterval)")
        }
        if let startTime = startTime {
            url.append("&start_time=\(startTime)")
        }
        if let endTime = endTime {
            url.append("&end_time=\(endTime)")
        }
        
        let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        apiManager.genericAuthorizedDataRequest(url: urlString ?? url, parameter: nil, method: .get) { response, error in
            guard let result = ESPTSData.decoder(data: response) else {
                completionHandler(nil)
                return
            }
            if let nextID = result.next_id {
                self.fetchNextRecordSet(url: urlString ?? url, nodeID: nodeID, paramName: paramName, startID: nextID, tsData: result, completionHandler: completionHandler)
            } else {
                completionHandler(result)
            }
        }
    }
    
    
    private func fetchNextRecordSet(url: String, nodeID: String, paramName: String, startID: String, tsData: ESPTSData, completionHandler: @escaping (ESPTSData?) -> Void) {
        let urlString = url + "&start_id=\(startID)"
        apiManager.genericAuthorizedDataRequest(url: urlString, parameter: nil, method: .get) { response, error in
            guard let result = ESPTSData.decoder(data: response) else {
                completionHandler(tsData)
                return
            }
            var joinedTSData = tsData
            joinedTSData.params?.append(contentsOf: result.params ?? [])
            if let nextID = result.next_id {
                self.fetchNextRecordSet(url: url, nodeID: nodeID, paramName: paramName, startID: nextID, tsData: joinedTSData, completionHandler: completionHandler)
            } else {
                completionHandler(joinedTSData)
            }
        }
    }
}
