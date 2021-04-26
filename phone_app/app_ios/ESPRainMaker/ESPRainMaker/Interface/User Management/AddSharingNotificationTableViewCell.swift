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
//  AddSharingNotificationTableViewCell.swift
//  ESPRainMaker
//

import UIKit

class AddSharingNotificationTableViewCell: UITableViewCell {
    var acceptButtonAction: () -> Void = {}
    var denyButtonAction: () -> Void = {}

    @IBOutlet var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        // UI Customisation
        contentView.layer.borderWidth = 1
        contentView.layer.cornerRadius = 10
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.layer.masksToBounds = true
    }

    @IBAction func acceptButtonTapped(_: Any) {
        acceptButtonAction()
    }

    @IBAction func denyButtonTapped(_: Any) {
        denyButtonAction()
    }
}
