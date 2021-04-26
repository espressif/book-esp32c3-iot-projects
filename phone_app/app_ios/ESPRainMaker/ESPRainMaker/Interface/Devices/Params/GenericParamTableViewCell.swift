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
//  GenericParamTableViewCell.swift
//  ESPRainMaker
//

import UIKit

class GenericParamTableViewCell: GenericControlTableViewCell {
    override func layoutSubviews() {
        // Customise switch element for param screen
        // Hide row selection button
        super.layoutSubviews()
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

    @IBAction override func editButtonTapped(_: Any) {
        var input: UIAlertController!
        if param?.type == Constants.deviceNameParam {
            input = UIAlertController(title: attributeKey, message: "Enter device name of length 1-32 characters", preferredStyle: .alert)
        } else {
            input = UIAlertController(title: attributeKey, message: "Enter new value", preferredStyle: .alert)
        }
        input.addTextField { textField in
            textField.text = self.controlValue ?? ""
            self.addHeightConstraint(textField: textField)
        }

        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
        }))
        input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
            let valueTextField = input?.textFields![0]
            self.controlValue = valueTextField?.text
            self.doneButtonAction()
        }))
        parentViewController?.present(input, animated: true, completion: nil)
    }

    @objc override func doneButtonAction() {
        if let value = controlValue {
            if dataType.lowercased() == "int" {
                if let intValue = Int(value) {
                    if let bounds = param?.bounds, let max = bounds["max"] as? Int, let min = bounds["min"] as? Int {
                        if intValue >= min, intValue <= max {
                            DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: intValue]], delegate: paramDelegate)
                            controlValueLabel.text = value
                        } else {
                            showAlert(message: "Value out of bound.")
                        }
                    } else {
                        DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: intValue]], delegate: paramDelegate)
                        controlValueLabel.text = value
                    }
                } else {
                    showAlert(message: "Please enter a valid integer value.")
                }
            } else if dataType.lowercased() == "float" {
                if let floatValue = Float(value) {
                    if let bounds = param?.bounds, let max = bounds["max"] as? Float, let min = bounds["min"] as? Float {
                        if floatValue >= min, floatValue <= max {
                            DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: floatValue]], delegate: paramDelegate)
                            controlValueLabel.text = value
                        } else {
                            showAlert(message: "Value out of bound.")
                        }
                    } else {
                        DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: floatValue]], delegate: paramDelegate)
                        controlValueLabel.text = value
                    }
                } else {
                    showAlert(message: "Please enter a valid float value.")
                }
            } else if dataType.lowercased() == "bool" {
                if boolTypeValidValues.keys.contains(value) {
                    let validValue = boolTypeValidValues[value]!
                    if validValue == 0 {
                        DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: false]], delegate: paramDelegate)
                        controlValueLabel.text = value
                    } else {
                        DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: true]], delegate: paramDelegate)
                        controlValueLabel.text = value
                    }
                } else {
                    showAlert(message: "Please enter a valid boolean value.")
                }
            } else {
                if param?.type == Constants.deviceNameParam {
                    if value.count < 1 || value.count > 32 || value.isEmpty || value.trimmingCharacters(in: .whitespaces).isEmpty {
                        showAlert(message: "Please enter a valid device name within a range of 1-32 characters")
                        return
                    }
                }
                DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: controlValue]], delegate: paramDelegate) { result in
                    // Updates local storage in case parameter update is successfull.
                    if result == .success {
                        DispatchQueue.main.async {
                            self.device.deviceName = value
                            ESPLocalStorageHandler().saveNodeDetails(nodes: User.shared.associatedNodeList)
                        }
                    }
                }
                controlValueLabel.text = value

                if Configuration.shared.appConfiguration.supportLocalControl {
                    ESPScheduler.shared.updateDeviceName(for: device.node?.node_id, name: device.name ?? "", deviceName: value)
                }
            }
            param?.value = controlValue as Any
        }
    }
    
    override func paramTapped(_ sender: Any) {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        let chartVC = deviceStoryboard.instantiateViewController(withIdentifier: "chartsVC") as! ESPChartsViewController
        chartVC.param = param
        chartVC.device = device
        parentViewController?.navigationController?.pushViewController(chartVC, animated: true)
    }
}
