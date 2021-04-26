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
//  ProvisionLandingViewController.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation
import MBProgressHUD
import SystemConfiguration.CaptiveNetwork
import UIKit

class ProvisionLandingViewController: UIViewController {
    var deviceList: [Node]?
    var deviceStatusTimer: Timer?
    var task: URLSessionDataTask?
    var connectedToDevice = false
    var capabilities: [String]?

    @IBOutlet var connectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        checkConnectivity()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func checkConnectivity() {
        connectButton.alpha = 0.5
        connectButton.isEnabled = false
        Utility.showLoader(message: "", view: view)
        getDeviceVersionInfo()
        deviceStatusTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(timeoutFetchingStatus), userInfo: nil, repeats: false)
    }

    @objc func appEnterForeground() {
        checkConnectivity()
    }

    @objc func appEnterBackground() {
        task?.cancel()
    }

    @objc func timeoutFetchingStatus() {
        Utility.hideLoader(view: view)
        deviceStatusTimer?.invalidate()
        connectButton.alpha = 1.0
        connectButton.isEnabled = true
    }

    func getDeviceVersionInfo() {
        SendHTTPData(path: "proto-ver", data: Data("ESP".utf8), completionHandler: { response, error in
            DispatchQueue.main.async {
                if error == nil {
                    do {
                        if let result = try JSONSerialization.jsonObject(with: response!, options: .mutableContainers) as? NSDictionary {
                            if let prov = result[Constants.provKey] as? NSDictionary, let capabilities = prov[Constants.capabilitiesKey] as? [String] {
                                self.capabilities = capabilities
                                if let capability = self.capabilities, capability.contains(Constants.noProofCapability) {
                                    if self.deviceStatusTimer!.isValid {
                                        self.deviceStatusTimer?.invalidate()
                                        self.getESPDevice()
                                        return
                                    }
                                }
                            }
                        }
                    } catch {
                        print(error)
                    }
                    if self.deviceStatusTimer!.isValid {
                        self.deviceStatusTimer?.invalidate()
                        self.goToConnectVC(ssid: self.verifyConnection() ?? "")
                    }
                } else {
                    Utility.hideLoader(view: self.view)
                    self.timeoutFetchingStatus()
                }
            }
        })
    }

    @IBAction func connectClicked(_: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                _ = UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        }
    }

    func verifyConnection() -> String? {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    if let currentSSID = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String {
                        return currentSSID
                    }
                }
            }
        }
        return nil
    }

    @IBAction func cancelClicked(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func backClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    func getESPDevice() {
        ESPProvisionManager.shared.createESPDevice(deviceName: verifyConnection() ?? "", transport: .softap, security: Configuration.shared.espProvSetting.securityMode, completionHandler: { device, _ in
            if device != nil {
                self.connectDevice(espDevice: device!)

            } else {
                DispatchQueue.main.async {
                    self.retry(message: "Device could not be connected. Please try again")
                }
            }
        })
    }

    func retry(message: String) {
        Utility.hideLoader(view: view)
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func connectDevice(espDevice: ESPDevice) {
        espDevice.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            switch status {
            case .connected:
                DispatchQueue.main.async {
                    self.checkForAssistedClaiming(device: espDevice)
                }
            default:
                DispatchQueue.main.async {
                    self.retry(message: "Device could not be connected. Please try again")
                }
            }
        }
    }

    func showAlert(error: ESPDeviceCSSError, action: UIAlertAction) {
        let alertController = UIAlertController(title: "Error!", message: error.description, preferredStyle: .alert)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    func goToConnectVC(ssid: String) {
        let connectVC = storyboard?.instantiateViewController(withIdentifier: Constants.connectVCIdentifier) as! ConnectViewController
        connectVC.currentDeviceName = ssid
        navigationController?.pushViewController(connectVC, animated: true)
    }

    func checkForAssistedClaiming(device: ESPDevice) {
        if let versionInfo = device.versionInfo, let rmaikerInfo = versionInfo["rmaker"] as? NSDictionary, let rmaikerCap = rmaikerInfo["cap"] as? [String], rmaikerCap.contains("claim") {
            retry(message: "Assisted Claiming not supported for SoftAP. Cannot Proceed.")
        } else {
            goToProvision(device: device)
        }
    }

    func goToProvision(device: ESPDevice) {
        let provVC = storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
        provVC.device = device
        navigationController?.pushViewController(provVC, animated: true)
    }

    func attributedString(from string: String, nonBoldRange: NSRange?) -> NSAttributedString {
        let attrs = [
            kCTFontAttributeName: UIFont.boldSystemFont(ofSize: 20),
            kCTForegroundColorAttributeName: UIColor.black,
        ]
        let nonBoldAttribute = [
            kCTFontAttributeName: UIFont.systemFont(ofSize: 20),
        ]
        let attrStr = NSMutableAttributedString(string: string, attributes: attrs as [NSAttributedString.Key: Any])
        if let range = nonBoldRange {
            attrStr.setAttributes(nonBoldAttribute as [NSAttributedString.Key: Any], range: range)
        }
        return attrStr
    }

    private func SendHTTPData(path: String, data: Data, completionHandler: @escaping (Data?, Error?) -> Swift.Void) {
        let url = URL(string: "http://\(Utility.baseUrl)/\(path)")!
        var request = URLRequest(url: url)

        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        request.setValue("text/plain", forHTTPHeaderField: "Accept")

        request.httpMethod = "POST"
        request.httpBody = data
        request.timeoutInterval = 2.0
        task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }

            let httpStatus = response as? HTTPURLResponse
            if httpStatus?.statusCode != 200 {
                print("statusCode should be 200, but is \(String(describing: httpStatus?.statusCode))")
            }

            completionHandler(data, nil)
        }
        task?.resume()
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}

extension ProvisionLandingViewController: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice _: ESPDevice, completionHandler: @escaping (String) -> Void) {
        completionHandler("")
    }
}
