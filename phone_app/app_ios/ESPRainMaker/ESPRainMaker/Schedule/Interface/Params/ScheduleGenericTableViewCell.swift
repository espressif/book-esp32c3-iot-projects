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
//  ScheduleGenericTableViewCell.swift
//  ESPRainMaker
//
import UIKit

class ScheduleGenericTableViewCell: GenericControlTableViewCell {
    
    var cellType: DeviceServiceType = .none
    
    override func layoutSubviews() {
        super.layoutSubviews()
        checkButton.isHidden = false
        trailingSpaceConstraint.constant = 0
        leadingSpaceConstraint.constant = 30.0
        backView.backgroundColor = .white
        setupSelections()
    }

    @IBAction override func editButtonTapped(_: Any) {
        let input = UIAlertController(title: param?.attributeKey, message: "Enter new value", preferredStyle: .alert)
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
                            param?.value = intValue
                            controlValueLabel.text = value
                        } else {
                            showAlert(message: "Value out of bound.")
                        }
                    } else {
                        param?.value = intValue
                        controlValueLabel.text = value
                    }
                } else {
                    showAlert(message: "Please enter a valid integer value.")
                }
            } else if dataType.lowercased() == "float" {
                if let floatValue = Float(value) {
                    if let bounds = param?.bounds, let max = bounds["max"] as? Float, let min = bounds["min"] as? Float {
                        if floatValue >= min, floatValue <= max {
                            param?.value = floatValue
                            controlValueLabel.text = value
                        } else {
                            showAlert(message: "Value out of bound.")
                        }
                    } else {
                        param?.value = floatValue
                        controlValueLabel.text = value
                    }
                } else {
                    showAlert(message: "Please enter a valid float value.")
                }
            } else if dataType.lowercased() == "bool" {
                if boolTypeValidValues.keys.contains(value) {
                    let validValue = boolTypeValidValues[value]!
                    if validValue == 0 {
                        param?.value = false
                        controlValueLabel.text = value
                    } else {
                        param?.value = true
                        controlValueLabel.text = value
                    }
                } else {
                    showAlert(message: "Please enter a valid boolean value.")
                }
            } else {
                param?.value = controlValue
                controlValueLabel.text = value
            }
        }
    }

    @IBAction override func checkBoxPressed(_: Any) {
        if param!.selected {
            editButton.isHidden = true
            checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
            param!.selected = false
            device.selectedParams -= 1
        } else {
            editButton.isHidden = false
            checkButton.setImage(UIImage(named: "selected"), for: .normal)
            param!.selected = true
            device.selectedParams += 1
        }
        scheduleDelegate?.paramStateChangedat(indexPath: indexPath)
    }
}

extension ScheduleGenericTableViewCell: ScheduleSceneActionAllowedProtocol {
    func setupSelections() {
        let isAllowed = isCellEnabled(cellType: cellType, device: device)
        if isAllowed {
            self.alpha = 1.0
            checkButton.isEnabled = true
            editButton.isHidden = param?.selected ?? false
        } else {
            self.alpha = 0.6
            checkButton.isEnabled = false
            editButton.isHidden = true
            scheduleDelegate?.takeScheduleNotAllowedAction(action: device.scheduleAction)
        }
    }
}
