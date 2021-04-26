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
//  DropDownTableViewCell.swift
//  ESPRainMaker
//

import DropDown
import UIKit

class DropDownTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "dropDownTableViewCell"
    
    // IB outlets
    @IBOutlet var backView: UIView!
    @IBOutlet var controlName: UILabel!
    @IBOutlet var controlValueLabel: UILabel!
    @IBOutlet var dropDownButton: UIButton!
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var leadingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var trailingSpaceConstraint: NSLayoutConstraint!

    // Stored properties
    var datasource: [String] = []
    var param: Param!
    var device: Device!
    var currentValue = ""
    var scheduleDelegate: ScheduleActionDelegate?
    var indexPath: IndexPath!
    var paramDelegate: ParamUpdateProtocol?
    var service: Service?
    var node: Node?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // IB actions
    @IBAction func dropDownButtonTapped(_: Any) {}

    @IBAction func checkBoxPressed(_: Any) {}
}
