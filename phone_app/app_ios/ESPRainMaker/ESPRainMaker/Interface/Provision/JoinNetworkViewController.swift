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
//  JoinNetworkViewController.swift
//  ESPRainMaker
//

import ESPProvision
import UIKit

class JoinNetworkViewController: UIViewController {
    @IBOutlet var passphraseTextfield: UITextField!
    @IBOutlet var ssidTextfield: UITextField!
    @IBOutlet var provisionButton: UIButton!
    @IBOutlet var passwordButton: UIButton!
    @IBOutlet var bottomSpaceConstraint: NSLayoutConstraint!

    var device: ESPDevice!
    var passphrase = ""
    var pop = ""

    @IBOutlet var headerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Add gesture recognizer to hide keyboard(if open) on tapping anywhere on screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        view.addGestureRecognizer(tapGestureRecognizer)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func hideKeyBoard() {
        passphraseTextfield.resignFirstResponder()
        ssidTextfield.resignFirstResponder()
        view.endEditing(true)
    }

    @objc func keyboardWillShow(notification _: Notification) {
        UIView.animate(withDuration: 0.1) {
            self.bottomSpaceConstraint.constant = 200.0
        }
    }

    @objc func keyboardWillHide(notification _: Notification) {
        UIView.animate(withDuration: 0.1) {
            self.bottomSpaceConstraint.constant = 0.0
        }
    }

    private func provisionDevice(ssid _: String, passphrase: String) {
        Utility.showLoader(message: "Sending association data", view: view)
        self.passphrase = passphrase
        User.shared.associateNodeWithUser(device: device, delegate: self)
    }

    @IBAction func passwordClicked(_: Any) {
        if passphraseTextfield.isSecureTextEntry {
            passwordButton.setImage(UIImage(named: "unsecure"), for: .normal)
        } else {
            passwordButton.setImage(UIImage(named: "secure"), for: .normal)
        }
        passphraseTextfield.togglePasswordVisibility()
    }

    @IBAction func cancelClicked(_: Any) {
        device.disconnect()
        navigationController?.popToRootViewController(animated: false)
    }

    @IBAction func provisionButtonClicked(_: Any) {
        guard let passphrase = passphraseTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              passphrase.count > 0
        else {
            return
        }
        provisionDevice(ssid: ssidTextfield.text ?? "", passphrase: passphrase)
    }

    func showStatusScreen(step1Failed: Bool = false) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let successVC = self.storyboard?.instantiateViewController(withIdentifier: "successViewController") as! SuccessViewController
            successVC.passphrase = self.passphrase
            successVC.ssid = self.ssidTextfield.text ?? ""
            successVC.step1Failed = step1Failed
            successVC.espDevice = self.device
            self.navigationController?.pushViewController(successVC, animated: true)
        }
    }
}

extension JoinNetworkViewController: DeviceAssociationProtocol {
    func deviceAssociationFinishedWith(success: Bool, nodeID: String?, error: AssociationError?) {
        User.shared.currentAssociationInfo!.associationInfoDelievered = success
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            if success {
                if let deviceSecret = nodeID {
                    User.shared.currentAssociationInfo!.nodeID = deviceSecret
                }
                self.showStatusScreen()
            } else {
                let alertController = UIAlertController(title: "Error", message: error?.description, preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default) { _ in
                    self.navigationController?.popToRootViewController(animated: false)
                }
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
