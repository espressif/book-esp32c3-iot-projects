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
//  NodeGroupsViewController.swift
//  ESPRainMaker
//

import UIKit

class NodeGroupsViewController: UIViewController {
    // IB Outlets
    @IBOutlet var addButton: UIButton!
    @IBOutlet var initialView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var editButton: BarButton!

    // Pull to refresh control
    private let refreshControl = UIRefreshControl()

    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide tab bar
        tabBarController?.tabBar.isHidden = true

        // Add pull to refresh on current table view
        refreshControl.addTarget(self, action: #selector(fetchGroupList), for: .valueChanged)
        tableView.refreshControl = refreshControl
        refreshControl.tintColor = .clear

        // Table view customisation
        tableView.tableFooterView = UIView()

        // Load initial view
        setupInitialView()
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)

        // Disable editing in table view
        tableView.isEditing = false
        editButton.setTitle("Edit", for: .normal)

        // Check if list is updated to reload table view
        if NodeGroupManager.shared.listUpdated {
            if !initialView.isHidden {
                displayTableView()
            }
            tableView.reloadData()
        }
    }

    // MARK: - IB Actions

    // Enable/disable editing on table view
    @IBAction func editTableView(_ sender: UIButton) {
        tableView.isEditing = !tableView.isEditing
        sender.setTitle(tableView.isEditing ? "Done" : "Edit", for: .normal)
    }

    // Go to home screen on back button action
    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    // Refetch group list on button action
    @IBAction func refreshNodeGroupList(_: Any) {
        fetchGroupList()
    }

    // Fetch list of groups for current user
    @objc func fetchGroupList() {
        refreshControl.endRefreshing()
        Utility.showLoader(message: "", view: view)
        NodeGroupManager.shared.getNodeGroups { _, error in
            User.shared.updateDeviceList = true
            Utility.hideLoader(view: self.view)
            // Check if api throws error
            guard let getDeviceError = error else {
                DispatchQueue.main.async {
                    self.setupInitialView()
                }
                return
            }
            Utility.showToastMessage(view: self.view, message: getDeviceError.description, duration: 5.0)
        }
    }

    // MARK: - Private Methods

    // Method to display table view
    private func displayTableView() {
        // Reload tableview data
        initialView.isHidden = true
        tableView.isHidden = false
        addButton.isHidden = false
        editButton.isHidden = false
    }

    // Method to hide table view
    private func hideTableView() {
        // Load initial view if group list is empty
        tableView.isHidden = true
        initialView.isHidden = false
        addButton.isHidden = true
        editButton.isHidden = true
    }

    // Method to show inital view based on group count
    private func setupInitialView() {
        // Check if group count is more than zero.
        // Display group list in table view.
        if NodeGroupManager.shared.nodeGroups.count > 0 {
            displayTableView()
            tableView.reloadData()
        } else {
            // Hide table view.
            hideTableView()
        }
    }
}

extension NodeGroupsViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return NodeGroupManager.shared.nodeGroups.count
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeGroupsTVC", for: indexPath) as! NodeGroupTableViewCell
        let nodeGroup = NodeGroupManager.shared.nodeGroups[indexPath.section]
        cell.groupLabel.text = nodeGroup.group_name
        var totalDeviceCount = 0
        var deviceList: [String] = []
        // Iterate through list of nodes to fetch device information
        if let nodes = nodeGroup.nodeList {
            for node in nodes {
                // Update device count with number of devices in node
                totalDeviceCount = totalDeviceCount + (node.devices?.count ?? 0)
                // Append device name of every node in a group
                if let devices = node.devices {
                    for device in devices {
                        deviceList.append(device.deviceName)
                    }
                }
            }
        }
        // Show device information on table view cell of groups
        cell.deviceCountLabel.text = "\(totalDeviceCount) devices"
        cell.devicesLabel.text = deviceList.joined(separator: ",")
        return cell
    }
}

extension NodeGroupsViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        // On selection of any group, go to edit page
        let selectedGroup = NodeGroupManager.shared.nodeGroups[indexPath.section]
        let nodeGroupStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
        let editNodeGroupVC = nodeGroupStoryBoard.instantiateViewController(withIdentifier: "editNodeGroupVC") as! EditNodeGroupViewController
        editNodeGroupVC.currentNodeGroup = selectedGroup
        navigationController?.pushViewController(editNodeGroupVC, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Check if user wants to remove the node group
        if editingStyle == .delete {
            // Add confirmation alert before removing node group
            let alertController = UIAlertController(title: "Remove", message: "Are you sure to remove this group?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
                Utility.showLoader(message: "Removing group...", view: self.view)
                // Perform remove node group operation for selected group
                NodeGroupManager.shared.performNodeGroupOperation(group: NodeGroupManager.shared.nodeGroups[indexPath.section], parameter: nil, method: .delete) { success, error in
                    Utility.hideLoader(view: self.view)
                    // Check if remove node group operation is successful
                    if success {
                        DispatchQueue.main.async {
                            NodeGroupManager.shared.nodeGroups.remove(at: indexPath.section)
                            tableView.deleteSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
                            User.shared.updateDeviceList = true
                            if NodeGroupManager.shared.nodeGroups.count < 1 {
                                // Load initial view if group list is empty
                                self.hideTableView()
                            }
                        }

                    } else {
                        // In case remove operation is unsuccessful, show error as toast
                        Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                    }
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        }
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        return view
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 70.0
    }
}
