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
//  HueSliderTableViewCell.swift
//  ESPRainMaker
//

import FlexColorPicker
import UIKit

class RoundHueSliderTableViewCell: UITableViewCell {
    @IBOutlet var hueSlider: RadialHueControl!
    @IBOutlet var backView: UIView!
    @IBOutlet var selectedColor: ColorPreviewWithHex!

    var param: Param!
    var device: Device!
    var paramDelegate: ParamUpdateProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        hueSlider.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    @IBAction func valueChanged(_ sender: RadialHueControl) {
        selectedColor.setSelectedHSBColor(sender.selectedHSBColor.withSaturation(1.0), isInteractive: true)
    }
}

extension RoundHueSliderTableViewCell: RadialHueControlDelegate {
    func colorSelected(hue: CGFloat) {
        print(hue)
        DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [param.name ?? "": Int(hue)]], delegate: paramDelegate)
        param.value = Int(hue)
    }
}
