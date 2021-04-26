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
//  CommonDeviceServices+Utils.swift
//  ESPRainMaker
//

import Foundation
import UIKit

/// Enum with states for response from cloud regarding the param API response
enum ESPServiceAPIResponseStatus {
    
    case success(Bool) //API success with flag giving info on whether some nodes failed or not true for success and false for no nodes failed
    case failure //API failure
}

protocol CommonDeviceServicesProtocol {
    func getDeviceListFromActions(action: [String: [Device]], availableDevices: [String: Device], forNodes nodes: [ESPCloudResponse]) -> String
    func getServiceKeys(id: String, serviceType: DeviceServiceType) -> (String, String)
    func callParamsAPIWithActions(apiManager: ESPAPIManager, list: [[String: Any]], actions: [String: [Device]], onView: UIView, text: String, availableDevices: [String: Device], completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void)
    func handleResponse(cloudResponse: [ESPCloudResponse]?, actions: [String: [Device]], onView: UIView, errorText: String,  availableDevices: [String: Device], completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void)
    func getActionList(availableDevices: [String: Device]) -> String
    func resetAvailableDeviceStatus(availableDevices: inout [String: Device])
    func invokeServiceAction(apiManager: ESPAPIManager, keys: [String], jsonString: [String: Any], text: String, nodeIdKey: String, payloadKey: String, actions: [String: [Device]], availableDevices: [String: Device], serviceType: DeviceServiceType, isSave: Bool, onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void)
}

extension CommonDeviceServicesProtocol {
    
    /// Get device names of nodes which schedule or scene operation is performed
    func getDeviceListFromActions(action: [String: [Device]], availableDevices: [String: Device], forNodes nodes: [ESPCloudResponse]) -> String {
        var deviceNames: [String] = [String]()
        nodes.forEach {
            if let node_id = $0.node_id, let devices = action[node_id] {
                devices.forEach {
                    let key = [node_id, $0.name].compactMap { $0 }.joined(separator: ".")
                    if let availableDevice = availableDevices[key] {
                        deviceNames.append(availableDevice.deviceName)
                    } else {
                        deviceNames.append($0.name ?? "")
                    }
                }
            }
        }
        return deviceNames.joined(separator: ", ")
    }
    
    /// Method returns the service & param name for scenes or schedules
    ///
    /// - Parameter id: node id
    /// - Parameter serviceType: type of service (.scene/.schedule)
    /// - Returns: service name, param name
    func getServiceKeys(id: String, serviceType: DeviceServiceType) -> (String, String) {
        if serviceType == .schedule {
            if let node = User.shared.getNode(id: id) {
                return (node.scheduleName, node.schedulesName)
            }
            return (Constants.scheduleKey, Constants.schedulesKey)
        }
        if let node = User.shared.getNode(id: id) {
            return (node.sceneName, node.scenesName)
        }
        return (Constants.sceneKey, Constants.scenesKey)
    }
    
    /// Call multi params API and process the response and send response status via callback or show error message
    ///
    /// - Parameters:
    ///   - list: list of user actions
    ///   - actions: dictionary of node ids and their devices
    ///   - onView: UIView to show message in case of failure.
    ///   - text: error text to be shown
    ///   - completionHandler: Callback invoked after api response is recieved
    func callParamsAPIWithActions(apiManager: ESPAPIManager, list: [[String: Any]], actions: [String: [Device]], onView: UIView, text: String, availableDevices: [String: Device], completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        apiManager.setMultipleDeviceParam(parameter: list) { cloudResponse, error in
            if error == nil {
                self.handleResponse(cloudResponse: cloudResponse, actions: actions, onView: onView, errorText: text, availableDevices: availableDevices, completionHandler: completionHandler)
            } else {
                completionHandler(.failure)
            }
        }
    }
    
