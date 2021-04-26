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
//  UserAccountViewController.swift
//  ESPRainMaker
//

import Foundation
import UIKit

class UserAccountViewController: UIViewController {
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var changePasswordView: UIView!
    @IBOutlet var changepasswordTopConstraint: NSLayoutConstraint!
    @IBOutlet var changepasswordHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailLabel.text = User.shared.userInfo.email
        userIDLabel.text = User.shared.userInfo.userID
        
        // Shows/hides change password option based on type of login.
        if User.shared.userInfo.loggedInWith == .other {
            changePasswordView.isHidden = true
            changepasswordHeightConstraint.constant = 0
            changepasswordTopConstraint.constant = 0
        } else {
            changePasswordView.isHidden = false
            changepasswordHeightConstraint.constant = 50.0
            changepasswordTopConstraint.constant = 20
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = true
    }
    
    @IBAction func backClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}
