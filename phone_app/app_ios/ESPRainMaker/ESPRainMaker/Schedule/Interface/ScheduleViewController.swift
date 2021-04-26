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
//  ScheduleViewController.swift
//  ESPRainMaker
//

import UIKit

class ScheduleViewController: UIViewController {
    @IBOutlet var repeatViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet var actionTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var onDaysImageView: UIImageView!
    @IBOutlet var scheduleNameLabel: UILabel!
    @IBOutlet var dailyImageView: UIImageView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var repeatView: UIView!
    @IBOutlet var repeatImage: UIImageView!
    @IBOutlet var daysLabel: UILabel!
    @IBOutlet var actionListTextView: UITextView!
    @IBOutlet var timerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var timeView: UIView!
    @IBOutlet var removeButton: RemoveScheduleButton!
    @IBOutlet weak var nameViewHeight: NSLayoutConstraint!
    
    var isNewSchedule = false

    var isCollapsed = true
    var scheduleKey = ""
    
    var deSelectedNodeIDs: [String] = [String]()
    var selectedNodeIDs: [String] = [String]()
    
    var failedSchedule: ESPSchedule?
    
    weak var delegate: ServiceUpdateActionsDelegate?

    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update list of available devices for schedule
        if let nodeList = User.shared.associatedNodeList {
            ESPScheduler.shared.getAvailableDeviceWithScheduleCapability(nodeList: nodeList)
        }
        
        // Configure view for current schedule
        ESPScheduler.shared.configureDeviceForCurrentSchedule()
        
        failedSchedule = getFailedSchedule(schedule: ESPScheduler.shared.currentSchedule)
        
        //Get devices already selected for scheduling
        selectedNodeIDs = getSelectedNodeIDs()

        // Configure time of date picker based on the value of schedule minute field.
        datePicker.backgroundColor = UIColor.white
        if ESPScheduler.shared.currentSchedule.id != nil {
            scheduleNameLabel.text = ESPScheduler.shared.currentSchedule.name
            setNameViewHeight(label: scheduleNameLabel)
            let lastSelectedDateStr = ESPScheduler.shared.currentSchedule.trigger.getTimeDetails()
            datePicker.setDate(from: lastSelectedDateStr, format: "h:mm a", animated: true)
            removeButton.isHidden = false
            removeButton.setTitle("Remove", for: .normal)
            removeButton.setImage(UIImage(named: "trash"), for: .normal)
        } else {
            isNewSchedule = true
        }

