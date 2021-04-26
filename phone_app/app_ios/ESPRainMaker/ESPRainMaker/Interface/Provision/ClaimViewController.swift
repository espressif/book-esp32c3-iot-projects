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
//  DocumentViewController.swift
//  ESPRainMaker
//
//  ClaimViewController.swift
//  ESPRainMaker
//

import ESPProvision
import UIKit

class ClaimViewController: UIViewController {
    @IBOutlet var progressIndicator: UILabel!
    @IBOutlet var failureLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var okButton: PrimaryButton!
    @IBOutlet var cancelButton: BarButton!
    @IBOutlet var centralIcon: UIImageView!

    var device: ESPDevice!
    var count = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            self.cancelButton.isHidden = false
        }
        progressIndicator.text = "Claiming in progress..."
        startAssistedClaiming()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centralIcon.rotate360Degrees()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        centralIcon.layer.removeAllAnimations()
    }

    func startAssistedClaiming() {
        let assistedClaiming = AssistedClaiming(espDevice: device)
        assistedClaiming.initiateAssistedClaiming { result, error in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                if result {
                    self.goToProvision()
                } else {
                    self.centralIcon.layer.removeAllAnimations()
                    self.progressIndicator.text = "Claiming failed with error:"
                    self.failureLabel.text = error ?? "Failure"
                    self.failureLabel.isHidden = false
                    var status = "Claiming failed. Please reboot the device and restart provisioning."
                    if error == "BLE characteristic related with claiming cannot be found." {
                        status = "Please restart your iOS device to reset BLE cache and try again."
                    }
                    self.statusLabel.text = status
                    self.statusLabel.isHidden = false
                    self.okButton.isHidden = false
                }
            }
        }
    }

    func goToProvision() {
        let provisionVC = storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
        provisionVC.device = device
        navigationController?.pushViewController(provisionVC, animated: true)
    }

    @IBAction func doneButtonPressed(_: Any) {
        device.disconnect()
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func cancelPressed(_: Any) {
        device.disconnect()
        navigationController?.popToRootViewController(animated: true)
    }
}
