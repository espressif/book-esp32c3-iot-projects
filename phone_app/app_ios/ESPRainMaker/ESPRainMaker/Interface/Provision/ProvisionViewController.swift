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
//  ProvisionViewController.swift
//  ESPRainMaker
//

import CoreBluetooth
import ESPProvision
import Foundation
import MBProgressHUD
import SystemConfiguration.CaptiveNetwork
import UIKit

class ProvisionViewController: UIViewController {
    @IBOutlet var passphraseTextfield: UITextField!
    @IBOutlet var currentSSIDLabel: UILabel!
    @IBOutlet var provisionButton: UIButton!
    @IBOutlet var savePasswordButton: UIButton!
    @IBOutlet var passwordButton: UIButton!
    @IBOutlet var bottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var wifiListView: UIView!
    @IBOutlet var passphraseView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var signalImageView: UIImageView!
    @IBOutlet var authenticationImageView: UIImageView!

    var savedPasswords = UserDefaults.standard.value(forKey: Constants.wifiPassword) as? [String: String] ?? [:]
    var activityView: UIActivityIndicatorView?
    var wifiDetailList: [ESPWifiNetwork] = []
    var shouldSavePassword = true
    var device: ESPDevice!
    var passphrase = ""
    var currentSSID = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        let ssidTapGesture = UITapGestureRecognizer(target: self, action: #selector(showWiFiList))
        wifiListView.addGestureRecognizer(ssidTapGesture)
        // Add gesture recognizer to hide keyboard(if open) on tapping anywhere on screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false

        getCurrentSSID()

        // Added observers for Keyboard hide/unhide event.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        scanDeviceForWiFiList()
        tableView.tableFooterView = UIView()
    }

    @objc private func showWiFiList() {
        if tableView.isHidden {
            tableView.reloadData()
        }
        tableView.isHidden = !tableView.isHidden
    }

