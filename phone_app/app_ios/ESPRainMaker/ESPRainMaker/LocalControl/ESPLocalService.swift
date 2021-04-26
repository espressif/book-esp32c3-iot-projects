// Copyright 2020 Espressif Systems
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
//  ESPLocalService.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation
import UIKit

/// Enum contains error cases that can occur while communicating on local network
enum ESPLocalServiceError {
    case httpError(Error)

    case failure(Status)

    case decodingError(Error)

    case encodingError(Error)

    case zeroProperty

    var description: String {
        switch self {
        case let .httpError(error):
            return "Error while sending HTTP request: \(error.localizedDescription)"
        case let .failure(status):
            return "Recieved failure response from device with status:\(status)"
        case let .decodingError(error):
            return "Error decoding device response:\(error.localizedDescription)"
        case let .encodingError(error):
            return "Error encoding device request:\(error.localizedDescription)"
        case .zeroProperty:
            return "Found no property in device response."
        }
    }
}

/// Class that provides interface for communicating with services on local network.
class ESPLocalService: NSObject {
    var netService: NetService
    var hostname = ""
    var espLocalDevice = ESPLocalDevice(name: "espDevice", security: .unsecure, transport: .softap)

    private let control_endpoint = "esp_local_ctrl/control"
    private var paramValues: [String: Any] = [:]
    private var propertyInfo: [String: Any] = [:]

    init(service: NetService) {
        netService = service
        hostname = service.hostName ?? ""
        espLocalDevice.espSoftApTransport = ESPSoftAPTransport(baseUrl: hostname)
        espLocalDevice.hostname = hostname
    }

    /// Method to provide property info of a device on local netowrk.
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func getPropertyInfo(completionHandler: @escaping ([String: Any]?, ESPLocalServiceError?) -> Swift.Void) {
        let data = try! createGetPropertyCountRequest()
        propertyInfo.removeAll()
        espLocalDevice.sendData(path: control_endpoint, data: data!) { response, error in
            if error != nil {
                completionHandler(nil, .httpError(error!))
                return
            }

            self.processGetPropertyCount(response: response!, completionHandler: completionHandler)
        }
    }

    /// Method to set parameter of a device.
    ///
    /// - Parameters:
    ///   - json: Key-value pair of property name and value.
    ///   - completionHandler: Callback that gives information on success/failure of set method.
    func setProperty(json: [String: Any], completionHandler: @escaping (Bool, ESPLocalServiceError?) -> Swift.Void) {
        let data = try! createSetPropertyInfoRequest(json: json)
        espLocalDevice.sendData(path: control_endpoint, data: data!) { response, error in
            if error != nil {
                completionHandler(false, .httpError(error!))
                return
            }
            self.processSetPropertyResponse(response: response!, completionHandler: completionHandler)
        }
    }

    private func getPropertyValues(count: UInt32, completionHandler: @escaping ([String: Any]?, ESPLocalServiceError?) -> Swift.Void) {
        if count < 1 {
            completionHandler(nil, .zeroProperty)
        } else {
            self.getPropertValue(count: count, currentCount: 0, completionHandler: completionHandler)
        }
    }
    
    private func getPropertValue(count: UInt32, currentCount:UInt32, completionHandler: @escaping ([String: Any]?, ESPLocalServiceError?) -> Swift.Void) {
        do {
            let propValRequest = try createGetPropertyValueRequest(index: currentCount)
            espLocalDevice.sendData(path: control_endpoint, data: propValRequest!) { response, error in
                if error != nil {
                    completionHandler(nil, .httpError(error!))
                    return
                }
                let processResult = self.processGetPropertyInfoResponse(response: response!, completionHandler: completionHandler)
                if count == currentCount + 1 {
                    if processResult {
                        completionHandler(self.propertyInfo, nil)
                    }
                } else {
                    self.getPropertValue(count: count, currentCount: currentCount+1, completionHandler: completionHandler)
                }
            }
        } catch {
            completionHandler(nil, .encodingError(error))
        }
    }

    private func createGetPropertyCountRequest() throws -> Data? {
        var request = LocalCtrlMessage()
        request.msg = LocalCtrlMsgType.typeCmdGetPropertyCount
        request.cmdGetPropCount = CmdGetPropertyCount()
        return try request.serializedData()
    }

    private func createSetPropertyInfoRequest(json: [String: Any]) throws -> Data? {
        var request = LocalCtrlMessage()
        request.msg = LocalCtrlMsgType.typeCmdSetPropertyValues
        var payload = CmdSetPropertyValues()
        var prop = PropertyValue()
        prop.index = 1
        let jsonData:Data!
        if #available(iOS 13.0, *) {
            jsonData = try! JSONSerialization.data(withJSONObject: json, options: .withoutEscapingSlashes)
        } else {
            // Fallback on earlier versions
            let data = try! JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
            let jsonStr = String(decoding: data, as: UTF8.self)
            jsonData = Data(jsonStr.replacingOccurrences(of: "\\/", with: "/").utf8)
        }
        prop.value = jsonData
        payload.props.append(prop)
        request.cmdSetPropVals = payload
        return try request.serializedData()
    }

    private func createGetPropertyValueRequest(index: UInt32) throws -> Data? {
        var request = LocalCtrlMessage()
        request.msg = LocalCtrlMsgType.typeCmdGetPropertyValues
        var payload = CmdGetPropertyValues()
        payload.indices.append(index)
        request.cmdGetPropVals = payload
        return try request.serializedData()
    }

    private func processGetPropertyCount(response: Data, completionHandler: @escaping ([String: Any]?, ESPLocalServiceError?) -> Swift.Void) {
        do {
            let response = try LocalCtrlMessage(serializedData: response)
            if response.respGetPropCount.status == .success {
                getPropertyValues(count: response.respGetPropCount.count, completionHandler: completionHandler)
            } else {
                completionHandler(nil, .failure(response.respGetPropCount.status))
            }
        } catch {
            completionHandler(nil, .decodingError(error))
        }
    }

    private func processSetPropertyResponse(response: Data, completionHandler: @escaping (Bool, ESPLocalServiceError?) -> Swift.Void) {
        do {
            let response = try LocalCtrlMessage(serializedData: response)
            if response.respSetPropVals.status == .success {
                completionHandler(true, nil)
            } else {
                completionHandler(false, .failure(response.respSetPropVals.status))
            }
        } catch {
            completionHandler(false, .decodingError(error))
        }
    }

    private func processGetPropertyInfoResponse(response: Data, completionHandler: @escaping ([String: Any]?, ESPLocalServiceError?) -> Swift.Void) -> Bool {
        do {
            let response = try LocalCtrlMessage(serializedData: response)
            if response.respGetPropVals.status == .success {
                let prop = response.respGetPropVals.props.first
                let json = try! JSONSerialization.jsonObject(with: prop!.value, options: .allowFragments) as! [String: Any]
                propertyInfo[prop?.name ?? ""] = json
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
}
