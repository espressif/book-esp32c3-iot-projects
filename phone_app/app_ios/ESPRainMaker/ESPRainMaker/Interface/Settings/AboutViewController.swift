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
//  AboutViewController.swift
//  ESPRainMaker
//

import Foundation
import UIKit

class AboutViewController: UIViewController {
    
    @IBOutlet var appVersionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appVersionLabel.text = "v" + Constants.appVersion + " (\(GIT_SHA_VERSION))"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = true
    }
    
    // MARK: IB Actions
    
    @IBAction func openPrivacy(_: Any) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            showDocumentVC(url: Configuration.shared.externalLinks.privacyPolicyURL)
        }
    }

    @IBAction func openTermsOfUse(_: Any) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            showDocumentVC(url: Configuration.shared.externalLinks.termsOfUseURL)
        }
    }

    @IBAction func openDocumentation(_: Any) {
        showDocumentVC(url: Configuration.shared.externalLinks.documentationURL)
    }
    
    @IBAction func backClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: Helper Methods
    
    private func showDocumentVC(url: String) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let documentVC = storyboard.instantiateViewController(withIdentifier: "documentVC") as! DocumentViewController
        modalPresentationStyle = .popover
        documentVC.documentLink = url
        present(documentVC, animated: true, completion: nil)
    }
}
