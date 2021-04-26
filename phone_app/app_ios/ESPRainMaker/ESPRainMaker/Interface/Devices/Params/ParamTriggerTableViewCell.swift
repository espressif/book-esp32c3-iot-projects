// Copyright 2022 Espressif Systems
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
//  ParamTriggerTableViewCell.swift
//  ESPRainMaker
//

import UIKit

// Class to show param of ui type "esp.ui.trigger"
class ParamTriggerTableViewCell: TriggerTableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Customise UI elements for param screen
        checkButton.isHidden = true
        leadingSpaceConstraint.constant = 15.0
        trailingSpaceConstraint.constant = 15.0

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
    
    @IBAction override func triggerPressed(_ triggerButton : Any) {
        super.triggerPressed(_: triggerButton)
        DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: true]], delegate: paramDelegate)
    }
}
