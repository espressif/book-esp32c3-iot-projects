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
//  ESPAPIManager.swift
//  ESPRainMaker
//

import Alamofire
import Foundation
import JWTDecode

class ESPAPIManager: ESPNoRefreshTokenLogic {
    /// A  class that manages API call for this application
    var session: Session!

    init() {
        // Validate api calls with server certificate
        let certificate = [ESPAPIManager.certificate(filename: "amazonRootCA")]
        let trustManager = ServerTrustManager(evaluators: [
            Configuration.shared.awsConfiguration.baseURL.getDomain(): PinnedCertificatesTrustEvaluator(certificates: certificate), Configuration.shared.awsConfiguration.authURL.getDomain(): PinnedCertificatesTrustEvaluator(certificates: certificate), Configuration.shared.awsConfiguration.claimURL.getDomain(): PinnedCertificatesTrustEvaluator(certificates: certificate),
        ])
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        session = Session(configuration: configuration, serverTrustManager: trustManager)
        session.sessionConfiguration.timeoutIntervalForRequest = 10
        session.sessionConfiguration.timeoutIntervalForResource = 10
    }

    /// Method to get security certificate from bundle resource
    ///
    /// - Parameters:
    ///   - filename: name of the certificate file
    private static func certificate(filename: String) -> SecCertificate {
        let filePath = Bundle.main.path(forResource: filename, ofType: "der")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let certificate = SecCertificateCreateWithData(nil, data as CFData)!

        return certificate
    }
    
    /// Method to update device thing shadow
    /// Any changes of the device params from the app trigger this method
    ///
    /// - Parameters:
    ///   - parameter: list of paramters to be updated
    ///   - completionHandler: handler called when response to setDeviceParam is recieved
    func setMultipleDeviceParam(parameter: [[String: Any]], completionHandler: (([ESPCloudResponse]?, ESPNetworkError?) -> Void)? = nil) {
        self.genericAuthorizedMultiParamDataRequest(url: Constants.setParam, parameter: parameter) { response, error in
            if error == nil {
                guard let data = response else {
                    completionHandler?(nil, .noData)
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode([ESPCloudResponse].self, from: data)
                    completionHandler?(response, nil)
                } catch {
                    completionHandler?(nil, .parsingError(error.localizedDescription))
                }
            } else {
                completionHandler?(nil, error)
            }
        }
    }


    // MARK: - Node APIs

    /// Method to fetch node and devices associated with the user
    ///
    /// - Parameters:
    ///   - completionHandler: after response is parsed this block will be called with node array and error(if any) as argument
    func getNodes(partialList: [Node]? = nil, nextNodeID: String? = nil, completionHandler: @escaping ([Node]?, ESPNetworkError?) -> Void) {
        
        let sessionWorker = ESPExtendUserSessionWorker()
        sessionWorker.checkUserSession() { accessToken, error in
            if let token = accessToken {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                var url = Constants.getNodes + "?node_details=true&num_records=10"
                if nextNodeID != nil {
                    url += "&start_id=" + nextNodeID!
                }
                self.session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if !self.validateJSONResponse(response: response) {
                        completionHandler(nil, .emptyToken)
                        return
                    }
                    switch response.result {
                    case let .success(value):
                        if Configuration.shared.appConfiguration.supportSchedule {
                            ESPScheduler.shared.refreshScheduleList()
                        }
                        if Configuration.shared.appConfiguration.supportScene {
                            ESPSceneManager.shared.refreshSceneList()
                        }
                        ESPNetworkMonitor.shared.setNetworkConnection(connected: true)
                        if let json = value as? [String: Any] {
                            if let nodeArray = json["node_details"] as? [[String: Any]] {
                                var finalNodeList: [Node]?
                                if let nodes = JSONParser.parseNodeArray(data: nodeArray, forSingleNode: false) {
                                    if nextNodeID == nil {
                                        finalNodeList = nodes
                                    } else {
                                        finalNodeList = partialList
                                        for node in nodes {
                                            if node.devices?.count == 1 {
                                                finalNodeList?.insert(node, at: 0)
                                            } else {
                                                finalNodeList?.append(node)
                                            }
                                        }
                                    }
                                }

                                if let nextNodeID = json["next_id"] as? String {
                                    self.getNodes(partialList: finalNodeList, nextNodeID: nextNodeID, completionHandler: completionHandler)
                                } else {
                                    let localStorageHandler = ESPLocalStorageHandler()
                                    localStorageHandler.saveNodeDetails(nodes: finalNodeList)
                                    // Save schedules if it is enabled
                                    if Configuration.shared.appConfiguration.supportSchedule {
                                        localStorageHandler.saveSchedules(schedules: ESPScheduler.shared.schedules)
                                    }
                                    completionHandler(finalNodeList, nil)
                                }
                                return
                            } else if let status = json["status"] as? String, let description = json["description"] as? String {
                                if status == "failure" {
                                    completionHandler(nil, ESPNetworkError.serverError(description))
                                    return
                                }
                            }
                        }
                        completionHandler(nil, nil)
                        return
                    case let .failure(error):
                        let nserror = error as NSError
                        print(nserror.code)
                        if nserror.code == 13 {
                            ESPNetworkMonitor.shared.setNetworkConnection(connected: false)
                        }
                        completionHandler(nil, ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }
                }
            } else {
                if self.validatedRefreshToken(error: error) {
                    completionHandler(nil, .emptyToken)
                }
            }
        }
    }

