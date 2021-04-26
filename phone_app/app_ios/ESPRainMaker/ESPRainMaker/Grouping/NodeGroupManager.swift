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
//  NodeGroupManager.swift
//  ESPRainMaker
//

import Alamofire
import Foundation

// Class to manage group related methods
class NodeGroupManager {
    private let apiManager = ESPAPIManager()
    private let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_group"

    var nodeGroups: [NodeGroup] = []
    static let shared = NodeGroupManager()
    var listUpdated = false

    private init() {}

    /// Method to get node groups for the current user
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func getNodeGroups(completionHandler: @escaping ([NodeGroup]?, ESPNetworkError?) -> Void) {
        apiManager.genericAuthorizedDataRequest(url: nodeGroupURL + "?node_list=true", parameter: nil, method: .get) { result, error in
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
                    let groups = try decoder.decode(Group.self, from: response)
                    // Sorting Groups by their name ascending
                    groups.groups.sort(by: { $0.group_name?.lowercased() ?? "" < $1.group_name?.lowercased() ?? "" })
                    // Adding reference of node object in groups
                    self.updateNodeListInNodeGroup(nodeGroup: groups.groups)
                    self.nodeGroups = groups.groups
                    ESPLocalStorageHandler().saveNodeGroups(self.nodeGroups)
                    completionHandler(groups.groups, nil)
                    return
                }
            } catch {
                completionHandler(nil, .parsingError(error.localizedDescription))
            }
        }
    }

    /// Method to create node groups for the logged-in user
    ///
    /// - Parameters:
    ///   - group: Group for which create request will be made.
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func createNodeGroup(group: NodeGroup, completionHandler: @escaping (NodeGroup?, ESPNetworkError?) -> Void) {
        // Initializing parameter for create group request
        var parameter: [String: Any] = ["group_name": group.group_name!]
        if let nodes = group.nodes {
            parameter["nodes"] = nodes
        }
        apiManager.genericAuthorizedDataRequest(url: nodeGroupURL, parameter: parameter, method: .post) { result, error in
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
                    let createNodeGroup = try decoder.decode(CreateNodeGroupResponse.self, from: response)
                    // Check if group ID is present before marking the response as successfull
                    group.group_id = createNodeGroup.group_id
                    completionHandler(group, nil)
                    return
                }
            } catch {
                completionHandler(nil, .parsingError(error.localizedDescription))
            }
        }
    }

    /// Method to perform group operations like remove, add nodes, rename etc.
    ///
    /// - Parameters:
    ///   - group: Group for which operation will be performed.
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func performNodeGroupOperation(group: NodeGroup, parameter: [String: Any]?, method: HTTPMethod, completionHandler: @escaping (Bool, ESPNetworkError?) -> Void) {
        apiManager.genericAuthorizedDataRequest(url: nodeGroupURL + "?group_id=\(group.group_id!)", parameter: parameter, method: method) { result, error in
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

    /// Method to add reference of node object in groups
    ///
    ///
    private func updateNodeListInNodeGroup(nodeGroup: [NodeGroup]?) {
        if let groups = nodeGroup {
            // Iterate through groups and find associated node by node ID
            for group in groups {
                var nodeList: [Node] = []
                for node in User.shared.associatedNodeList ?? [] {
                    if let groupNodes = group.nodes, groupNodes.contains(node.node_id ?? "") {
                        nodeList.append(node)
                    }
                }
                group.nodeList = nodeList
            }
        }
    }
}
