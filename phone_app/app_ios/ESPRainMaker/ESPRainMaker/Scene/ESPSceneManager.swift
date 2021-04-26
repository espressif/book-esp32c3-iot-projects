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
//  ESPSceneManager.swift
//  ESPRainMaker
//

import Foundation
import UIKit

class ESPSceneManager: CommonDeviceServicesProtocol {
    
    static let shared = ESPSceneManager()
    var scenes: [String: ESPScene] = [:]
    var availableDevices: [String: Device] = [:]
    var currentScene: ESPScene!
    var currentSceneKey: String!
    let apiManager = ESPAPIManager()
    
    // MARK: Utility methods
    
    /// Remove each element from the scene list and refetch.
    func refreshSceneList() {
        scenes.removeAll()
        availableDevices.removeAll()
        currentScene = nil
    }

    /// Creates list of scenes from the scene JSON of a particular node.
    ///
    /// - Parameters:
    ///   - nodeID:Node ID for which JSON is fetched.
    ///   - sceneJSON: JSON containing scene parameters for a particular node
    func saveScenesFromJSON(nodeID: String, sceneJSON: [String: Any]) {
        if nodeID.count == 0 {
            return
        }
        let id = sceneJSON["id"] as? String ?? ""
        let name = sceneJSON["name"] as? String ?? ""
        let info = sceneJSON["info"] as? String ?? ""
        var devices: [Device] = []
        let node = Node()
        node.node_id = nodeID

        let actionDict = sceneJSON["action"] as? [String: Any] ?? [:]
        for key in actionDict.keys {
            let newDevice = Device()
            newDevice.name = key
            newDevice.node = node
            newDevice.params = []
            if let paramJSON = actionDict[key] as? [String: Any] {
                for paramKey in paramJSON.keys {
                    let newParam = Param()
                    newParam.name = paramKey
                    newParam.value = paramJSON[paramKey]
                    newDevice.params?.append(newParam)
                }
            }
            devices.append(newDevice)
        }

        // Check for existing scene in the list for a given key
        
        let key = "\(id).\(name).\(info)"
        
        if let existingScene = scenes[key] {
            existingScene.actions[nodeID] = devices
        } else {
            let newScene = ESPScene()
            newScene.id = id
            newScene.name = name
            newScene.actions[nodeID] = devices
            newScene.info = info
            scenes[key] = newScene
        }
    }
    
    /// Filters devices based on the capability of whether they support scenes.
    ///
    /// - Parameters:
    ///   - nodeList: List of nodes. Each node contains devices and information of their services
    func getAvailableDeviceWithSceneCapability(nodeList: [Node]) {
        for node in nodeList {
            if node.isSceneSupported {
                if let devices = node.devices {
                    for device in devices {
                        let copyDevice = Device(device: device)
                        copyDevice.params = []
                        if let params = device.params {
                            for param in params {
                                if param.canUseDeviceServices {
                                    copyDevice.params?.append(Param(param: param))
                                }
                            }
                        }
                        if copyDevice.params!.count > 0 {
                            let key = [copyDevice.node?.node_id, copyDevice.name].compactMap { $0 }.joined(separator: ".")
                            ESPSceneManager.shared.availableDevices[key] = copyDevice
                        }
                    }
                }
            }
        }
    }
    
