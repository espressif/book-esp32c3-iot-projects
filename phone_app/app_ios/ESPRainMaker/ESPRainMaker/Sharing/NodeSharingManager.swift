// Copyright 2021 Espressif Systems
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
//  NodeSharingManager.swift
//  ESPRainMaker
//

import Foundation

// Class managing node sharing operations.
class NodeSharingManager {
    private let apiManager = ESPAPIManager()
    private let nodeSharingURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/sharing"

    var sharingRequestsSent: [SharingRequest] = []
    var sharingRequestsReceived: [SharingRequest] = []

    static let shared = NodeSharingManager()

    private init() {}

    /// Method to get sharing details of the logged in user.
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func getSharingDetails(node: Node, completionHandler: @escaping (ESPNetworkError?) -> Void) {
        let url = Constants.sharing + "?node_id=" + (node.node_id ?? "")
        apiManager.genericAuthorizedJSONRequest(url: url, parameter: nil, method: .get) { response, error in
            guard let json = response as? [String: Any], let node_sharing = json["node_sharing"] as? [[String: Any]] else {
                if let failureJSON = response as? [String: String], let status = failureJSON["status"], let description = failureJSON["description"] {
                    if status == "failure" {
                        completionHandler(ESPNetworkError.serverError(description))
                        return
                    }
                } else if let apiError = error {
                    completionHandler(ESPNetworkError.serverError(apiError.description))
                    return
                }
                completionHandler(.unknownError)
                return
            }

            let node_info = node_sharing[0]
            if let users = node_info["users"] as? [String: [String]] {
                node.primary = users["primary"]
                node.secondary = users["secondary"]
            }
            completionHandler(nil)
            return
        }
    }