    @objc private func hideKeyBoard() {
        passphraseTextfield.resignFirstResponder()
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

    private func networkSelected(wifiNetwork: ESPWifiNetwork) {
        currentSSIDLabel.text = wifiNetwork.ssid
        currentSSID = wifiNetwork.ssid
        provisionButton.isHidden = false
        if wifiNetwork.auth == .open {
            passphraseView.isHidden = true
            savePasswordButton.isHidden = true
        } else {
            passphraseView.isHidden = false
            savePasswordButton.isHidden = false
        }
        if let password = savedPasswords[currentSSID] {
            passphraseTextfield.text = password
        } else {
            passphraseTextfield.text = ""
        }
        setWifiIconImageFor(wifiSignalImageView: signalImageView, wifiSecurityImageView: authenticationImageView, network: wifiNetwork)
    }

    // Get ssid of currently connected Wi-Fi.
    private func getCurrentSSID() {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    if let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String {
                        currentSSID = ssid
                    }
                }
            }
        }
    }

    private func showBusy(isBusy: Bool) {
        if isBusy {
            activityView = UIActivityIndicatorView(style: .gray)
            activityView?.center = view.center
            activityView?.startAnimating()

            view.addSubview(activityView!)
        } else {
            activityView?.removeFromSuperview()
        }

        provisionButton.isUserInteractionEnabled = !isBusy
    }

    private func provisionDevice(ssid _: String, passphrase: String) {
        Utility.showLoader(message: "Sending association data", view: view)
        self.passphrase = passphrase
        User.shared.associateNodeWithUser(device: device, delegate: self)
    }

    @IBAction func savePasswordClicked(_: Any) {
        if shouldSavePassword {
            shouldSavePassword = false
            savePasswordButton.setImage(UIImage(named: "unselected"), for: .normal)
        } else {
            shouldSavePassword = true
            savePasswordButton.setImage(UIImage(named: "selected"), for: .normal)
        }
    }

    @IBAction func rescanWiFiList(_: Any) {
        scanDeviceForWiFiList()
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
        if shouldSavePassword {
            savedPasswords[currentSSID] = passphrase
        } else {
            savedPasswords.removeValue(forKey: currentSSID)
        }
        UserDefaults.standard.setValue(savedPasswords, forKey: Constants.wifiPassword)
        provisionDevice(ssid: currentSSID, passphrase: passphrase)
    }

    // Scanned ESP device to get list of available Wi-Fi
    func scanDeviceForWiFiList() {
        Utility.showLoader(message: "Scanning for Wi-Fi", view: view)
        device.scanWifiList { wifiList, _ in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                if let list = wifiList {
                    self.wifiDetailList = list.sorted { $0.rssi > $1.rssi }
                    // Checked if currently connected SSID is available on Wi-Fi list.
                    if let currentNetwork = list.first(where: { $0.ssid == self.currentSSID }) {
                        self.networkSelected(wifiNetwork: currentNetwork)
                    } else if let activeNetwork = list.first(where: { $0.ssid == Utility.activeSSID }) {
                        self.networkSelected(wifiNetwork: activeNetwork)
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }

    func setWifiIconImageFor(wifiSignalImageView: UIImageView, wifiSecurityImageView: UIImageView, network: ESPWifiNetwork) {
        let rssi = network.rssi
        wifiSignalImageView.isHidden = false
        if rssi > Int32(-50) {
            wifiSignalImageView.image = UIImage(named: "wifi_symbol_strong")
        } else if rssi > Int32(-60) {
            wifiSignalImageView.image = UIImage(named: "wifi_symbol_good")
        } else if rssi > Int32(-67) {
            wifiSignalImageView.image = UIImage(named: "wifi_symbol_fair")
        } else {
            wifiSignalImageView.image = UIImage(named: "wifi_symbol_weak")
        }
        if network.auth != .open {
            wifiSecurityImageView.isHidden = false
        } else {
            wifiSecurityImageView.isHidden = true
        }
    }

    func showStatusScreen(step1Failed: Bool = false) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let successVC = self.storyboard?.instantiateViewController(withIdentifier: "successViewController") as! SuccessViewController
            successVC.ssid = self.currentSSID
            successVC.passphrase = self.passphrase
            successVC.step1Failed = step1Failed
            successVC.espDevice = self.device
            self.navigationController?.pushViewController(successVC, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "joinNetwork" {
            let destinationVC = segue.destination as! JoinNetworkViewController
            destinationVC.device = device
        }
    }
}

extension ProvisionViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            passphraseView.isHidden = true
            savePasswordButton.isHidden = true
            tableView.isHidden = true
            currentSSIDLabel.text = "Select Wi-Fi Network"
            passphraseTextfield.text = ""
            provisionButton.isHidden = true
            signalImageView.isHidden = true
            authenticationImageView.isHidden = true
            return
        }
        let selectedNetwork = wifiDetailList[indexPath.row - 1]
        networkSelected(wifiNetwork: selectedNetwork)
        tableView.isHidden = true
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 45.0
    }
}

extension ProvisionViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return wifiDetailList.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wifiListCell", for: indexPath) as! WifiListTableViewCell
        if indexPath.row == 0 {
            cell.ssidLabel.text = "Select Wi-Fi Network"
            cell.signalImageView.isHidden = true
            cell.authenticationImageView.isHidden = true
        } else {
            let wifiNetwork = wifiDetailList[indexPath.row - 1]
            if wifiNetwork.ssid == currentSSIDLabel.text {
                cell.backgroundColor = UIColor(hexString: "#8265E3").withAlphaComponent(0.6)
            } else {
                cell.backgroundColor = .white
            }
            cell.ssidLabel.text = wifiDetailList[indexPath.row - 1].ssid
            setWifiIconImageFor(wifiSignalImageView: cell.signalImageView, wifiSecurityImageView: cell.authenticationImageView, network: wifiNetwork)
        }
        return cell
    }
}

extension ProvisionViewController: DeviceAssociationProtocol {
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