    /// Handle response from cloud
    ///
    /// - Parameters:
    ///   - cloudResponse: list of ESPCloudResponse objects
    ///   - actions: dictionary of node ids and their devices
    ///   - onView: UIView to show message in case of failure.
    ///   - errorText: error text to be shown
    ///   - completionHandler: Callback invoked after api response is recieved
    func handleResponse(cloudResponse: [ESPCloudResponse]?, actions: [String: [Device]], onView: UIView, errorText: String,  availableDevices: [String: Device], completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        var failureString = ""
        if let response = cloudResponse, response.count > 0 {
            let (successResponse: successNodes, failureResponse: failedNodes) = ESPCloudResponseParser().getNodesWithStatus(response: response)
            if failedNodes.count > 0 {
                failureString = self.getDeviceListFromActions(action: actions, availableDevices: availableDevices, forNodes: failedNodes)
            }
            if successNodes.count > 0 {
                if failureString.count > 0 {
                    Utility.showToastMessage(view: onView, message: "\(errorText) \(failureString)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        completionHandler(.success(true))
                    }
                } else {
                    completionHandler(.success(false))
                }
            } else {
                completionHandler(.failure)
            }
        }
    }
    
    /// Gives list of devices under a schedule or scene.
    ///
    /// - Parameter availableDevices: available devices for schedule or scene
    /// - Returns: Comma seperated string of devices that are part of a particular schedule or scene
    func getActionList(availableDevices: [String: Device]) -> String {
        var actionList: [String] = []
        for device in availableDevices.values {
            if device.selectedParams > 0 {
                actionList.append(device.deviceName)
            }
        }
        if actionList.count > 0 {
            actionList = actionList.sorted(by: <)
            return actionList.compactMap { $0 }.joined(separator: ", ")
        } else {
            return ""
        }
    }
    
    /// Reset avaialble devices list
    ///
    /// - Parameter availableDevices: List of available devices
    func resetAvailableDeviceStatus(availableDevices: inout [String: Device]) {
        for device in availableDevices.values {
            device.selectedParams = 0
            device.collapsed = true
            if let params = device.params {
                for param in params {
                    param.selected = false
                }
            }
        }
    }
    
    /// Call params API and send response via callback
    ///
    /// - Parameters:
    ///   - apiManager: ESPAPIManager instance
    ///   - keys: actions keys
    ///   - jsonString: param body
    ///   - text: error text message
    ///   - nodeIdKey: node id key
    ///   - payloadKey: payload key
    ///   - actions: service actions
    ///   - availableDevices: available devices
    ///   - serviceType: device service type
    ///   - isSave: is save action invoked
    ///   - onView: UIView where error is to be displayed
    ///   - completionHandler: callback to be invoked when API response is recevied
    func invokeServiceAction(apiManager: ESPAPIManager, keys: [String], jsonString: [String: Any], text: String, nodeIdKey: String, payloadKey: String, actions: [String: [Device]], availableDevices: [String: Device], serviceType: DeviceServiceType, isSave: Bool, onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        var actionsList = [[String: Any]]()
        var json = jsonString
        keys.forEach {
            if isSave {
                var deviceJSON: [String: Any] = [:]
                actions[$0]!.forEach {
                    var actionJSON: [String: Any] = [:]
                    $0.params!.filter { $0.selected == true }
                        .forEach {
                            if let name = $0.name, let value = $0.value {
                                actionJSON[name] = value
                            }
                        }
                    if let name = $0.name {
                        deviceJSON[name] = actionJSON
                    }
                }
                json["action"] = deviceJSON
            }
            let (serviceKey, paramsKey)  = getServiceKeys(id: $0, serviceType: serviceType)
            let payload = [serviceKey: [paramsKey: [json]]]
            actionsList.append([nodeIdKey: $0 as Any,
                                payloadKey: payload as Any])
        }
        callParamsAPIWithActions(apiManager: apiManager, list: actionsList, actions: actions, onView: onView, text: text, availableDevices: availableDevices) { result  in
            completionHandler(result)
        }
    }
}