    /// Method to remove sharing of node between users..
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func deleteSharing(forNode: Node, email: String, completionHandler: @escaping (Bool, ESPNetworkError?) -> Void) {
        let url = Constants.sharing + "?nodes=\(forNode.node_id ?? "")&user_name=\(email)"
        apiManager.genericAuthorizedDataRequest(url: url, parameter: nil, method: .delete) { result, error in
            guard let response = result else {
                completionHandler(false, error!)
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ESPCloudResponse.self, from: response)
                // Check for success in response
                if response.status.lowercased() == "success" {
                    completionHandler(true, nil)
                    return
                } else {
                    completionHandler(false, .serverError(response.description))
                }
            } catch {
                completionHandler(false, .parsingError(error.localizedDescription))
            }
        }
    }

    /// Method to create a new sharing request.
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func createSharingRequest(userName: String, node: Node, completionHandler: @escaping (SharingRequest?, ESPNetworkError?) -> Void) {
        var devicesList: [[String: String]] = [[:]]
        if let devices = node.devices {
            for device in devices {
                devicesList.append(["name": device.deviceName])
            }
        }
        let parameter: [String: Any] = ["nodes": [node.node_id ?? ""], "user_name": userName, "metadata": ["devices": devicesList]]
        apiManager.genericAuthorizedDataRequest(url: nodeSharingURL, parameter: parameter, method: .put) { result, error in
            guard let response = result else {
                completionHandler(nil, error!)
                return
            }
            do {
                let decoder = JSONDecoder()
                // Check for failure in response
                if let successResponse = try? decoder.decode(CreateSharingResponse.self, from: response) {
                    let request = SharingRequest(requestID: successResponse.request_id)
                    request.user_name = userName
                    request.request_timestamp = Date().timeIntervalSince1970
                    completionHandler(request, nil)
                    return
                } else {
                    // Initializing Group objects from response data
                    let failureResponse = try decoder.decode(ESPCloudResponse.self, from: response)
                    completionHandler(nil, .serverError(failureResponse.description))
                    return
                }
            } catch {
                completionHandler(nil, .parsingError(error.localizedDescription))
            }
        }
    }

    /// Method to get all sharing request for the logged in user.
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func getSharingRequests(primaryUser: Bool, nextRequestID: String? = nil, completionHandler: @escaping ([SharingRequest]?, ESPNetworkError?) -> Void) {
        var sharingRequestURL = nodeSharingURL + "/requests?primary_user="
        if primaryUser {
            sharingRequestURL = sharingRequestURL + "true"
        } else {
            sharingRequestURL = sharingRequestURL + "false"
        }

        if let startRequestID = nextRequestID {
            sharingRequestURL += "&start_request_id=" + startRequestID + "&start_user_name=" + User.shared.userInfo.username
        }

        apiManager.genericAuthorizedDataRequest(url: sharingRequestURL, parameter: nil, method: .get) { result, error in
            guard let response = result else {
                completionHandler(nil, error!)
                return
            }
            do {
                let decoder = JSONDecoder()
                // Check for failure in response
                if let failureResponse = try? decoder.decode(ESPCloudResponse.self, from: response) {
                    completionHandler(nil, .serverError(failureResponse.description))
                    return
                } else {
                    // Initializing Group objects from response data
                    let sharingRequests = try decoder.decode(SharingRequests.self, from: response)
                    // Sorting Groups by their name ascending
                    if sharingRequests.sharing_requests != nil {
                        if primaryUser {
                            if nextRequestID == nil {
                                self.sharingRequestsSent = sharingRequests.sharing_requests!
                            } else {
                                self.sharingRequestsSent.append(contentsOf: sharingRequests.sharing_requests!)
                            }
                        } else {
                            if nextRequestID == nil {
                                self.sharingRequestsReceived = sharingRequests.sharing_requests!
                            } else {
                                self.sharingRequestsReceived.append(contentsOf: sharingRequests.sharing_requests!)
                            }
                        }
                    }
                    if sharingRequests.next_request_id == nil {
                        if primaryUser {
                            self.sharingRequestsSent.sort(by: { $0.request_timestamp ?? 0 > $1.request_timestamp ?? 0 })
                            completionHandler(self.sharingRequestsSent, nil)
                        } else {
                            self.sharingRequestsReceived.sort(by: { $0.request_timestamp ?? 0 > $1.request_timestamp ?? 0 })
                            completionHandler(self.sharingRequestsReceived, nil)
                        }
                    } else {
                        self.getSharingRequests(primaryUser: primaryUser, nextRequestID: sharingRequests.next_request_id, completionHandler: completionHandler)
                    }
                    return
                }
            } catch {
                completionHandler(nil, .parsingError(error.localizedDescription))
            }
        }
    }

    /// Method to delete sharing request which are pending to be accepted.
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func deleteSharingRequest(request: SharingRequest, completionHandler: @escaping (Bool, ESPNetworkError?) -> Void) {
        apiManager.genericAuthorizedDataRequest(url: nodeSharingURL + "/requests?request_id=\(request.request_id)", parameter: nil, method: .delete) { result, error in
            guard let response = result else {
                completionHandler(false, error!)
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ESPCloudResponse.self, from: response)
                // Check for success in response
                if response.status.lowercased() == "success" {
                    completionHandler(true, nil)
                    return
                } else {
                    completionHandler(false, .serverError(response.description))
                }
            } catch {
                completionHandler(false, .parsingError(error.localizedDescription))
            }
        }
    }

    /// Method to update sharing requests for a user.
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func updateSharing(parameter: [String: Any], completionHandler: @escaping (Bool, ESPNetworkError?) -> Void) {
        apiManager.genericAuthorizedDataRequest(url: nodeSharingURL + "/requests", parameter: parameter, method: .put) { result, error in
            guard let response = result else {
                completionHandler(false, error!)
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ESPCloudResponse.self, from: response)
                // Check for success in response
                if response.status.lowercased() == "success" {
                    completionHandler(true, nil)
                    return
                } else {
                    completionHandler(false, .serverError(response.description))
                }
            } catch {
                completionHandler(false, .parsingError(error.localizedDescription))
            }
        }
    }
}
