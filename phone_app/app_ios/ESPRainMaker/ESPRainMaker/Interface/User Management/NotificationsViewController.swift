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
//  NotificationsViewController.swift
//  ESPRainMaker
//

import UIKit

class NotificationsViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var initialView: UIView!
    var pendingRequests: [SharingRequest] = []
    var pastNotifications: [ESPNotifications] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400.0
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        refreshData()
    }
    
    func refreshData() {
        pastNotifications = ESPLocalStorageHandler().getDeliveredESPNotifications() ?? []
        getSharingRequests()
    }

    // MARK: - Private Methods

    // Method to fetch and filter pending sharing requests.
    private func getSharingRequests() {
        Utility.showLoader(message: "", view: view)
        NodeSharingManager.shared.getSharingRequests(primaryUser: false) { requests, error in
            Utility.hideLoader(view: self.view)
            guard let _ = error else {
                self.pendingRequests.removeAll()

                if let sharingRequests = requests {
                    for request in sharingRequests {
                        // Filtered requests with state as pending.
                        if request.request_status?.lowercased() == "pending" {
                            self.pendingRequests.append(request)
                        }
                    }
                }

                self.updateNotificationView()
                return
            }
            self.updateNotificationView()
        }
    }

    // Method to show table view based on count of pending sharing requests.
    private func updateNotificationView() {
        DispatchQueue.main.async {
            if self.pendingRequests.count < 1 && self.pastNotifications.count < 1 {
                self.tableView.isHidden = true
                self.initialView.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.initialView.isHidden = true
                self.tableView.reloadData()
            }
        }
    }

    // Method called on tap of deny button.
    private func denyButtonAction(request: SharingRequest) {
        Utility.showLoader(message: "", view: view)
        let parameter: [String: Any] = ["confirm_sharing": false, "request_id": request.request_id]
        // Declined request for node sharing.
        NodeSharingManager.shared.updateSharing(parameter: parameter) { success, error in
            Utility.hideLoader(view: self.view)
            guard let apiError = error else {
                if success {
                    if let index = self.pendingRequests.firstIndex(where: {
                        $0.request_id == request.request_id
                    }) {
                        self.pendingRequests.remove(at: index)
                        NodeSharingManager.shared.sharingRequestsReceived = self.pendingRequests
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                    // Check count for pending requests.
                    self.updateNotificationView()
                } else {
                    // Error while denying sharing request.
                    Utility.showToastMessage(view: self.view, message: "Unknown error: Unable to deny sharing request.", duration: 5.0)
                }
                return
            }
            Utility.showToastMessage(view: self.view, message: apiError.description, duration: 5.0)
        }
    }

    // Method called on tap of accept button.
    private func acceptButtonAction(request: SharingRequest) {
        Utility.showLoader(message: "", view: view)
        let parameter: [String: Any] = ["accept": true, "request_id": request.request_id]
        // Accept request for node sharing.
        NodeSharingManager.shared.updateSharing(parameter: parameter) { success, error in
            Utility.hideLoader(view: self.view)
            guard let apiError = error else {
                if success {
                    User.shared.updateDeviceList = true
                    if let index = self.pendingRequests.firstIndex(where: {
                        $0.request_id == request.request_id
                    }) {
                        self.pendingRequests.remove(at: index)
                        NodeSharingManager.shared.sharingRequestsReceived = self.pendingRequests
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                    // Check for request count to show appropriate UI.
                    self.updateNotificationView()
                } else {
                    // Error while accepting sharing request.
                    Utility.showToastMessage(view: self.view, message: "Unknown error: Unable to deny sharing request.", duration: 5.0)
                }
                return
            }
            Utility.showToastMessage(view: self.view, message: apiError.description, duration: 5.0)
        }
    }
    
    private func getNotificationTableViewCell(for indexPath:IndexPath) -> NotificationsTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notificationsTVC", for: indexPath) as! NotificationsTableViewCell
        let notification = pastNotifications[indexPath.section - pendingRequests.count]
        cell.bodyLabel.text = notification.body
        
        let timeDetails = notification.timestamp.dateTimeString()
        cell.timeLabel.text = timeDetails.time
        cell.dateLabel.text = timeDetails.date
        
        return cell
    }
    
    private func getAddSharingNotificationTableViewCell(for indexPath:IndexPath) -> AddSharingNotificationTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addSharingNotificationsTVC", for: indexPath) as! AddSharingNotificationTableViewCell
        let request = pendingRequests[indexPath.row]
        let primaryUserID = request.primary_user_name ?? ""
        let nodeIDs = request.node_ids?.joined(separator: ", ")
        if let deviceList = request.metadata, deviceList.count > 0 {
            if deviceList.count == 1 {
                cell.detailLabel.text = primaryUserID + " wants to share device \(deviceList[0]) with you."
            } else {
                var devices = ""
                for i in 0 ..< deviceList.count {
                    if i != 0 {
                        if i == deviceList.count - 1 {
                            devices.append(" & ")
                        } else {
                            devices.append(", ")
                        }
                    }
                    devices.append(deviceList[i])
                }
                cell.detailLabel.text = primaryUserID + " wants to share devices \(devices) with you."
            }
        } else {
            cell.detailLabel.text = primaryUserID + " wants to share node \(nodeIDs ?? "") with you."
        }
        cell.denyButtonAction = {
            self.denyButtonAction(request: request)
        }
        cell.acceptButtonAction = {
            self.acceptButtonAction(request: request)
        }
        return cell
    }
}

extension NotificationsViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 25.0
    }
}

extension NotificationsViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return pendingRequests.count + pastNotifications.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < pendingRequests.count {
            return getAddSharingNotificationTableViewCell(for: indexPath)
        } else {
           return getNotificationTableViewCell(for: indexPath)
        }
    }
}
