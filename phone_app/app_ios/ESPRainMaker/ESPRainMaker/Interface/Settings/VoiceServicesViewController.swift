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
//  VoiceServicesViewController.swift
//  ESPRainMaker
//

import UIKit

class VoiceServicesViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = true
    }
    
    func showDocumentVC(url: String) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let documentVC = storyboard.instantiateViewController(withIdentifier: "documentVC") as! DocumentViewController
        modalPresentationStyle = .popover
        documentVC.documentLink = url
        present(documentVC, animated: true, completion: nil)
    }

    @IBAction func openAlexaVoiceAssistant(_: Any) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            if ESPEnableAlexaSkillService.isAlexaConfigValid() {
                if let connectToAlexaVC = ESPEnableAlexaSkillService.getConnectToAlexaVC() {
                    self.navigationController?.pushViewController(connectToAlexaVC, animated: true)
                }
            } else {
                showDocumentVC(url: "https://rainmaker.espressif.com/docs/3rd-party.html#enabling-alexa")
            }
        }
    }

    @IBAction func openGoogleAssitant(_: Any) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            showDocumentVC(url: "https://rainmaker.espressif.com/docs/3rd-party.html#enabling-google-voice-assistant-gva")
        }
    }

    @IBAction func backClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}