    /// Get node info like device list, param list and online/offline status
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node info is recieved
    func getNodeInfo(nodeId: String, completionHandler: @escaping (Node?, ESPNetworkError?) -> Void) {
        
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, error in
            if let token = accessToken {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                let url = Constants.getNodes + "?node_id=" + nodeId
                self.session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if !self.validateJSONResponse(response: response) {
                        completionHandler(nil, .emptyToken)
                        return
                    }
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: Any] {
                            if let nodeArray = json["node_details"] as? [[String: Any]] {
                                if let nodes = JSONParser.parseNodeArray(data: nodeArray, forSingleNode: true), nodes.count > 0 {
                                    completionHandler(nodes[0], nil)
                                    return
                                }
                                completionHandler(nil, ESPNetworkError.emptyConfigData)
                                return
                            } else if let status = json["status"] as? String, let description = json["description"] as? String {
                                if status == "failure" {
                                    completionHandler(nil, ESPNetworkError.serverError(description))
                                    return
                                }
                            }
                        }
                        completionHandler(nil, ESPNetworkError.emptyConfigData)
                        return
                    case let .failure(error):
                        completionHandler(nil, ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }
                }
            } else {
                if self.validatedRefreshToken(error: error) {
                    completionHandler(nil, .emptyToken)
                }
            }
        }
    }

    /// Get device parameters current value
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get device paramater is recieved
    func getDeviceParams(device: Device, completionHandler: @escaping (ESPNetworkError?) -> Void) {
        
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, error in
            if let token = accessToken {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                let url = Constants.setParam + "?node_id=" + (device.node?.node_id ?? "")
                self.session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if !self.validateJSONResponse(response: response) {
                        completionHandler(.emptyToken)
                        return
                    }
                    switch response.result {
                    case let .success(value):
                        if let response = value as? [String: Any] {
                            if let deviceName = device.name, let attributes = response[deviceName] as? [String: Any] {
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
                            }
                        }
                        completionHandler(nil)
                        return
                    case let .failure(error):
                        completionHandler(ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }
                }
            } else {
                if self.validatedRefreshToken(error: error) {
                    completionHandler(.emptyToken)
                }
            }
        }
    }

    /// Method to fetch online/offline status of associated nodes
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node status is recieved
    func getNodeStatus(node: Node, completionHandler: @escaping (Node?, Error?) -> Void) {
        
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, error in
            if let token = accessToken {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                let url = Constants.getNodeStatus + "?nodeid=" + (node.node_id ?? "")
                self.session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if !self.validateJSONResponse(response: response) {
                        return
                    }
                    // Parse the connected status of the node
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: Any], let connectivity = json["connectivity"] as? [String: Any] {
                            if let status = connectivity["connected"] as? Bool {
                                let newNode = node
                                newNode.isConnected = status
                                completionHandler(newNode, nil)
                                return
                            }
                        }
                    case let .failure(error):
                        print(error)
                    }
                    completionHandler(node, nil)
                }
            } else {
                if self.validatedRefreshToken(error: error) {
                    completionHandler(node, nil)
                }
            }
        }
    }

    // MARK: - Device Association

    /// Method to send request of adding device to currently active user
    ///
    /// - Parameters:
    ///   - parameter: Request parameter
    ///   - completionHandler: handler called when response to add device to user is recieved with id of the request
    func addDeviceToUser(parameter: [String: String], completionHandler: @escaping (String?, ESPNetworkError?) -> Void) {
        
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, error in
            if let token = accessToken {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                self.session.request(Constants.addDevice, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if !self.validateJSONResponse(response: response) {
                        completionHandler(nil, .emptyToken)
                        return
                    }
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: String] {
                            // Get request id for add device request
                            // This request id will be used for getting the status of add request
                            if let requestId = json[Constants.requestID] {
                                completionHandler(requestId, nil)
                                return
                            } else if let status = json["status"], let description = json["description"] {
                                if status == "failure" {
                                    completionHandler(nil, ESPNetworkError.serverError(description))
                                    return
                                }
                            }
                        }
                    case let .failure(error):
                        // Check for any error on response
                        completionHandler(nil, ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }
                    completionHandler(nil, nil)
                }
            } else {
                if self.validatedRefreshToken(error: error) {
                    completionHandler(nil, .emptyToken)
                }
            }
        }
    }

    /// Method to fetch device assoication staus
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which association status is fetched
    ///   - requestID: Request id to match with the device association request
    ///   - completionHandler: handler called when response to deviceAssociationStatus is recieved
    func deviceAssociationStatus(nodeID: String, requestID: String, completionHandler: @escaping (String) -> Void) {
        
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, error in
            if let token = accessToken {
                let url = Constants.checkStatus + "?node_id=" + nodeID
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                self.session.request(url + "&request_id=" + requestID + "&user_request=true", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if !self.validateJSONResponse(response: response) {
                        completionHandler("error")
                        return
                    }
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: String], let status = json["request_status"] {
                            completionHandler(status)
                            return
                        }
                    case let .failure(error):
                        print(error)
                    }
                    completionHandler("error")
                }
            } else {
                if self.validatedRefreshToken(error: error) {
                    completionHandler("error")
                }
            }
        }
    }

    // MARK: - Thing Shadow

    /// Method to update device thing shadow
    /// Any changes of the device params from the app trigger this method
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which thing shadow is updated
    ///   - completionHandler: handler called when response to setDeviceParam is recieved
    func setDeviceParam(nodeID: String?, parameter: [String: Any], completionHandler: ((ESPCloudResponseStatus) -> Void)? = nil) {
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.paramUpdateNotification)))
        if let nodeid = nodeID {
            ESPExtendUserSessionWorker().checkUserSession() { accessToken, error in
                if let token = accessToken {
                    let url = Constants.setParam + "?nodeid=" + nodeid
                    let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                    self.session.request(url, method: .put, parameters: parameter, encoding: ESPCustomJsonEncoder.default, headers: headers).responseJSON { response in
                        if !self.validateJSONResponse(response: response) {
                            completionHandler?(.failure)
                            return
                        }
                        switch response.result {
                        case let .success(value):
                            if let json = value as? [String: Any] {
                                if let status = json["status"] as? String {
                                    if status == "success" {
                                        completionHandler?(.success)
                                        return
                                    }
                                }
                                completionHandler?(.failure)
                            }
                            return
                        case let .failure(error):
                            print(error)
                            completionHandler?(.failure)
                        }
                    }
                } else {
                    let _ = self.validatedRefreshToken(error: error)
                }
            }
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
        session.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).responseJSON { response in
            switch response.result {
            case let .success(value):
                if let json = value as? [String: Any] {
                    completionHandler(json)
                    return
                }
            case let .failure(error):
                print(error)
            }
            completionHandler(nil)
        }
    }

    /// Method to make generic authorized data request
    ///
    /// - Parameters:
    ///   - url: URL of the api
    ///   - parameter: Parameter to be included in the api call
    ///   - method: HTTP method
    ///   - completionHandler: Callback invoked after api response is recieved
    func genericAuthorizedDataRequest(url: String, parameter: [String: Any]?, method: HTTPMethod = .post, completionHandler: @escaping (Data?, ESPNetworkError?) -> Void) {
        
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, serverError in
            if let token = accessToken {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                self.session.request(url, method: method, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseData { response in
                    if !self.validateDataResponse(response: response) {
                        completionHandler(nil, .emptyToken)
                        return
                    }
                    switch response.result {
                    case let .success(value):
                        completionHandler(value, nil)
                        return
                    case let .failure(error):
                        completionHandler(nil, ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }
                }
            } else {
                if self.validatedRefreshToken(error: serverError) {
                    completionHandler(nil, .emptyToken)
                }
            }
        }
    }

    /// Method to make generic authorized JSON request
    ///
    /// - Parameters:
    ///   - url: URL of the api
    ///   - parameter: Parameter to be included in the api call
    ///   - completionHandler: Callback invoked after api response is recieved
    func genericAuthorizedJSONRequest(url: String, parameter: [String: Any]?, method: HTTPMethod, completionHandler: @escaping (Any?, ESPNetworkError?) -> Void) {
        
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, serverError in
            if let token = accessToken {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                self.session.request(url, method: method, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if !self.validateJSONResponse(response: response) {
                        completionHandler(nil, .emptyToken)
                        return
                    }
                    switch response.result {
                    case let .success(value):
                        completionHandler(value, nil)
                        return
                    case let .failure(error):
                        completionHandler(nil, ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }
                }
            } else {
                if self.validatedRefreshToken(error: serverError) {
                    completionHandler(nil, .emptyToken)
                }
            }
        }
    }
    
    /// Method to make generic authorized data request with array as param
    ///
    /// - Parameters:
    ///   - url: URL of the api
    ///   - parameter: Parameter to be included in the api call
    ///   - method: HTTP method
    ///   - completionHandler: Callback invoked after api response is recieved
    func genericAuthorizedMultiParamDataRequest(url: String, parameter: [[String: Any]]?, method: HTTPMethod = .post, completionHandler: @escaping (Data?, ESPNetworkError?) -> Void) {
        
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, serverError in
            if let token = accessToken {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": token]
                let params = [ESPCustomJsonEncoder.key: parameter as Any]
                self.session.request(url, method: .put, parameters: params, encoding: ESPCustomJsonEncoder.default, headers: headers).responseData { response in
                    if !self.validateDataResponse(response: response) {
                        completionHandler(nil, .emptyToken)
                        return
                    }
                    switch response.result {
                    case let .success(value):
                        completionHandler(value, nil)
                        return
                    case let .failure(error):
                        completionHandler(nil, ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }
                }
            } else {
                if self.validatedRefreshToken(error: serverError) {
                    completionHandler(nil, .emptyToken)
                }
            }
        }
    }
    
    /// Check error code and ireturn true if user session is valid
    /// - Parameter error: Error from server
    /// - Returns: true if session is valid. false otherwise
    private func validatedRefreshToken(error: ESPAPIError?) -> Bool {
        if let serverError = error {
            let parser = ESPAPIParser()
            if !parser.isRefreshTokenValid(serverError: serverError) {
                self.noRefreshSignOutUser(error: serverError)
                return false
            }
        }
        return true
    }
    
    /*
     Clear user data and sign out of the app.
     Navigate to devices screen and present sign in screen.
     */
    private func clearDataAndPresentSignInVC() {
        self.clearUserData()
        DispatchQueue.main.async {
            if !self.isSigninViewControllerPresented() {
                self.presentSigninViewController()
            }
        }
    }
    
}
