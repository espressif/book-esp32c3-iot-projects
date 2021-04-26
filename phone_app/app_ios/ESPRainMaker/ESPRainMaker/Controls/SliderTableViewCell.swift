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
//  SliderTableViewCell.swift
//  ESPRainMaker
//

import MBProgressHUD
import UIKit

class SliderTableViewCell: UITableViewCell {
    // IB outlets
    @IBOutlet var slider: UISlider!
    @IBOutlet var minLabel: UILabel!
    @IBOutlet var maxLabel: UILabel!
    @IBOutlet var backView: UIView!
    @IBOutlet var title: UILabel!
    @IBOutlet var hueSlider: GradientSlider!
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var leadingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var trailingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var minImage: UIImageView!
    @IBOutlet var maxImage: UIImageView!

    // Stored properties
    var device: Device!
    var currentHueValue: CGFloat = 0
    var param: Param!
    var scheduleDelegate: ScheduleActionDelegate?
    var indexPath: IndexPath!
    var paramName: String = ""
    var dataType: String!
    var sliderValue = ""
    var paramDelegate: ParamUpdateProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // IB Actions
    @IBAction func sliderValueChanged(_: UISlider) {}

    @IBAction func hueSliderValueDragged(_: GradientSlider) {}

    @IBAction func hueSliderValueChanged(_: GradientSlider) {}

    @IBAction func checkBoxPressed(_: Any) {}
}
