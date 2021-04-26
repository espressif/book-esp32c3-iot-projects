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
//  ScannerViewController.swift
//  ESPRainMaker
//
//  Created by Vikas Chandra on 26/11/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import AVFoundation
import CoreLocation
import ESPProvision
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import UIKit

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    let locationManager = CLLocationManager()
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet var scannerView: UIView!
    @IBOutlet var noCameraView: UIView!
    @IBOutlet var manualActionButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Check for device type to ask for location permission
        // Location permission is needed to get SSID of connected Wi-Fi network.
        switch Configuration.shared.espProvSetting.transport {
        case .both, .softAp:
            getLocationPermission()
        default:
            break
        }
        scanQrCode()

        Utility.setActiveSSID()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = scannerView.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func scanQrCode() {
        ESPProvisionManager.shared.scanQRCode(scanView: scannerView) { espDevice, scanError in
            if let device = espDevice {
                if self.isDeviceSupported(device: device) {
                    DispatchQueue.main.async {
                        Utility.showLoader(message: "Connecting to device", view: self.view)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.connectDevice(espDevice: device)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.retry(message: "Device type not supported. Please choose another device and try again.")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if let error = scanError {
                        switch error {
                        case .cameraAccessDenied:
                            self.noCameraView.isHidden = false
                        case .espDeviceNotFound, .softApSearchNotSupported, .invalidQRCode:
                            self.retry(message: error.description)
                        case .videoInputError, .videoOutputError, .cameraNotAvailable, .avCaptureDeviceInputError:
                            self.showAlertWith(message: "Unable to scan QR code. Something went wrong while processing camera input.")
                        }
                    }
                }
            }
        }
    }

    func connectDevice(espDevice: ESPDevice) {
        espDevice.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                switch status {
                case .connected:
                    self.checkForAssistedClaiming(device: espDevice)
                default:
                    self.retry(message: "Device could not be connected. Please try again")
                }
            }
        }
    }

    @IBAction func goToSettings(_: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { _ in
            })
        }
    }

    func checkForAssistedClaiming(device: ESPDevice) {
        if let versionInfo = device.versionInfo, let rmaikerInfo = versionInfo["rmaker"] as? NSDictionary, let rmaikerCap = rmaikerInfo["cap"] as? [String], rmaikerCap.contains("claim") {
            if device.transport == .ble {
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    self.goToClaimVC(device: device)
                }
            } else {
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    self.retry(message: "Assisted Claiming not supported for SoftAP. Cannot Proceed.")
                }
            }
        } else {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.goToProvision(device: device)
            }
        }
    }

    @IBAction func cancelClickecd(_: Any) {
        navigationController?.popToRootViewController(animated: false)
    }

    @IBAction func selectManualProvisioning(_: Any) {
        switch Configuration.shared.espProvSetting.transport {
        case .ble:
            goToBleProvision()
        case .softAp:
            goToSoftAPProvision()
        default:
            let actionSheet = UIAlertController(title: "", message: "Choose Provisioning Transport", preferredStyle: .actionSheet)
            let bleAction = UIAlertAction(title: "BLE", style: .default) { _ in
                self.goToBleProvision()
            }
            let softapAction = UIAlertAction(title: "SoftAP", style: .default) { _ in
                self.goToSoftAPProvision()
            }
            actionSheet.addAction(bleAction)
            actionSheet.addAction(softapAction)
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            actionSheet.popoverPresentationController?.sourceView = manualActionButton
            present(actionSheet, animated: true, completion: nil)
        }
    }

    func retry(message: String) {
        Utility.hideLoader(view: view)
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            DispatchQueue.main.async {
                self.scanQrCode()
            }
        }))
        present(alertController, animated: true, completion: nil)
    }

    func goToClaimVC(device: ESPDevice) {
        let claimVC = storyboard?.instantiateViewController(withIdentifier: Constants.claimVCIdentifier) as! ClaimViewController
        claimVC.device = device
        navigationController?.pushViewController(claimVC, animated: true)
    }

    func goToProvision(device: ESPDevice) {
        let provisionVC = storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
        provisionVC.device = device
        navigationController?.pushViewController(provisionVC, animated: true)
    }

    func goToBleProvision() {
        let bleLandingVC = storyboard?.instantiateViewController(withIdentifier: "bleLandingVC") as! BLELandingViewController
        navigationController?.pushViewController(bleLandingVC, animated: true)
    }

    func goToSoftAPProvision() {
        let bleLandingVC = storyboard?.instantiateViewController(withIdentifier: "provisionLanding") as! ProvisionLandingViewController
        navigationController?.pushViewController(bleLandingVC, animated: true)
    }

    // Helper method to check whether app supports the scanned device.
    private func isDeviceSupported(device: ESPDevice) -> Bool {
        switch Configuration.shared.espProvSetting.transport {
        case .both:
            return true
        case .softAp:
            if device.transport == .softap {
                return true
            }
        case .ble:
            if device.transport == .ble {
                return true
            }
        }
        return false
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
    func showAlertWith(message: String = "") {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func getLocationPermission() {
        let locStatus = CLLocationManager.authorizationStatus()
        switch locStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return
        case .denied, .restricted:
            let alert = UIAlertController(title: "Location Services are disabled", message: "Please enable Location Services in your Settings", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            break
        }
    }
}

extension ScannerViewController: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        completionHandler("")
    }
}
