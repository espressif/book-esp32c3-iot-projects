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
//  CentralSwitchTableViewCell.swift
//  ESPRainMaker
//

import UIKit

class CentralSwitchTableViewCell: UITableViewCell {
    @IBOutlet var backView: UIView!
    @IBOutlet var powerButton: UIButton!

    var device: Device!
    var param: Param!
    var paramDelegate: ParamUpdateProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear

        backView.layer.borderWidth = 1
        backView.layer.cornerRadius = 10
        backView.layer.borderColor = UIColor.clear.cgColor
        backView.layer.masksToBounds = true

        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
    }

    @IBAction func powerButtonPressed(_: Any) {
        let currentValue = param.value as! Bool
        if currentValue {
            DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [param.name ?? "": false]], delegate: paramDelegate)
            powerButton.setBackgroundImage(UIImage(named: "central_switch_off"), for: .normal)
            param.value = false
        } else {
            DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [param.name ?? "": true]], delegate: paramDelegate)
            powerButton.setBackgroundImage(UIImage(named: "central_switch_on"), for: .normal)
            param.value = true
        }
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.reloadCollectionView)))
    }
}