        actionListTextView.textContainer.heightTracksTextView = true
        actionListTextView.isScrollEnabled = false
        actionListTextView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        } else {
            // Fallback on earlier versions
            timeLabel.isHidden = true
            timerViewHeightConstraint.constant = 200.0
            datePicker.leadingAnchor.constraint(equalTo: timeView.leadingAnchor, constant: 0).isActive = true
            datePicker.trailingAnchor.constraint(equalTo: timeView.trailingAnchor, constant: 0).isActive = true
            datePicker.topAnchor.constraint(equalTo: timeView.topAnchor, constant: 0).isActive = true
            datePicker.bottomAnchor.constraint(equalTo: timeView.bottomAnchor, constant: 0).isActive = true
        }
        removeButton.layer.borderColor = UIColor(hexString: "#f45c10").cgColor
        removeButton.backgroundColor = UIColor(hexString: "#FFECE4")
        setRepeatStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        // Show list of actions added on a schedule.
        getDeSelectedNodeIDs()
        let actionList = ESPScheduler.shared.getActionList()
        if actionList == "" {
            if deSelectedNodeIDs.count > 0 {
                saveButton.isHidden = false
            } else {
                saveButton.isHidden = true
            }
            actionListTextView.text = ""
            actionTextViewHeightConstraint.priority = .defaultHigh
        } else {
            actionListTextView.text = actionList
            actionTextViewHeightConstraint.priority = .defaultLow
            saveButton.isHidden = false
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "selectDaysVC" {
            if let vc = segue.destination as? SelectDaysViewController {
                vc.pvc = self
            }
        }
    }

    // MARK: - IBActions

    @IBAction func removeScheduleAction(_: Any) {
        let alertController = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
            DispatchQueue.main.async {
                Utility.showLoader(message: "", view: self.view)
                ESPScheduler.shared.deleteScheduleAt(key: self.scheduleKey, onView: self.view) { result  in
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                        switch result {
                        case .success(let nodesFailed):
                            User.shared.updateDeviceList = true
                            if !nodesFailed {
                                self.delegate?.serviceRemoved()
                            }
                            self.navigationController?.popViewController(animated: true)
                        default:
                            break
                        }
                    }
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func scheduleNamePressed(_: Any) {
        let input = UIAlertController(title: "Add name", message: "Choose name for your schedule", preferredStyle: .alert)

        input.addTextField { textField in
            textField.text = self.scheduleNameLabel.text ?? ""
            textField.delegate = self
            self.addHeightConstraint(textField: textField)
        }
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in

        }))
        input.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak input] _ in
            let textField = input?.textFields![0]
            textField?.keyboardType = .asciiCapable
            guard let name = textField?.text else {
                return
            }
            self.scheduleNameLabel.text = name
            self.setNameViewHeight(label: self.scheduleNameLabel)
        }))
        present(input, animated: true, completion: nil)
    }
    
    @IBAction func repeatButtonPressed(_: Any) {
        if isCollapsed {
            isCollapsed = false
            repeatImage.image = UIImage(named: "down_arrow")
            UIView.animate(withDuration: 1.0) {
                self.repeatView.isHidden = false
                self.repeatViewHeightConstraint.constant = 80.0
            }
        } else {
            isCollapsed = true
            repeatImage.image = UIImage(named: "right_arrow")
            UIView.animate(withDuration: 1.0) {
                self.repeatView.isHidden = true
                self.repeatViewHeightConstraint.constant = 0
            }
        }
    }

    @IBAction func backButtonPressed(_: Any) {
        ESPScheduler.shared.configureDeviceForCurrentSchedule()
        navigationController?.popViewController(animated: true)
    }

    @IBAction func onDaysButtonPressed(_: Any) {}

    @IBAction func dailyButtonTapped(_: Any) {
        onDaysImageView.isHidden = true
        dailyImageView.isHidden = false
        daysLabel.text = "Never"
        ESPScheduler.shared.currentSchedule.trigger.days = 0
        ESPScheduler.shared.currentSchedule.week = ESPWeek(number: 0)
    }

    @IBAction func saveSchedule(_: Any) {
        // Check if the user has provided name for the schedule
        let scheduleName = scheduleNameLabel.text ?? ""
        if scheduleName == "" {
            let alert = UIAlertController(title: "Error", message: "Please enter name of the schedule to proceed.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            //If de-selected node count is greater than 0 then call delete on those node ids. Else call edit schedule.
            if deSelectedNodeIDs.count > 0 {
                self.deleteNodesForSchedule() { schedulesDeleted in
                    self.editSchedule(scheduleName: scheduleName, schedulesDeleted: schedulesDeleted)
                }
            } else {
                self.editSchedule(scheduleName: scheduleName, schedulesDeleted: false)
            }
        }
    }
    
    /// Calls delete action on deselected nodes and returns true if user has edited schedule without removing all actions
    /// - Parameter callEditAction: called with flag informing if schedule actions have been deleted
    private func deleteNodesForSchedule(_ callEditAction: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { Utility.showLoader(message: "", view: self.view) }
        ESPScheduler.shared.deleteScheduleNodes(key: ESPScheduler.shared.currentScheduleKey, onView: view, nodeIDs: deSelectedNodeIDs) { result  in
            //If user has deselected all devices, then set update device list to true and pop to schedule list screen. Else call edit schedule.
            var schedulesDeleted: Bool = false
            switch result {
            case .success(_):
                schedulesDeleted = true
            default:
                schedulesDeleted = false
            }
            let actionList = ESPScheduler.shared.getActionList()
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0, execute: {
                if actionList == "" {
                    Utility.hideLoader(view: self.view)
                    if schedulesDeleted {
                        User.shared.updateDeviceList = true
                        self.delegate?.serviceRemoved()
                        self.navigationController?.popToRootViewController(animated: false)
                    }
                } else {
                    callEditAction(schedulesDeleted)
                }
            })
        }
    }
    
    /// Called when user has edited user actions in a schedule. Or created a new schedule.
    /// - Parameter scheduleName: schedule name
    private func editSchedule(scheduleName: String, schedulesDeleted: Bool) {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        // If no id is present that means new schedule is added.
        if ESPScheduler.shared.currentSchedule != nil, ESPScheduler.shared.currentSchedule.id == nil {
            // Generate a unique 4 length id for the new schedule.
            ESPScheduler.shared.currentSchedule.id = NanoID.new(4)
            ESPScheduler.shared.currentSchedule.operation = .add
        } else {
            // Schedule already present so will run edit operation on it.
            ESPScheduler.shared.currentSchedule.operation = .edit
        }

        // Give value for the schedule parameters based on the user selection.
        ESPScheduler.shared.currentSchedule.name = scheduleName
        ESPScheduler.shared.currentSchedule.trigger = self.getTrigger()
        
        // Call save operation.
        ESPScheduler.shared.saveSchedule(onView: view) { result  in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                Utility.hideLoader(view: self.view)
                switch result {
                case .success(let nodesFailed):
                    // Result is success. Navigate back to schedule list and refetch the list.
                    // To check if schedule is successfully added.
                    User.shared.updateDeviceList = true
                    self.formatCurrentScheduleKey()
                    if !ESPScheduler.shared.currentSchedule.enabled {
                        Utility.showLoader(message: "", view: self.view)
                        ESPScheduler.shared.currentSchedule.enabled = true
                        ESPScheduler.shared.currentSchedule.operation = .edit
                        ESPScheduler.shared.shouldEnableSchedule(onView: self.view, completionHandler: { result in
                            DispatchQueue.main.asyncAfter(deadline: .now()+1.0, execute: {
                                Utility.hideLoader(view: self.view)
                                switch result {
                                case .success(let nodesFailed):
                                    if !nodesFailed {
                                        if self.isNewSchedule {
                                            self.delegate?.serviceAdded()
                                        } else {
                                            self.delegate?.serviceUpdated()
                                        }
                                        self.navigationController?.popToRootViewController(animated: false)
                                        return
                                    }
                                    break
                                case .failure:
                                    Utility.showToastMessage(view: self.view, message: "Failed to schedule devices. Please check your connection!!")
                                }
                                self.navigationController?.popToRootViewController(animated: false)
                            })
                        })
                    } else {
                        if !nodesFailed {
                            if self.isNewSchedule {
                                self.delegate?.serviceAdded()
                            } else {
                                self.delegate?.serviceUpdated()
                            }
                        }
                        self.navigationController?.popToRootViewController(animated: false)
                    }
                case .failure:
                    if let failed = self.failedSchedule {
                        if let key = ESPScheduler.shared.currentScheduleKey, let _ = ESPScheduler.shared.schedules[key] {
                            ESPScheduler.shared.schedules[ESPScheduler.shared.currentScheduleKey] = failed
                            ESPScheduler.shared.schedules[ESPScheduler.shared.currentScheduleKey]?.actions = ESPScheduler.shared.currentSchedule.actions
                        }
                    }
                    Utility.showToastMessage(view: self.view, message: ESPScheduleConstants.scheduleUpdateFailed)
                    if schedulesDeleted {
                        User.shared.updateDeviceList = true
                        self.navigationController?.popToRootViewController(animated: false)
                    }
                }
            }
        }
    }
    
    private func getFailedSchedule(schedule: ESPSchedule) -> ESPSchedule {
        let failed = ESPSchedule()
        failed.id = schedule.id
        failed.name = schedule.name
        failed.actions = schedule.actions
        failed.trigger = schedule.trigger
        failed.operation = schedule.operation
        failed.week = schedule.week
        failed.enabled = schedule.enabled
        return failed
    }
    
    private func formatCurrentScheduleKey() {
        let trigger = ESPScheduler.shared.currentSchedule.trigger
        ESPScheduler.shared.currentScheduleKey = "\(ESPScheduler.shared.currentSchedule.id!).\(ESPScheduler.shared.currentSchedule.name!).\(trigger.days!).\(trigger.minutes!).\(ESPScheduler.shared.currentSchedule.enabled)"
    }
    
    /// Get trigger object for schedule
    /// - Returns: trigger value for current schedule
    private func getTrigger() -> ESPTrigger {
        let trigger = ESPTrigger()
        trigger.days = ESPScheduler.shared.currentSchedule.week.getDecimalConversionOfSelectedDays()
        let date = datePicker.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour!
        let minute = components.minute!
        trigger.minutes = hour * 60 + minute
        return trigger
    }

    @IBAction func selectDevicesPressed(_: Any) {
        let selectDeviceVC = storyboard?.instantiateViewController(withIdentifier: "selecDevicesVC") as! SelectDevicesViewController
        var availableDeviceCopy: [Device] = []
        // Re-order list of devices such that devices whose params are selected be on top.
        for device in ESPScheduler.shared.availableDevices.values {
            if device.selectedParams > 0 {
                availableDeviceCopy.insert(device, at: 0)
            } else {
                availableDeviceCopy.append(device)
            }
        }
        availableDeviceCopy = configureDeviceScheduleActions(availableDeviceCopy)
        selectDeviceVC.availableDeviceCopy = sortDevices(availableDevices: availableDeviceCopy)
        navigationController?.pushViewController(selectDeviceVC, animated: true)
    }
    
    /// Get list of node IDs for which some action has been selected
    /// - Returns: list of selected node IDs
    private func getSelectedNodeIDs() -> [String] {
        var nodeIDs: [String] = [String]()
        for device in ESPScheduler.shared.availableDevices.values {
            if let node = device.node, let nodeID = node.node_id {
                if device.selectedParams > 0, !nodeIDs.contains(nodeID) {
                    nodeIDs.append(nodeID)
                }
            }
        }
        return nodeIDs
    }
    
    /// Get list of node IDs for which actions have been removed from the original selected nodes.
    /// - Returns: list of deselected node IDs
    private func getDeSelectedNodeIDs() {
        let nodeIDs = getSelectedNodeIDs()
        deSelectedNodeIDs = [String]()
        for nodeID in selectedNodeIDs {
            if !nodeIDs.contains(nodeID) {
                deSelectedNodeIDs.append(nodeID)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Set height for the schedule name label
    /// - Parameter label: schedule name label
    private func setNameViewHeight(label: UILabel) {
        let height = self.scheduleNameLabel.getNameViewHeight(height: self.nameViewHeight.constant, width: self.view.frame.width - 127.0)
        self.nameViewHeight.constant = height
    }
    
    /// Set schedule action status for a device to allowed (if said device is online) if schedule already has a device from the same node
    /// - Parameter availableDevices: list of available devices
    /// - Returns: list of available devices after configuration
    private func configureDeviceScheduleActions(_ availableDevices: [Device]) -> [Device] {
        var finalDevicesList = [Device]()
        var selectedCount = 0
        var deSelectedCount = 0
        var nodesSelected = [String: Bool]()
        for device in availableDevices {
            if let node_id = device.node?.node_id {
                if device.selectedParams > 0 {
                    nodesSelected[node_id] = true
                }
            }
        }
        for device in availableDevices {
            if let node_id = device.node?.node_id, let selected = nodesSelected[node_id], selected {
                switch device.scheduleAction {
                case .deviceOffline:
                    device.scheduleActionStatus = .deviceOffline
                default:
                    device.scheduleActionStatus = .allowed
                }
            }
            //Sort devices such that selected devices are on top and not selected devices are on bottom
            if device.selectedParams > 0 {
                finalDevicesList.insert(device, at: selectedCount)
                selectedCount+=1
            } else {
                finalDevicesList.insert(device, at: selectedCount+deSelectedCount)
                deSelectedCount+=1
            }
        }
        return finalDevicesList
    }
    
    /// Sort devices in the following order [allowed devices, max reached devices, offline devices]
    /// - Parameter availableDevices: list of avaiable devices
    /// - Returns: list of avaiable devices after sorting
    private func sortDevices(availableDevices: [Device]) -> [Device] {
        var devices = [Device]()
        var availableCount = 0
        var maxReachedCount = 0
        var offlineCount = 0
        for device in availableDevices {
            let status = device.scheduleAction
            switch status {
            case .allowed:
                devices.insert(device, at: availableCount)
                availableCount+=1
            case .maxScheduleReached(_):
                devices.insert(device, at: availableCount+maxReachedCount)
                maxReachedCount+=1
            case .deviceOffline:
                devices.insert(device, at: availableCount+maxReachedCount+offlineCount)
                offlineCount+=1
            }
        }
        return devices
    }

    private func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        textField.addConstraint(heightConstraint)
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
    }

    // MARK: -

    func setRepeatStatus() {
        if ESPScheduler.shared.currentSchedule.trigger.days == 0 {
            onDaysImageView.isHidden = true
            dailyImageView.isHidden = false
            daysLabel.text = "Never"
        } else {
            onDaysImageView.isHidden = false
            dailyImageView.isHidden = true
            daysLabel.text = ESPScheduler.shared.currentSchedule.week.getShortDescription()
        }
    }
}

extension ScheduleViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Restrict the length of name of schedule to be equal to or less than 32 characters.
        let maxLength = 32
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
}
