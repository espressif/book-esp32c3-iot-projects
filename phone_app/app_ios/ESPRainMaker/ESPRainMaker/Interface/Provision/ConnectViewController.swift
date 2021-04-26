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
//  ConnectViewController.swift
//  ESPRainMaker
//

import ESPProvision
import UIKit

class ConnectViewController: UIViewController {
    @IBOutlet var popTextField: UITextField!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var nextButton: UIButton!
    var popHandler: ((String) -> Void)?
    var currentDeviceName = ""
    var espDevice: ESPDevice!
    var pop = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        if espDevice == nil {
            ESPProvisionManager.shared.createESPDevice(deviceName: currentDeviceName, transport: .softap, completionHandler: { device, error in
                if device != nil {
                    self.espDevice = device
                    DispatchQueue.main.async {
                        self.nextButton.isHidden = false
                    }

                } else {
                    DispatchQueue.main.async {
                        let action = UIAlertAction(title: "Retry", style: .default) { _ in
                            self.navigationController?.popToRootViewController(animated: false)
                        }
                        self.showAlert(error: error!.description, action: action)
                    }
                }
            })
        } else {
            nextButton.isHidden = false
            currentDeviceName = espDevice.name
        }

        headerLabel.text = "Enter your proof of possession PIN for \n" + currentDeviceName
    }

    @IBAction func cancelClicked(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func nextBtnClicked(_: Any) {
        pop = popTextField.text ?? ""
        Utility.showLoader(message: "Connecting to device", view: view)
        espDevice.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                switch status {
                case .connected:
                    DispatchQueue.main.async {
                        self.checkForAssistedClaiming(device: self.espDevice)
                    }
                case let .failedToConnect(error):
                    switch error {
                    case .sessionInitError:
                        self.showStatusScreen(step1Failed: true, message: error.description + ".Please check if POP is correct.")
                    default:
                        self.showStatusScreen(step1Failed: true, message: error.description)
                    }
                default:
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: "Device disconnected", action: action)
                }
            }
        }
    }

    func checkForAssistedClaiming(device: ESPDevice) {
        if let versionInfo = device.versionInfo, let rmaikerInfo = versionInfo["rmaker"] as? NSDictionary, let rmaikerCap = rmaikerInfo["cap"] as? [String], rmaikerCap.contains("claim") {
            if device.transport == .ble {
                goToClaimVC(device: device)
            } else {
                let action = UIAlertAction(title: "Okay", style: .default, handler: nil)
                showAlert(error: "Assisted Claiming not supported for SoftAP. Cannot Proceed.", action: action)
            }
        } else {
            goToProvision()
        }
    }

    // Show status screen, called when device connection fails.
    func showStatusScreen(step1Failed: Bool = false, message: String) {
        Utility.hideLoader(view: view)
        let successVC = storyboard?.instantiateViewController(withIdentifier: "successViewController") as! SuccessViewController
        successVC.step1Failed = step1Failed
        successVC.espDevice = espDevice
        successVC.failureMessage = message
        navigationController?.pushViewController(successVC, animated: true)
    }

    func goToProvision() {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.device = self.espDevice
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
    }

    func goToClaimVC(device: ESPDevice) {
        let claimVC = storyboard?.instantiateViewController(withIdentifier: "claimVC") as! ClaimViewController
        claimVC.device = device
        navigationController?.pushViewController(claimVC, animated: true)
    }

    func showAlert(error: String, action: UIAlertAction) {
        let alertController = UIAlertController(title: "Error!", message: error, preferredStyle: .alert)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
}

extension ConnectViewController: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        completionHandler(pop)
    }
}
