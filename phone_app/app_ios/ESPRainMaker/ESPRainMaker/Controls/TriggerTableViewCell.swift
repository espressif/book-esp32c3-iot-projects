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
//  TriggerTableViewCell.swift
//  ESPRainMaker
//

import UIKit

// Class to show "esp.ui.trigger" UI type
class TriggerTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "triggerTVC"

    // IB Outlets
    @IBOutlet var leadingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var trailingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var backView: UIView!
    @IBOutlet var controlName: UILabel!
    @IBOutlet var triggerButton: UIButton!
    @IBOutlet var checkButton: UIButton!

    // Stored properties
    var paramName: String = ""
    var param: Param!
    var device: Device!
    var paramDelegate: ParamUpdateProtocol?
    var scheduleDelegate: ScheduleActionDelegate?
    var indexPath: IndexPath!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // IB Actions
    @IBAction func triggerPressed(_: Any) {
        // Animate button to show trigger effect
        triggerButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        UIView.animate(withDuration: 0.5,
          delay: 0,
                       usingSpringWithDamping: CGFloat(0.39),
                       initialSpringVelocity: CGFloat(0),
          options: .allowUserInteraction,
          animations: {
            self.triggerButton.transform = .identity
          }, completion: {_ in }
        )
    }
    
    @IBAction func checkBoxPressed(_: Any) {}
}
