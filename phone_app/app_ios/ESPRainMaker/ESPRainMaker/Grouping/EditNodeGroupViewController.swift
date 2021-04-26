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
//  EditNodeGroupViewController.swift
//  ESPRainMaker
//

import UIKit

// Class to manage renaming and removing of existing device in a group
class EditNodeGroupViewController: UIViewController {
    @IBOutlet var addButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addButton: UIButton!

    // List of nodes in the group
    var groupNodes: [Node] = []
    // List of other nodes available but not included in the group
    var remainingNodes: [Node] = []
    var singleDeviceNodeCount = 0
    var currentNodeGroup: NodeGroup!

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true

        // Show option to Add Device if there are available nodes not already added in the current group
        getRemainingNodes()
        if remainingNodes.count < 1 {
            addButtonHeightConstraint.constant = 0
            addButton.isHidden = true
        }

        // Configure collection view for display of group nodes
        getSingleDeviceNodeCount()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        collectionView.collectionViewLayout = GroupDevicesFlowLayout()
        // Add name of current group in label
        nameLabel.text = currentNodeGroup.group_name ?? ""
    }

    // MARK: - IB Actions

    @IBAction func removeGroupButtonPressed(_: Any) {
        // Add confirmation alert before removing node group
        let alertController = UIAlertController(title: "Remove", message: "Are you sure to remove this group?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
            Utility.showLoader(message: "Removing group...", view: self.view)
            // Perform remove node group operation for selected group
            NodeGroupManager.shared.performNodeGroupOperation(group: self.currentNodeGroup, parameter: nil, method: .delete) { success, error in
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    // Check if remove node group operation is successful
                    if success {
                        if let index = NodeGroupManager.shared.nodeGroups.firstIndex(where: { $0.group_id == self.currentNodeGroup.group_id }) {
                            NodeGroupManager.shared.nodeGroups.remove(at: index)
                        }
                        User.shared.updateDeviceList = true
                        NodeGroupManager.shared.listUpdated = true
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        // In case remove operation is unsuccessful, show error as toast
                        Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                    }
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func nameButtonPressed(_: Any) {
        // Open dialog box for renaming the group
        let input = UIAlertController(title: "Enter new name", message: "", preferredStyle: .alert)
        // Add textfield for entering new name of the group
        input.addTextField { textField in
            textField.text = self.currentNodeGroup.group_name ?? ""
        }
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in

        }))
        input.addAction(UIAlertAction(title: "Rename", style: .default, handler: { [weak input] _ in
            let textField = input?.textFields![0]
            guard let name = textField?.text, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                return
            }
            Utility.showLoader(message: "Renaming...", view: self.view)
            // API call for renaming the existing group
            NodeGroupManager.shared.performNodeGroupOperation(group: self.currentNodeGroup, parameter: ["group_name": name], method: .put) { success, error in
                Utility.hideLoader(view: self.view)
                // Rename operation is successful.
                if success {
                    DispatchQueue.main.async {
                        User.shared.updateDeviceList = true
                        self.nameLabel.text = name
                        // Update group instance with new name
                        self.currentNodeGroup.group_name = name
                    }
                } else {
                    Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                }
            }
        }))
        present(input, animated: true, completion: nil)
    }

    @IBAction func addDeviceButtonPressed(_: Any) {
        let nodeGroupStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
        let addDeviceNodeVC = nodeGroupStoryBoard.instantiateViewController(withIdentifier: "addNodeGroupVC") as! AddNodeGroupsViewController
        addDeviceNodeVC.nodeList = remainingNodes
        addDeviceNodeVC.currentGroup = currentNodeGroup
        navigationController?.pushViewController(addDeviceNodeVC, animated: true)
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    private func getSingleDeviceNodeCount() {
        singleDeviceNodeCount = 0
        if let nodeList = currentNodeGroup.nodeList {
            for item in nodeList {
                if item.devices?.count == 1 {
                    singleDeviceNodeCount += 1
                }
            }
        }
    }

    // MARK: - Private Methods

    private func getDeviceAt(indexPath: IndexPath) -> Device {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return currentNodeGroup.nodeList![indexPath.row].devices![0]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return currentNodeGroup.nodeList![index].devices![indexPath.row]
    }

    private func getNodeAt(indexPath: IndexPath) -> Node {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return currentNodeGroup.nodeList![indexPath.section]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return currentNodeGroup.nodeList![index]
    }

    private func getRemainingNodes() {
        if currentNodeGroup.nodes?.count ?? 0 < 1 {
            remainingNodes = User.shared.associatedNodeList ?? []
            return
        }
        var nodeList: [Node] = []
        for each in User.shared.associatedNodeList ?? [] {
            if let nodes = currentNodeGroup.nodes, !nodes.contains(each.node_id ?? "") {
                nodeList.append(each)
            }
        }
        remainingNodes = nodeList
    }
}

