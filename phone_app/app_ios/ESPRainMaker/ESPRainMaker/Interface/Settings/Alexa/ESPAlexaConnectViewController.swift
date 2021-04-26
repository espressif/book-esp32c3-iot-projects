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
//  ESPAlexaConnectViewController.swift
//  ESPRainMaker
//

import UIKit

protocol ESPEnableAlexaSkillPresenter {
    func actOnURL(url: String, state: ESPEnableSkillState)
    func accountLinked(status: Bool)
    func showErrorAlert(title: String, message: String)
    func showLoader(message: String)
    func hideLoader()
    func showToast(message: String)
    func showDisableSkillAlert()
}

/// This viewcontroller is to show screen to allow user to connect to Alexa
class ESPAlexaConnectViewController: UIViewController {
    
    static let storyboardId = "ESPAlexaConnectViewController"
    var isAccountConnected: Bool = false
    var service: ESPEnableAlexaSkillService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.service = ESPEnableAlexaSkillService(presenter: self)
        self.connectToAlexaView.isHidden = true
        self.showLoader(message: "")
        ESPAlexaTokenWorker.shared.clearAccessToken()
        service.isAccountLinked() { status in
            self.hideLoader()
            self.accountLinked(status: status)
        }
    }
    
    // MARK: Views for connect to alexa flow
    @IBOutlet weak var connectToAlexaView: UIView!
    @IBOutlet weak var linkWithAlexaButton: UIButton!
    @IBAction func linkWithAlexa(_ sender: Any) {
        self.service.initiateEnableSkillFlow()
    }
    
    // MARK: Back button
    @IBAction func backClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: Views for connected to alexa flow
    @IBOutlet weak var connectedToAlexaView: UIView!
    @IBOutlet weak var unlinkWithAlexaButton: UIButton!
    @IBOutlet weak var alexaControlsLabel: UILabel!
    @IBAction func unlinkWithAlexa(_ sender: Any) {
        self.showDisableSkillAlert()
    }
}

extension ESPAlexaConnectViewController: ESPEnableAlexaSkillPresenter {
    
    
    /// Check linked status for alexa skill and if not linked call method to act on URL retrieved from WKWebview or Alexa app
    /// - Parameters:
    ///   - url: URL retrieved from WKWebview or Alexa app
    ///   - state: state for which url is retrieved
    func checkAccountLinkingAndActOnURL(url: String, state: ESPEnableSkillState) {
        if state == .rainMakerAuthCode {
            self.actOnURL(url: url, state: state)
        } else {
            service.isAccountLinked() { status in
                self.accountLinked(status: status)
                if !status {
                    self.actOnURL(url: url, state: state)
                }
            }
        }
    }
    
    /// Callback that informs if account is linked
    /// - Parameter status: is account linked
    func accountLinked(status: Bool) {
        DispatchQueue.main.async {
            self.connectToAlexaView.isHidden = status
            self.connectedToAlexaView.isHidden = !status
            if status {
                self.alexaControlsLabel.text =
                    Configuration.shared.espAlexaConfiguration.alexaActionsString
            }
        }
    }
    
    /// Act on URL that is retried from WKWebview
    /// - Parameters:
    ///   - url: URL retrieved from WKWebview or Alexa app
    ///   - state: state for which url is retrieved
    func actOnURL(url: String, state: ESPEnableSkillState) {
        if ESPAlexaAPIParser.shared.parseURL(url, state: state) {
            if state != .rainMakerAuthCode {
                if let error = ESPAlexaAPIParser.shared.getAlexaErrorDescription(), error.count > 0 {
                    self.showErrorAlert(title: "Error", message: error)
                } else if let code = ESPAlexaAPIParser.shared.getAlexaAuthCode() {
                    service.getAlexaAccessToken(code: code)
                }
            } else {
                if let code = ESPAlexaAPIParser.shared.getRainmakerAuthCode() {
                    service.enableSkill(code: code)
                }
            }
        } else {
            
        }
    }
    
    /// Show error alert view
    /// - Parameters:
    ///   - title: title for alert
    ///   - message: message for alert
    func showErrorAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: {_ in
                alertController.dismiss(animated: true, completion: nil)
            })
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    /// Show loading indicator
    /// - Parameter message: message for loading indicator
    func showLoader(message: String) {
        Utility.showLoader(message: message, view: self.view)
    }
    
    /// Hide loading indicator
    func hideLoader() {
        Utility.hideLoader(view: self.view)
    }
    
    /// Show toast message
    /// - Parameter message: message for toast
    func showToast(message: String) {
        Utility.showToastMessage(view: self.view, message: message, duration: 2.0)
    }
    
    /// Show alert to ask user disable skill
    func showDisableSkillAlert() {
        let alert = UIAlertController(title: "Disable skill", message: "Do you want to unlink your account?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.service.disableSkill()
        }
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        alert.addAction(yesAction)
        alert.addAction(noAction)
        self.present(alert, animated: true, completion: nil)
    }
}
