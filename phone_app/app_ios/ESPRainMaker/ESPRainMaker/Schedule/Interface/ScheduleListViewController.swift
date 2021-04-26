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
//  ScheduleListViewController.swift
//  ESPRainMaker
//

import UIKit

class ScheduleListViewController: UIViewController {
    @IBOutlet var addButton: UIButton!
    @IBOutlet var initialView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var editButton: BarButton!
    @IBOutlet var addScheduleButton: PrimaryButton!
    @IBOutlet var initialLabel: UILabel!
    @IBOutlet var networkIndicator: UIView!

    private let refreshControl = UIRefreshControl()
    var scheduleList: [String] = []

    // MARK: - Overriden methods

    override func viewDidLoad() {
        super.viewDidLoad()

        showScheduleList()

        navigationController?.navigationBar.isHidden = true
        tableView.tableFooterView = UIView()

        refreshControl.addTarget(self, action: #selector(refreshScheduleList(_:)), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        tableView.refreshControl = refreshControl
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.isEditing = false
        editButton.setTitle("Edit", for: .normal)
        ESPScheduler.shared.currentScheduleKey = nil
        // Show UI based on scheudle list count
        if User.shared.updateDeviceList {
            User.shared.updateDeviceList = false
            Utility.showLoader(message: "", view: view)
            refreshScheduleList(self)
        } else {
            ESPScheduler.shared.currentScheduleKey = nil
            showScheduleList()
        }
        checkNetworkUpdate()
        NotificationCenter.default.addObserver(self, selector: #selector(checkNetworkUpdate), name: Notification.Name(Constants.networkUpdateNotification), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.networkUpdateNotification), object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == Constants.addScheduleSegue || segue.identifier == Constants.addNewScheduleSegue {
            if let vc = segue.destination as? ScheduleViewController {
                vc.delegate = self
            }
            ESPScheduler.shared.addSchedule()
        }
    }

    @objc func checkNetworkUpdate() {
        DispatchQueue.main.async {
            if ESPNetworkMonitor.shared.isConnectedToNetwork {
                self.networkIndicator.isHidden = true
            } else {
                self.networkIndicator.isHidden = false
            }
        }
    }

    // MARK: -  IBActions

    @IBAction func editTableView(_ sender: UIButton) {
        tableView.isEditing = !tableView.isEditing
        sender.setTitle(tableView.isEditing ? "Done" : "Edit", for: .normal)
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func refreshScheduleList(_: Any) {
        refreshControl.endRefreshing()
        NetworkManager.shared.getNodes { nodes, error in
            Utility.hideLoader(view: self.view)
            if error != nil {
                DispatchQueue.main.async {
                    Utility.showToastMessage(view: self.view, message: "Network error: \(error?.description ?? "Something went wrong!!")")
                }
            } else {
                User.shared.associatedNodeList = nodes
                DispatchQueue.main.async {
                    self.showScheduleList()
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }

    // MARK: Private Methods

    func showScheduleList() {
        getScheduleList()
        if ESPScheduler.shared.availableDevices.count < 1 {
            tableView.isHidden = true
            addButton.isHidden = true
            initialView.isHidden = false
            editButton.isHidden = true
            addButton.isHidden = true
            addScheduleButton.isHidden = true
            initialLabel.text = "You don't have any device \n that supports this."
        } else if scheduleList.count < 1 {
            tableView.isHidden = true
            addButton.isHidden = true
            initialView.isHidden = false
            editButton.isHidden = true
            addButton.isHidden = true
            addScheduleButton.isHidden = false
            initialLabel.text = "No Schedules added."
        } else {
            tableView.isHidden = false
            addButton.isHidden = false
            initialView.isHidden = true
            editButton.isHidden = false
        }
    }

    func getScheduleList() {
        scheduleList.removeAll()
        scheduleList = [String](ESPScheduler.shared.schedules.keys).sorted(by: { first, second -> Bool in
            // Sorting schedule list by time
            let firstArray = first.components(separatedBy: ".")
            let firstMinutes = Int(firstArray[firstArray.count - 2]) ?? 0
            let secondArray = second.components(separatedBy: ".")
            let secondMinutes = Int(secondArray[secondArray.count - 2]) ?? 0
            return firstMinutes < secondMinutes
        })
        tableView.reloadData()
    }
    
    /// Format schedule list after switching schedule status
    /// - Parameters:
    ///   - index: position of schedule in list
    ///   - enabled: is schedule enabled or disabled
    private func formatScheduleList(index: Int, enabled: Bool) {
        let schedule = ESPScheduler.shared.schedules[scheduleList[index]]
        ESPScheduler.shared.schedules[scheduleList[index]] = nil
        let scheduleKey = scheduleList[index]
        var scheduleKeys = scheduleKey.components(separatedBy: ".")
        scheduleKeys[scheduleKeys.count-1] = enabled ? "true": "false"
        scheduleList[index] = scheduleKeys.joined(separator: ".")
        ESPScheduler.shared.schedules[scheduleList[index]] = schedule
    }

}

extension ScheduleListViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row % 2 != 0 {
            return 20.0
        }
        return 80.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row % 2 != 0 {
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
        let scheduleVC = storyboard?.instantiateViewController(withIdentifier: "scheduleVC") as! ScheduleViewController
        scheduleVC.delegate = self
        ESPScheduler.shared.currentSchedule = ESPScheduler.shared.schedules[scheduleList[indexPath.row/2]]!
        scheduleVC.scheduleKey = scheduleList[indexPath.row/2]
        ESPScheduler.shared.currentScheduleKey = scheduleList[indexPath.row/2]
        navigationController?.pushViewController(scheduleVC, animated: true)
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let view = UIView(frame: CGRect.zero)
        return view
    }

    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.row % 2 != 0 {
            return
        }
        if editingStyle == .delete {
            let alertController = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
                DispatchQueue.main.async {
                    Utility.showLoader(message: "", view: self.view)
                    ESPScheduler.shared.deleteScheduleAt(key: self.scheduleList[indexPath.row/2], onView: self.view) { result  in
                        switch result {
                        case .success(let nodesFailed):
                            DispatchQueue.main.asyncAfter(deadline: .now()+1.0, execute: {
                                if !nodesFailed {
                                    Utility.showToastMessage(view: self.view, message: "Schedule deleted successfully.", duration: 2.0)
                                }
                                self.refreshScheduleList(self)
                            })
                        default:
                            Utility.hideLoader(view: self.view)
                            Utility.showToastMessage(view: self.view, message: ESPScheduleConstants.scheduleDeletionFailed, duration: 2.0)
                        }
                    }
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension ScheduleListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row % 2 != 0 {
            let cell = UITableViewCell(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.width, height: 20.0))
            cell.contentView.backgroundColor = .clear
            cell.isUserInteractionEnabled = false
            cell.backgroundColor = .clear
            cell.isHidden = true
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "scheduleListTVC", for: indexPath) as! ScheduleListTableViewCell
        let schedule = ESPScheduler.shared.schedules[scheduleList[indexPath.row/2]]!
        ESPScheduler.shared.currentSchedule = schedule
        ESPScheduler.shared.configureDeviceForCurrentSchedule()
        cell.schedule = schedule
        cell.scheduleLabel.text = schedule.name ?? ""
        cell.actionLabel.text = ESPScheduler.shared.getActionList()
        cell.timerLabel.text = schedule.trigger.getTimeDetails()
        if schedule.trigger.days == 0 {
            cell.daysLabel.text = "Once"
        } else if schedule.trigger.days == 127 {
            cell.daysLabel.text = "Everyday"
        } else {
            let dayDescription = schedule.week.getShortDescription()
            if dayDescription.lowercased() == "weekends" || dayDescription.lowercased() == "weekdays" {
                cell.daysLabel.text = "\(dayDescription.dropLast().lowercased())"
            } else {
                cell.daysLabel.text = "\(dayDescription)"
            }
        }
        cell.scheduleSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        cell.scheduleSwitch.setOn(schedule.enabled, animated: true)
        cell.index = indexPath.row/2
        cell.delegate = self
        return cell
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 2*scheduleList.count
    }

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }
}

extension ScheduleListViewController: ScheduleListTableViewCellDelegate {
    
    func scheduleStateChanged(index: Int, enabled: Bool, shouldRefresh: Bool) {
        if !shouldRefresh, index < scheduleList.count {
            self.formatScheduleList(index: index, enabled: enabled)
        } else {
            self.refreshScheduleList(self)
        }
    }
}

extension ScheduleListViewController: ServiceUpdateActionsDelegate {
    func serviceAdded() {
        Utility.showToastMessage(view: self.view, message: ESPScheduleConstants.scheduleAddSuccess, duration: 2.0)
    }
    
    func serviceUpdated() {
        Utility.showToastMessage(view: self.view, message: ESPScheduleConstants.scheduleUpdateSuccess, duration: 2.0)
    }
    
    func serviceRemoved() {
        Utility.showToastMessage(view: self.view, message: ESPScheduleConstants.scheduleDeletionSuccess, duration: 2.0)
    }
}