extension EditNodeGroupViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0, singleDeviceNodeCount > 0 {
            return CGSize(width: 0, height: 10.0)
        }
        return CGSize(width: collectionView.bounds.width, height: 55.0)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection _: Int) -> CGSize {
        return CGSize(width: 0, height: 10.0)
    }
}

extension EditNodeGroupViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var index = section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return singleDeviceNodeCount
            }
            index = index + singleDeviceNodeCount - 1
        }
        return currentNodeGroup.nodeList![index].devices?.count ?? 0
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        let count = currentNodeGroup.nodeList?.count ?? 0
        if count == 0 {
            return count
        }
        if singleDeviceNodeCount > 0 {
            return count - singleDeviceNodeCount + 1
        }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "selectGroupNodeCVC", for: indexPath) as! SelectGroupNodeCollectionViewCell
        let device = getDeviceAt(indexPath: indexPath)
        cell.deviceName.text = device.getDeviceName()
        if device.node?.devices?.count ?? 0 > 1 {
            cell.selectButton.isHidden = true
            cell.selectedImage.isHidden = true
        } else {
            cell.selectButton.isHidden = false
            cell.selectedImage.isHidden = false
        }

        cell.selectButtonAction = {
            Utility.showLoader(message: "Removing device..", view: self.view)
            let parameter: [String: Any] = ["operation": "remove", "nodes": [device.node?.node_id ?? ""]]
            NodeGroupManager.shared.performNodeGroupOperation(group: self.currentNodeGroup, parameter: parameter, method: .put) { success, error in
                Utility.hideLoader(view: self.view)
                if success {
                    DispatchQueue.main.async {
                        User.shared.updateDeviceList = true
                        self.remainingNodes.insert(device.node!, at: 0)
                        if let index = self.currentNodeGroup.nodes?.firstIndex(of: device.node?.node_id ?? "") {
                            self.currentNodeGroup.nodes?.remove(at: index)
                        }
                        if let index = self.currentNodeGroup.nodeList?.firstIndex(where: { $0.node_id == device.node?.node_id ?? "" }) {
                            self.currentNodeGroup.nodeList?.remove(at: index)
                        }
                        self.singleDeviceNodeCount = self.singleDeviceNodeCount - 1

                        if self.remainingNodes.count > 0, self.addButton.isHidden {
                            self.addButtonHeightConstraint.constant = 55
                            self.addButton.isHidden = false
                        }

                        self.collectionView.reloadData()
                    }
                } else {
                    Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                }
            }
        }

        cell.layer.backgroundColor = UIColor.white.cgColor
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        cell.layer.shadowRadius = 0.5
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false

        cell.deviceImageView.image = ESPRMDeviceType(rawValue: device.type ?? "")?.getImageFromDeviceType() ?? UIImage(named: Constants.dummyDeviceImage)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "selectNodeCollectionReusableView", for: indexPath) as! SelectNodeHeaderCollectionReusableView
            let node = getNodeAt(indexPath: indexPath)
            if singleDeviceNodeCount > 0 {
                if indexPath.section == 0 {
                    headerView.topBorder.backgroundColor = .clear
                    headerView.headerLabel.isHidden = true
                    headerView.selectButton.isHidden = true
                    headerView.selectedImage.isHidden = true
                    headerView.borderWidth = 0.0
                    return headerView
                } else {
                    headerView.headerLabel.isHidden = false
                    headerView.selectButton.isHidden = false
                    headerView.selectedImage.isHidden = false
                }
            }
            headerView.headerLabel.text = node.info?.name ?? "Node"
            headerView.selectButtonAction = {
                Utility.showLoader(message: "Removing device..", view: self.view)
                let parameter: [String: Any] = ["operation": "remove", "nodes": [node.node_id ?? ""]]
                NodeGroupManager.shared.performNodeGroupOperation(group: self.currentNodeGroup, parameter: parameter, method: .put) { success, error in
                    Utility.hideLoader(view: self.view)
                    if success {
                        DispatchQueue.main.async {
                            User.shared.updateDeviceList = true
                            self.remainingNodes.append(node)
                            if let index = self.currentNodeGroup.nodes?.firstIndex(of: node.node_id ?? "") {
                                self.currentNodeGroup.nodes?.remove(at: index)
                            }
                            if let index = self.currentNodeGroup.nodeList?.firstIndex(where: { $0.node_id == node.node_id ?? "" }) {
                                self.currentNodeGroup.nodeList?.remove(at: index)
                            }

                            if self.remainingNodes.count > 0, self.addButton.isHidden {
                                self.addButtonHeightConstraint.constant = 55
                                self.addButton.isHidden = false
                            }

                            self.collectionView.reloadData()
                        }
                    } else {
                        Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                    }
                }
            }
            return headerView
        default:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "selectionNodeFooterCV", for: indexPath) as! SelectNodeFooterCollectionReusableView
            if singleDeviceNodeCount > 0 {
                footerView.bottomBorder.backgroundColor = .clear
            }
            return footerView
        }
    }
}
