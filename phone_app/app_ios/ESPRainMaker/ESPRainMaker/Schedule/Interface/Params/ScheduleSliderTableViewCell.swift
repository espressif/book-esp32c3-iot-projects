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
//  ScheduleSliderTableViewCell.swift
//  ESPRainMaker
//
import UIKit

class ScheduleSliderTableViewCell: SliderTableViewCell {
    
    var cellType: DeviceServiceType = .none
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        checkButton.isHidden = false
        trailingSpaceConstraint.constant = 0
        leadingSpaceConstraint.constant = 30.0
        backView.backgroundColor = .white
        setupSelections()
    }

    @IBAction override func checkBoxPressed(_: Any) {
        if param.selected {
            hueSlider.alpha = 0.5
            hueSlider.isEnabled = false
            slider.isEnabled = false
            param.selected = false
            checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
            device.selectedParams -= 1
        } else {
            hueSlider.alpha = 1.0
            hueSlider.isEnabled = true
            slider.isEnabled = true
            param.selected = true
            checkButton.setImage(UIImage(named: "selected"), for: .normal)
            device.selectedParams += 1
        }
        scheduleDelegate?.paramStateChangedat(indexPath: indexPath)
    }

    @IBAction override func sliderValueChanged(_ slider: UISlider) {
        if param.dataType?.lowercased() ?? "" == "int" {
            param.value = Int(slider.value)
        } else {
            param.value = slider.value
        }
    }

    @IBAction override func hueSliderValueDragged(_ sender: GradientSlider) {
        hueSlider.thumbColor = UIColor(hue: CGFloat(sender.value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }

    @IBAction override func hueSliderValueChanged(_ sender: GradientSlider) {
        if currentHueValue != sender.value {
            hueSlider.thumbColor = UIColor(hue: CGFloat(sender.value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
            if param.dataType?.lowercased() ?? "" == "int" {
                param.value = Int(sender.value)
            } else {
                param.value = sender.value
            }
            currentHueValue = sender.value
        }
    }
}

extension ScheduleSliderTableViewCell: ScheduleSceneActionAllowedProtocol {
    func setupSelections() {
        let isAllowed = isCellEnabled(cellType: cellType, device: device)
        if isAllowed {
            self.alpha = 1.0
            checkButton.isEnabled = true
            hueSlider.isEnabled = param?.selected ?? false
            slider.isEnabled = param?.selected ?? false
        } else {
            self.alpha = 0.6
            checkButton.isEnabled = false
            hueSlider.isEnabled = false
            slider.isEnabled = false
            scheduleDelegate?.takeScheduleNotAllowedAction(action: device.scheduleAction)
        }
    }
}
