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
//  DeviceListCollectionReusableView.swift
//  ESPRainMaker
//

import UIKit

protocol DeviceListHeaderProtocol {
    func deviceInfoClicked(nodeID: String)
}

class DeviceListCollectionReusableView: UICollectionReusableView {
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var statusIndicator: UIView!
    var nodeID = ""
    var delegate: DeviceListHeaderProtocol?

    @IBAction func infoClicked(_: Any) {
        delegate?.deviceInfoClicked(nodeID: nodeID)
    }
}
