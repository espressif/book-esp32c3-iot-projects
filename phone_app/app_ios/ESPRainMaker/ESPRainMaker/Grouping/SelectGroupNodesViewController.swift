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
//  SelectGroupNodesViewController.swift
//  ESPRainMaker
//

import UIKit

// Class for adding nodes to the group
class SelectGroupNodesViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView!

    var newGroup: NodeGroup!
    var singleDeviceNodeCount = 0
    // List that contains all nodes currently selected
    var selectedNodes: [String: Node] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        getSingleDeviceNodeCount()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        collectionView.collectionViewLayout = GroupDevicesFlowLayout()
    }

    // MARK: - IB Actions

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func doneButtonPressed(_: Any) {
        // Start creating new group on action of Done button
        Utility.showLoader(message: "Creating new group..", view: view)
        // Get list of selected nodes
        if selectedNodes.keys.count > 0 {
            newGroup.nodes = Array(selectedNodes.keys)
            newGroup.nodeList = Array(selectedNodes.values)
        }
        // API called for creating new group
        NodeGroupManager.shared.createNodeGroup(group: newGroup) { group, error in
            Utility.hideLoader(view: self.view)
            // Check response of API for error
            guard let createGroupError = error else {
                // No error group is created
                // Insert new group in sorted manner
                let insertionIndex = NodeGroupManager.shared.nodeGroups.insertionIndexOf(group!, isOrderedBefore: { $0.group_name ?? "" < $1.group_name ?? "" })
                NodeGroupManager.shared.nodeGroups.insert(group!, at: insertionIndex)
                // Set flag for list update
                User.shared.updateDeviceList = true
                NodeGroupManager.shared.listUpdated = true
                DispatchQueue.main.async {
                    // Add reference of node objects in the group
                    var nodeList: [Node] = []
                    for each in User.shared.associatedNodeList ?? [] {
                        if group?.nodes?.count ?? 0 > 0, group!.nodes!.contains(each.node_id ?? "") {
                            nodeList.append(each)
                        }
                    }
                    group!.nodeList = nodeList
                    // Navigate to node groups page when group is configured
                    let controllers = self.navigationController?.viewControllers
                    for vc in controllers! {
                        if vc is NodeGroupsViewController {
                            _ = self.navigationController?.popToViewController(vc as! NodeGroupsViewController, animated: true)
                        } else if vc is DevicesViewController {
                            self.navigationController?.popToRootViewController(animated: false)
                        }
                    }
                }
                return
            }
            // Show toast message in case of error with description
            Utility.showToastMessage(view: self.view, message: createGroupError.description, duration: 5.0)
        }
    }

    // MARK: - Private Methods

    private func getSingleDeviceNodeCount() {
        singleDeviceNodeCount = 0
        if let nodeList = User.shared.associatedNodeList {
            for item in nodeList {
                if item.devices?.count == 1 {
                    singleDeviceNodeCount += 1
                }
            }
        }
    }

    // Helper method to fetch device at given index
    private func getDeviceAt(indexPath: IndexPath) -> Device {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return User.shared.associatedNodeList![indexPath.row].devices![0]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return User.shared.associatedNodeList![index].devices![indexPath.row]
    }

    // Helper method to fetch node at given index
    private func getNodeAt(indexPath: IndexPath) -> Node {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return User.shared.associatedNodeList![indexPath.section]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return User.shared.associatedNodeList![index]
    }
}

extension SelectGroupNodesViewController: UICollectionViewDelegateFlowLayout {
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

extension SelectGroupNodesViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var index = section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return singleDeviceNodeCount
            }
            index = index + singleDeviceNodeCount - 1
        }
        return User.shared.associatedNodeList![index].devices?.count ?? 0
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        let count = User.shared.associatedNodeList?.count ?? 0
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

        // Configure cell for device in the current index
        let device = getDeviceAt(indexPath: indexPath)
        cell.deviceName.text = device.getDeviceName()
        if device.node?.devices?.count ?? 0 > 1 {
            cell.selectButton.isHidden = true
            cell.selectedImage.isHidden = true
        } else {
            cell.selectButton.isHidden = false
            cell.selectedImage.isHidden = false
        }

        // Add action for select button on the cell
        cell.selectButtonAction = {
            if self.selectedNodes.removeValue(forKey: device.node?.node_id ?? "") != nil {
                cell.selectedImage.image = UIImage(named: "unselected_empty")
            } else {
                self.selectedNodes[device.node?.node_id ?? ""] = device.node
                cell.selectedImage.image = UIImage(named: "selected")
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
        // Configure header and footer on the basis of node at current index
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
                }
            }
            headerView.headerLabel.text = node.info?.name ?? "Node"
            headerView.selectButtonAction = {
                if self.selectedNodes.removeValue(forKey: node.node_id ?? "") != nil {
                    headerView.selectedImage.image = UIImage(named: "unselected_empty")
                } else {
                    self.selectedNodes[node.node_id ?? ""] = node
                    headerView.selectedImage.image = UIImage(named: "selected")
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
