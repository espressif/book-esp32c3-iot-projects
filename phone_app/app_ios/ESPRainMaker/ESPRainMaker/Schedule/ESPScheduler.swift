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
//  ESPScheduler.swift
//  ESPRainMaker
//
import Foundation
import UIKit

class ESPScheduler: CommonDeviceServicesProtocol {
    static let shared = ESPScheduler()
    var schedules: [String: ESPSchedule] = [:]
    var availableDevices: [String: Device] = [:]
    var currentSchedule: ESPSchedule!
    var currentScheduleKey: String!
    let apiManager = ESPAPIManager()
    
    // MARK constant strings:
    let nodeIdKey = "node_id"
    let payloadKey = "payload"
    let saveScheduleFailureMessage: String = "Unable to save schedule for"
    let editScheduleFailureMessage: String = "Unable to edit schedule for"
    let deleteScheduleFailureMessage: String = "Unable to delete schedule for"
    
    // MARK: - Schedule Operations

    /// Save or edit schedule parameters for a particular Schedule.
    ///
    /// - Parameters:
    ///   - onView:UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is recieved
    func saveSchedule(onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            var jsonString: [String: Any] = [:]
            jsonString["name"] = currentSchedule.name
            jsonString["id"] = currentSchedule.id
            jsonString["operation"] = currentSchedule.operation?.rawValue ?? "add"
            jsonString["triggers"] = [["d": currentSchedule.trigger.days!, "m": currentSchedule.trigger.minutes!]]
            let actions = createActionsFromDeviceList()
            if actions.keys.count > 0 {
                self.invokeServiceAction(apiManager: apiManager, keys: [String](actions.keys), jsonString: jsonString, text: saveScheduleFailureMessage, nodeIdKey: nodeIdKey, payloadKey: payloadKey, actions: actions, availableDevices: availableDevices, serviceType: .schedule, isSave: true, onView: onView) { result in
                    completionHandler(result)
                }
            } else {
                completionHandler(.failure)
            }
        } else {
            completionHandler(.failure)
        }
    }

    /// Enable/disable schedule from the list.
    ///
    /// - Parameters:
    ///   - onView:UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is recieved
    func shouldEnableSchedule(onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            configureDeviceForCurrentSchedule()
            var jsonString: [String: Any] = [:]
            jsonString["id"] = currentSchedule.id
            jsonString["operation"] = currentSchedule.enabled == true ? "enable" : "disable"
            let actions = createActionsFromDeviceList()
            if actions.keys.count > 0 {
                self.invokeServiceAction(apiManager: apiManager, keys: [String](actions.keys), jsonString: jsonString, text: editScheduleFailureMessage, nodeIdKey: nodeIdKey, payloadKey: payloadKey, actions: actions, availableDevices: availableDevices, serviceType: .schedule, isSave: false, onView: onView) { result  in
                    completionHandler(result)
                }
            } else {
                completionHandler(.failure)
            }
        } else {
            completionHandler(.failure)
        }
    }
    
    
    /// Delete nodes for a schedule
    /// - Parameters:
    ///   - key: schedule ID
    ///   - onView: UIView to show message in case of failure.
    ///   - nodeIDs: List of node IDs to be deleted
    ///   - completionHandler: Callback invoked after api response is recieved
    func deleteScheduleNodes(key: String, onView: UIView, nodeIDs: [String], completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            if let schedule = ESPScheduler.shared.schedules[key] {
                var jsonString: [String: Any] = [:]
                jsonString["name"] = schedule.name
                jsonString["id"] = schedule.id
                jsonString["operation"] = "remove"
                self.invokeServiceAction(apiManager: apiManager, keys: nodeIDs, jsonString: jsonString, text: deleteScheduleFailureMessage, nodeIdKey: nodeIdKey, payloadKey: payloadKey, actions: schedule.actions, availableDevices: availableDevices, serviceType: .schedule, isSave: false, onView: onView) { result  in
                    completionHandler(result)
                }
            } else {
                completionHandler(.failure)
            }
        } else {
            completionHandler(.failure)
        }
    }

    /// Delete schedule from the list.
    ///
    /// - Parameters:
    ///   - onView:UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is recieved
    func deleteScheduleAt(key: String, onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            currentSchedule = ESPScheduler.shared.schedules[key]!
            configureDeviceForCurrentSchedule()
            var jsonString: [String: Any] = [:]
            jsonString["name"] = currentSchedule.name
            jsonString["id"] = currentSchedule.id
            jsonString["operation"] = "remove"
            self.invokeServiceAction(apiManager: apiManager, keys: [String](currentSchedule.actions.keys), jsonString: jsonString, text: deleteScheduleFailureMessage, nodeIdKey: nodeIdKey, payloadKey: payloadKey, actions: self.currentSchedule.actions, availableDevices: availableDevices, serviceType: .schedule, isSave: false, onView: onView) { result  in
                completionHandler(result)
            }
        } else {
            completionHandler(.failure)
        }
    }

    // MARK: - Conifguration Methods

    /// Add a new schedule.
    func addSchedule() {
        currentSchedule = ESPSchedule()
    }

    /// Remove each element from the schedule list and refetch.
    func refreshScheduleList() {
        ESPScheduler.shared.schedules.removeAll()
        availableDevices.removeAll()
        currentSchedule = nil
    }

    /// In list of available devices select param and update param values as given in the current schedule.
    func configureDeviceForCurrentSchedule() {
        resetAvailableDeviceStatus(availableDevices: &availableDevices)
        if let schedule = ESPScheduler.shared.currentSchedule, schedule.actions.count > 0 {
            for key in schedule.actions.keys {
                for device in schedule.actions[key]! {
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

    /// Creates list of Schedules from the schedule JSON of a particular node.
    ///
    /// - Parameters:
    ///   - nodeID:Node ID for which JSON is fetched.
    ///   - scheduleJSON: JSON containing schedule parameters for a particular node
    func saveScheduleListFromJSON(nodeID: String, scheduleJSON: [String: Any]) {
        let id = scheduleJSON["id"] as? String ?? ""

        let trigger = ESPTrigger()
        if let triggerJSON = scheduleJSON["triggers"] as? [[String: Any]] {
            let triggerDict = triggerJSON[0]
            trigger.days = triggerDict["d"] as? Int ?? 0
            trigger.minutes = triggerDict["m"] as? Int ?? 0
        }

        let enabled = scheduleJSON["enabled"] as? Int ?? 0 == 1 ? true : false
        let name = scheduleJSON["name"] as? String ?? ""

        var devices: [Device] = []
        let node = Node()
        node.node_id = nodeID

        let actionDict = scheduleJSON["action"] as? [String: Any] ?? [:]
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

        // Same schedule id can have different value.
        // To properly define a single schedule we need to create a unique id based on the combination of each parameters.
        let key = "\(id).\(name).\(trigger.days!).\(trigger.minutes!).\(enabled)"

        // Check for existing schedule in the list for a given key
        if let existingSchedule = ESPScheduler.shared.schedules[key] {
            existingSchedule.actions[nodeID] = devices
        } else {
            // Create a new schedule object if no key is found on the list
            let newSchedule = ESPSchedule()
            newSchedule.id = id
            newSchedule.enabled = enabled
            newSchedule.name = name
            newSchedule.trigger = trigger
            newSchedule.week = ESPWeek(number: trigger.days ?? 0)
            newSchedule.actions[nodeID] = devices
            ESPScheduler.shared.schedules[key] = newSchedule
        }
    }

    /// Filters devices based on the capability of whether they support scheduling.
    ///
    /// - Parameters:
    ///   - nodeList: List of nodes. Each node contains devices and information of their services.
    func getAvailableDeviceWithScheduleCapability(nodeList: [Node]) {
        for node in nodeList {
            if node.isSchedulingSupported {
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
                            ESPScheduler.shared.availableDevices[key] = copyDevice
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Call this method when there is an update in the device name.
    /// This method is needed to show updated names on the action list.
    func updateDeviceName(for nodeID: String?, name: String?, deviceName: String) {
        let key = [nodeID, name].compactMap { $0 }.joined(separator: ".")
        if let deviceExist = availableDevices[key] {
            deviceExist.deviceName = deviceName
        }
    }
    
    /// Gives list of devices under a schedule
    ///
    /// - Returns: Comma seperated string of devices that are part of a schedule
    func getActionList() -> String {
        return self.getActionList(availableDevices: availableDevices)
    }

    // MARK: - Private Methods

    /// Method returns dictionary with:
    ///  key: node ID
    ///  value: devices for which some  action has been selected for schedule
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