    /// In list of available devices select param and update param values as given in the current scene.
    func configureDeviceForCurrentScene() {
        resetAvailableDeviceStatus(availableDevices: &availableDevices)
        if let scene = currentScene, scene.actions.count > 0 {
            for key in scene.actions.keys {
                for device in scene.actions[key]! {
                    let id = [key, device.name].compactMap { $0 }.joined(separator: ".")
                    if let availableDevice = availableDevices[id], let params = device.params {
                        for param in params {
                            if let availableDeviceParam = availableDevice.params?.first(where: { $0.name == param.name }) {
                                availableDeviceParam.value = param.value
                                availableDeviceParam.selected = true
                                availableDevice.selectedParams += 1
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Gives list of devices under a scene.
    ///
    /// - Returns: Comma seperated string of devices that are part of a scene
    func getActionList() -> String {
        return self.getActionList(availableDevices: availableDevices)
    }
    
    // MARK: - Scene Operations

    /// Save or edit scene parameters for a particular scene.
    ///
    /// - Parameters:
    ///   - onView:UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is recieved
    func saveScene(onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            var jsonString: [String: Any] = [:]
            jsonString["name"] = currentScene.name
            jsonString["id"] = currentScene.id
            jsonString["info"] = currentScene.info ?? ""
            jsonString["operation"] = currentScene.operation?.rawValue ?? "add"
            let actions = createActionsFromDeviceList()
            if actions.keys.count > 0 {
                self.invokeServiceAction(apiManager: apiManager, keys: [String](actions.keys), jsonString: jsonString, text: ESPSceneConstants.saveSceneFailureMessage, nodeIdKey: ESPSceneConstants.nodeIdKey, payloadKey: ESPSceneConstants.payloadKey, actions: actions, availableDevices: availableDevices, serviceType: .scene, isSave: true, onView: onView) { result in
                    completionHandler(result)
                }
            } else {
                completionHandler(.failure)
            }
        } else {
            completionHandler(.failure)
        }
    }
    
    /// Remove devices for given node IDs that are part of a given scene.
    ///
    /// - Parameters:
    ///   - key: scene ID
    ///   - onView: UIView to show message in case of failure.
    ///   - nodeIDs: List of node IDs to be deleted
    ///   - completionHandler: Callback invoked after api response is recieved
    func deleteSceneNodes(key: String, onView: UIView, nodeIDs: [String], completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            if let scene = scenes[key] {
                var jsonString: [String: Any] = [:]
                jsonString["name"] = scene.name
                jsonString["id"] = scene.id
                jsonString["operation"] = "remove"
                self.invokeServiceAction(apiManager: apiManager, keys: nodeIDs, jsonString: jsonString, text: ESPSceneConstants.partialDeleteSceneFailureMessage, nodeIdKey: ESPSceneConstants.nodeIdKey, payloadKey: ESPSceneConstants.payloadKey, actions: self.currentScene.actions, availableDevices: availableDevices, serviceType: .scene, isSave: false, onView: onView) { result  in
                    completionHandler(result)
                }
            } else {
                completionHandler(.failure)
            }
        } else {
            completionHandler(.failure)
        }
    }
    
    /// Delete scene for given scene ID.
    ///
    /// - Parameters:
    ///   - key: scene ID
    ///   - onView: UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is recieved
    func deleteSceneAt(key: String, onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            currentScene = scenes[key]!
            configureDeviceForCurrentScene()
            var jsonString: [String: Any] = [:]
            jsonString["id"] = currentScene.id
            jsonString["operation"] = "remove"
            self.invokeServiceAction(apiManager: apiManager, keys: [String](currentScene.actions.keys), jsonString: jsonString, text: ESPSceneConstants.partialDeleteSceneFailureMessage, nodeIdKey: ESPSceneConstants.nodeIdKey, payloadKey: ESPSceneConstants.payloadKey, actions: self.currentScene.actions, availableDevices: availableDevices, serviceType: .scene, isSave: false, onView: onView) { result  in
                completionHandler(result)
            }
        } else {
            completionHandler(.failure)
        }
    }
    
    /// Apply scene on corresponding devices.
    ///
    /// - Parameters:
    ///   - scene: scene to be applied
    ///   - onView: UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is recieved
    func activateScene(scene: ESPScene, onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            var jsonString: [String: Any] = [:]
            jsonString["id"] = scene.id
            jsonString["operation"] = "activate"
            self.invokeServiceAction(apiManager: apiManager, keys: [String](scene.actions.keys), jsonString: jsonString, text: ESPSceneConstants.partialActivateSceneFailureMessage, nodeIdKey: ESPSceneConstants.nodeIdKey, payloadKey: ESPSceneConstants.payloadKey, actions: scene.actions, availableDevices: availableDevices, serviceType: .scene, isSave: false, onView: onView) { result  in
                completionHandler(result)
            }
        } else {
            completionHandler(.failure)
        }
    }
    
    // MARK: - Private Methods
    
    /// Method returns dictionary with:
    ///  key: node ID
    ///  value: devices for which some  action has been selected for scene
    ///
    /// - Returns: dictionary with above key and values
    private func createActionsFromDeviceList() -> [String: [Device]] {
        var actions: [String: [Device]] = [:]
        for device in availableDevices.values {
            if device.selectedParams > 0 {
                if actions.keys.contains(device.node?.node_id ?? "") {
                    actions[device.node?.node_id ?? ""]!.append(device)
                } else {
                    actions[device.node?.node_id ?? ""] = [device]
                }
            }
        }
        return actions
    }
}

