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
//  DeviceGroupCollectionViewCell.swift
//  ESPRainMaker
//

import UIKit

protocol DeviceGroupCollectionViewCellDelegate {
    func didSelectDevice(device: Device)
    func didSelectNode(node: Node)
}

class DeviceGroupCollectionViewCell: UICollectionViewCell {
    var refreshAction: () -> Void = {}
    @IBOutlet var collectionView: UICollectionView!

    var singleDeviceNodeCount = 0
    var datasource: [Node] = []
    var delegate: DeviceGroupCollectionViewCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func refreshDeviceList() {
        refreshAction()
    }

    func getDeviceAt(indexPath: IndexPath) -> Device {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return datasource[indexPath.row].devices![0]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return datasource[index].devices![indexPath.row]
    }

    func getNodeAt(indexPath: IndexPath) -> Node {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return datasource[indexPath.section]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return datasource[index]
    }
}

extension DeviceGroupCollectionViewCell: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentDevice = getDeviceAt(indexPath: indexPath)
        delegate?.didSelectDevice(device: currentDevice)
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0, singleDeviceNodeCount > 0 {
            return CGSize(width: 0, height: 10)
        }
        return CGSize(width: collectionView.bounds.width, height: 68.0)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection _: Int) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
}

extension DeviceGroupCollectionViewCell: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var index = section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return singleDeviceNodeCount
            }
            index = index + singleDeviceNodeCount - 1
        }
        return datasource[index].devices?.count ?? 0
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        let count = datasource.count
        if count == 0 {
            return count
        }
        if singleDeviceNodeCount > 0 {
            return count - singleDeviceNodeCount + 1
        }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceCollectionViewCell", for: indexPath) as! DevicesCollectionViewCell
        cell.refresh()
        let device = getDeviceAt(indexPath: indexPath)
        cell.deviceName.text = device.getDeviceName()
        cell.device = device
        cell.switchButton.isHidden = true
        cell.primaryValue.isHidden = true

        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        cell.layer.shadowRadius = 0.5
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false

        cell.layer.backgroundColor = UIColor.white.withAlphaComponent(1.0).cgColor
        if device.node?.localNetwork ?? false {
            cell.statusView.isHidden = false
        } else if device.node?.isConnected ?? false {
            cell.statusView.isHidden = true
        } else {
            cell.statusView.isHidden = false
            cell.layer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
        }

        cell.offlineLabel.text = device.node?.nodeStatus ?? ""

        var primaryKeyFound = false

        if let primary = device.primary {
            if let primaryParam = device.params?.first(where: { param -> Bool in
                param.name == primary
            }) {
                primaryKeyFound = true
                if primaryParam.dataType?.lowercased() == "bool" {
                    if device.isReachable(), primaryParam.properties?.contains("write") ?? false {
                        cell.switchButton.alpha = 1.0
                        cell.switchButton.backgroundColor = UIColor.white
                        cell.switchButton.isEnabled = true
                        cell.switchButton.isHidden = false
                        cell.switchButton.setBackgroundImage(UIImage(named: "switch_off"), for: .normal)
                        if let value = primaryParam.value as? Bool {
                            if value {
                                cell.switchButton.setBackgroundImage(UIImage(named: "switch_on"), for: .normal)
                                cell.switchValue = true
                            }
                        }
                    } else {
                        cell.switchButton.isHidden = false
                        cell.switchButton.isEnabled = false
                        cell.switchButton.backgroundColor = UIColor(hexString: "#E5E5E5")
                        cell.switchButton.alpha = 0.4
                        cell.switchButton.setBackgroundImage(UIImage(named: "switch_disabled"), for: .normal)
                    }
                } else if primaryParam.dataType?.lowercased() == "string" {
                    cell.switchButton.isHidden = true
                    cell.primaryValue.text = primaryParam.value as? String ?? ""
                    cell.primaryValue.isHidden = false
                } else {
                    cell.switchButton.isHidden = true
                    if let value = primaryParam.value {
                        cell.primaryValue.text = "\(value)"
                        cell.primaryValue.isHidden = false
                    }
                }
            }
            if !primaryKeyFound {
                if let staticParams = device.attributes {
                    for item in staticParams {
                        if item.name == primary {
                            if let value = item.value as? String {
                                primaryKeyFound = true
                                cell.primaryValue.text = value
                                cell.primaryValue.isHidden = false
                            }
                        }
                    }
                }
            }
        }

        cell.deviceImageView.image = ESPRMDeviceType(rawValue: device.type ?? "")?.getImageFromDeviceType() ?? UIImage(named: Constants.dummyDeviceImage)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "deviceListCollectionReusableView", for: indexPath) as! DeviceListCollectionReusableView
        let node = getNodeAt(indexPath: indexPath)
        if singleDeviceNodeCount > 0 {
            if indexPath.section == 0 {
                headerView.headerLabel.isHidden = true
                headerView.infoButton.isHidden = true
                headerView.statusIndicator.isHidden = true
                headerView.borderWidth = 0.0
                return headerView
            }
        }
        headerView.headerLabel.isHidden = false
        headerView.infoButton.isHidden = false
        headerView.statusIndicator.isHidden = false
        headerView.headerLabel.text = node.info?.name ?? "Node"
        headerView.delegate = self
        headerView.nodeID = node.node_id ?? ""
        if node.isConnected {
            headerView.statusIndicator.backgroundColor = UIColor.green
        } else {
            headerView.statusIndicator.backgroundColor = UIColor.lightGray
        }
        return headerView
    }
}

extension DeviceGroupCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        var cellWidth: CGFloat = 0
        if width > 450 {
            cellWidth = (width - 60) / 3.0
        } else {
            cellWidth = (width - 30) / 2.0
        }
        return CGSize(width: cellWidth, height: 110.0)
    }
}

extension DeviceGroupCollectionViewCell: DeviceListHeaderProtocol {
    func deviceInfoClicked(nodeID: String) {
        if let node = datasource.first(where: { item -> Bool in
            item.node_id == nodeID
        }) {
            delegate?.didSelectNode(node: node)
        }
    }
}
