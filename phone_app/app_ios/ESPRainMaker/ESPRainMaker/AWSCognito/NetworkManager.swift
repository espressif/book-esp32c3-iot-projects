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
//  APIClient.swift
//  ESPRainMaker
//

import Alamofire
import Foundation
import JWTDecode

class NetworkManager {
    /// A singleton class that manages Network call for this application
    static let shared = NetworkManager()
    var session: Session!
    let apiManager = ESPAPIManager()

    // MARK: - Node APIs

    /// Method to fetch node and devices associated with the user
    ///
    /// - Parameters:
    ///   - completionHandler: after response is parsed this block will be called with node array and error(if any) as argument
    func getNodes(completionHandler: @escaping ([Node]?, ESPNetworkError?) -> Void) {
        apiManager.getNodes(completionHandler: completionHandler)
    }

    /// Get node info like device list, param list and online/offline status
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node info is recieved
    func getNodeInfo(nodeId: String, completionHandler: @escaping (Node?, ESPNetworkError?) -> Void) {
        if Configuration.shared.appConfiguration.supportLocalControl, let availableService = User.shared.localServices[nodeId] {
            availableService.getPropertyInfo { response, error in
                if error != nil {
                    if ESPNetworkMonitor.shared.isConnectedToNetwork {
                        self.getNodeInfoPrivate(nodeId: nodeId, completionHandler: completionHandler)
                    } else {
                        completionHandler(nil, .localServerError(error!))
                    }
                    return
                }
                var responseJSON = response!
                if nodeId.count > 0 {
                    responseJSON["id"] = nodeId
                }
                if let node = JSONParser.parseNodeArray(data: [responseJSON], forSingleNode: true)?[0] {
                    node.node_id = nodeId
                    if node.devices?.count ?? 0 < 1 {
                        completionHandler(nil, .unknownError)
                    } else {
                        completionHandler(node, nil)
                    }
                    return
                }
                completionHandler(nil, .emptyConfigData)
            }
        } else {
            getNodeInfoPrivate(nodeId: nodeId, completionHandler: completionHandler)
        }
    }

    private func getNodeInfoPrivate(nodeId: String, completionHandler: @escaping (Node?, ESPNetworkError?) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            apiManager.getNodeInfo(nodeId: nodeId, completionHandler: completionHandler)
        } else {
            completionHandler(nil, .noNetwork)
        }
    }

    /// Method to fetch online/offline status of associated nodes
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node status is recieved
    func getNodeStatus(node: Node, completionHandler: @escaping (Node?, Error?) -> Void) {
        apiManager.getNodeStatus(node: node, completionHandler: completionHandler)
    }

    // MARK: - Device Association

    /// Method to send request of adding device to currently active user
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to add device to user is recieved with id of the request
    func addDeviceToUser(parameter: [String: String], completionHandler: @escaping (String?, ESPNetworkError?) -> Void) {
        apiManager.addDeviceToUser(parameter: parameter, completionHandler: completionHandler)
    }

    /// Method to fetch device assoication staus
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which association status is fetched
    ///   - completionHandler: handler called when response to deviceAssociationStatus is recieved
    func deviceAssociationStatus(nodeID: String, requestID: String, completionHandler: @escaping (String) -> Void) {
        apiManager.deviceAssociationStatus(nodeID: nodeID, requestID: requestID, completionHandler: completionHandler)
    }

    // MARK: - Thing Shadow

    /// Method to get device parameter values
    ///
    /// - Parameters:
    ///   - device: Device for which get param is required
    ///   - completionHandler: handler called when response to getDeviceParam is recieved
    func getDeviceParam(device: Device, completionHandler: @escaping (ESPNetworkError?) -> Void) {
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.paramUpdateNotification)))
        if Configuration.shared.appConfiguration.supportLocalControl {
            if let nodeid = device.node?.node_id {
                if let availableService = User.shared.localServices[nodeid] {
                    availableService.getPropertyInfo { response, error in
                        if error != nil {
                            if ESPNetworkMonitor.shared.isConnectedToNetwork {
                                self.getDeviceParamPrivate(device: device, completionHandler: completionHandler)
                            } else {
                                completionHandler(.localServerError(error!))
                            }
                            return
                        }
                        if let params = response!["params"] as? [String:Any], let deviceName = device.name, let attributes = params[deviceName] as? [String: Any] {
                            device.deviceName = deviceName
                            if let params = device.params {
                                for index in params.indices {
                                    if let reportedValue = attributes[params[index].name ?? ""] {
                                        if params[index].type == Constants.deviceNameParam {
                                            device.deviceName = reportedValue as? String ?? deviceName
                                        }
                                        params[index].value = reportedValue
                                    }
                                }
                            }
                            completionHandler(nil)
                        } else {
                            completionHandler(nil)
                        }
                    }
                } else {
                    getDeviceParamPrivate(device: device, completionHandler: completionHandler)
                }
            }
        } else {
            getDeviceParamPrivate(device: device, completionHandler: completionHandler)
        }
    }

    private func getDeviceParamPrivate(device: Device, completionHandler: @escaping (ESPNetworkError?) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            apiManager.getDeviceParams(device: device, completionHandler: completionHandler)
        } else {
            completionHandler(.noNetwork)
        }
    }

    /// Method to update device thing shadow
    /// Any changes of the device params from the app trigger this method
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which thing shadow is updated
    ///   - completionHandler: handler called when response to setDeviceParam is recieved
    func setDeviceParam(nodeID: String?, parameter: [String: Any], completionHandler: @escaping (ESPCloudResponseStatus) -> Void) {
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.paramUpdateNotification)))
        if Configuration.shared.appConfiguration.supportLocalControl {
            if let nodeid = nodeID {
                if let availableService = User.shared.localServices[nodeid] {
                    availableService.setProperty(json: parameter) { success, _ in
                        if !success {
                            self.setDeviceParamPrivate(nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
                        }
                    }
                } else {
                    setDeviceParamPrivate(nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
                }
            }
        } else {
            setDeviceParamPrivate(nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
        }
    }

    private func setDeviceParamPrivate(nodeID: String?, parameter: [String: Any], completionHandler: @escaping (ESPCloudResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            apiManager.setDeviceParam(nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
        } else {
            completionHandler(.failure)
        }
    }

    // MARK: - Generic Request

    /// Method to make generic api request
    ///
    /// - Parameters:
    ///   - url: URL of the api
    ///   - method: HTTPMethod like post, get, etc.
    ///   - parameters: Parameter to be included in the api call
    ///   - encoding: ParameterEncoding
    ///   - header: HTTp headers
    ///   - completionHandler: Callback invoked after api response is recieved
    func genericRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters, encoding: ParameterEncoding, headers: HTTPHeaders, completionHandler: @escaping ([String: Any]?) -> Void) {
        apiManager.genericRequest(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, completionHandler: completionHandler)
    }

    /// Method to make generic authorized request
    ///
    /// - Parameters:
    ///   - url: URL of the api
    ///   - parameters: Parameter to be included in the api call
    ///   - completionHandler: Callback invoked after api response is recieved
    func genericAuthorizedDataRequest(url: String, parameter: [String: Any]?, completionHandler: @escaping (Data?, ESPNetworkError?) -> Void) {
        apiManager.genericAuthorizedDataRequest(url: url, parameter: parameter, completionHandler: completionHandler)
    }
}
