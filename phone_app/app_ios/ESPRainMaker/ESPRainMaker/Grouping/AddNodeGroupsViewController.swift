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
//  AddNodeGroupsViewController.swift
//  ESPRainMaker
//

import UIKit

// Class for adding nodes to existing groups
class AddNodeGroupsViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var doneButton: UIButton!

    var currentGroup: NodeGroup!
    var singleDeviceNodeCount = 0
    var selectedNodes: [String: Node] = [:]
    // List of node available for addition
    var nodeList: [Node] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        getSingleDeviceNodeCount()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        collectionView.collectionViewLayout = GroupDevicesFlowLayout()
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func doneButtonPressed(_: Any) {
        Utility.showLoader(message: "Adding devices..", view: view)
        let parameter: [String: Any] = ["operation": "add", "nodes": Array(selectedNodes.keys)]
        NodeGroupManager.shared.performNodeGroupOperation(group: currentGroup, parameter: parameter, method: .put) { success, error in
            Utility.hideLoader(view: self.view)
            if success {
                DispatchQueue.main.async {
                    User.shared.updateDeviceList = true
                    var nodeList: [Node] = []
                    if let listOfNodes = self.currentGroup.nodeList {
                        nodeList = listOfNodes
                    }

                    if self.currentGroup.nodes != nil {
                        self.currentGroup.nodes?.append(contentsOf: Array(self.selectedNodes.keys))
                    } else {
                        self.currentGroup.nodes = Array(self.selectedNodes.keys)
                    }
                    for each in User.shared.associatedNodeList ?? [] {
                        if Array(self.selectedNodes.keys).contains(each.node_id ?? "") {
                            if each.devices?.count ?? 0 > 1 {
                                nodeList.append(each)
                            } else {
                                nodeList.insert(each, at: 0)
                            }
                        }
                    }
                    self.currentGroup.nodeList = nodeList
                    NodeGroupManager.shared.listUpdated = true
                    let controllers = self.navigationController?.viewControllers
                    for vc in controllers! {
                        if vc is NodeGroupsViewController {
                            _ = self.navigationController?.popToViewController(vc as! NodeGroupsViewController, animated: true)
                        } else if vc is DevicesViewController {
                            self.navigationController?.popToRootViewController(animated: false)
                        }
                    }
                }
            } else {
                Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
            }
        }
    }

    // MARK: - Private Methods

    private func getSingleDeviceNodeCount() {
        singleDeviceNodeCount = 0
        for item in nodeList {
            if item.devices?.count == 1 {
                singleDeviceNodeCount += 1
            }
        }
    }

    private func getDeviceAt(indexPath: IndexPath) -> Device {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return nodeList[indexPath.row].devices![0]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return nodeList[index].devices![indexPath.row]
    }

    private func getNodeAt(indexPath: IndexPath) -> Node {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return nodeList[indexPath.section]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return nodeList[index]
    }

    private func updateDoneButton() {
        if selectedNodes.keys.count > 0 {
            doneButton.isHidden = false
        } else {
            doneButton.isHidden = true
        }
    }
}

extension AddNodeGroupsViewController: UICollectionViewDelegateFlowLayout {
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

extension AddNodeGroupsViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var index = section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return singleDeviceNodeCount
            }
            index = index + singleDeviceNodeCount - 1
        }
        return nodeList[index].devices?.count ?? 0
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        let count = nodeList.count
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
            if self.selectedNodes.removeValue(forKey: device.node?.node_id ?? "") != nil {
                cell.selectedImage.image = UIImage(named: "unselected_empty")
                self.updateDoneButton()
            } else {
                self.selectedNodes[device.node?.node_id ?? ""] = device.node
                cell.selectedImage.image = UIImage(named: "selected")
                self.updateDoneButton()
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
                }
            }
            headerView.headerLabel.text = node.info?.name ?? "Node"
            headerView.selectButtonAction = {
                if self.selectedNodes.removeValue(forKey: node.node_id ?? "") != nil {
                    headerView.selectedImage.image = UIImage(named: "unselected_empty")
                    self.updateDoneButton()
                } else {
                    self.selectedNodes[node.node_id ?? ""] = node
                    headerView.selectedImage.image = UIImage(named: "selected")
                    self.updateDoneButton()
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
