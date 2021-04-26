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
//  ScheduleDropDownTableViewCell.swift
//  ESPRainMaker
//

import DropDown
import UIKit

class ScheduleDropDownTableViewCell: DropDownTableViewCell {
    
    var cellType: DeviceServiceType = .none
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Cutomised appearance of control element for schedule action
        checkButton.isHidden = false
        trailingSpaceConstraint.constant = 0
        leadingSpaceConstraint.constant = 30.0
        backView.backgroundColor = .white
        setupSelections()
    }

    @IBAction override func checkBoxPressed(_: Any) {
        if param.selected {
            dropDownButton.isEnabled = false
            checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
            param.selected = false
            device.selectedParams -= 1
        } else {
            dropDownButton.isEnabled = true
            checkButton.setImage(UIImage(named: "selected"), for: .normal)
            param.selected = true
            device.selectedParams += 1
        }
        scheduleDelegate?.paramStateChangedat(indexPath: indexPath)
    }

    @IBAction override func dropDownButtonTapped(_: Any) {
        // Configuring dropdown attributes
        DropDown.appearance().backgroundColor = UIColor.white
        DropDown.appearance().selectionBackgroundColor = #colorLiteral(red: 0.04705882353, green: 0.4392156863, blue: 0.9098039216, alpha: 1)
        let dropDown = DropDown()
        dropDown.dataSource = datasource
        dropDown.width = UIScreen.main.bounds.size.width - 100
        dropDown.anchorView = backView
        dropDown.show()
        // Selecting param value in dropdown list
        if let index = datasource.firstIndex(where: { $0 == currentValue }) {
            dropDown.selectRow(at: index)
        }
        // Assigning action for dropdown item selection
        dropDown.selectionAction = { [unowned self] (_: Int, item: String) in
            if self.param.dataType?.lowercased() == "string" {
                param.value = item
            } else {
                param.value = Int(item)
            }
            currentValue = item
            DispatchQueue.main.async {
                controlValueLabel.text = item
            }
        }
    }
}

extension ScheduleDropDownTableViewCell: ScheduleSceneActionAllowedProtocol {
    func setupSelections() {
        let isAllowed = isCellEnabled(cellType: cellType, device: device)
        if isAllowed {
            self.alpha = 1.0
            checkButton.isEnabled = true
            dropDownButton.isEnabled = param?.selected ?? false
            dropDownButton.isHidden = false
        } else {
            self.alpha = 0.6
            checkButton.isEnabled = false
            dropDownButton.isEnabled = false
            dropDownButton.isHidden = true
            scheduleDelegate?.takeScheduleNotAllowedAction(action: device.scheduleAction)
        }
    }
}
