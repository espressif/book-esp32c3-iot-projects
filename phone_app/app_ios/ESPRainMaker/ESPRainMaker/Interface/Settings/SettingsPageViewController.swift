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
//  SettingsPageViewController.swift
//  ESPRainMaker
//

import Foundation
import JWTDecode
import UIKit

class SettingsPageViewController: UIViewController {
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var privacyView: UIView!
    @IBOutlet var notificationCount: UILabel!
    @IBOutlet var notificationView: UIView!
    @IBOutlet var pendingActionView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(updateUIView), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
        navigationController?.navigationBar.isHidden = true

        if !Configuration.shared.appConfiguration.supportSharing {
            pendingActionView.isHidden = true
            pendingActionView.heightAnchor.constraint(equalToConstant: 0.0).isActive = true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    @objc func updateUIView() {
        for subview in view.subviews {
            subview.setNeedsDisplay()
            for item in subview.subviews {
                item.setNeedsDisplay()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBarController?.tabBar.isHidden = false
        emailLabel.text = User.shared.userInfo.email

        if Configuration.shared.appConfiguration.supportSharing {
            var pendingRequestCount = 0
            // Update badge for pending notifications.
            for request in NodeSharingManager.shared.sharingRequestsReceived {
                if request.request_status?.lowercased() == "pending" {
                    pendingRequestCount += 1
                }
            }
            if pendingRequestCount > 0 {
                notificationCount.text = "\(pendingRequestCount)"
                notificationView.isHidden = false
            } else {
                notificationCount.text = ""
                notificationView.isHidden = true
            }
            getSharingRequests()
        }
    }

    @IBAction func signOut(_: Any) {
        let alertController = UIAlertController(title: "Logout", message: "Do you like to proceed?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
            DispatchQueue.main.async {
                Utility.showLoader(message: "Logging Out", view: self.view)
            }
            let service = ESPLogoutService(presenter: self)
            service.logoutUser()            
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func accountButtonPressed(_: Any) {
        let storyboard = UIStoryboard(name: "UserAccount", bundle: nil)
        let userAccountVC = storyboard.instantiateViewController(withIdentifier: "userAccountVC") as! UserAccountViewController
        navigationController?.pushViewController(userAccountVC, animated: true)
    }

    func imageWith(name: String?) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let nameLabel = UILabel(frame: frame)
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = .white
        nameLabel.textColor = .lightGray
        nameLabel.font = UIFont.boldSystemFont(ofSize: 40)
        nameLabel.text = name
        UIGraphicsBeginImageContext(frame.size)
        if let currentContext = UIGraphicsGetCurrentContext() {
            nameLabel.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
    }

    private func getSharingRequests() {
        NodeSharingManager.shared.getSharingRequests(primaryUser: false) { requests, error in
            guard let _ = error else {
                DispatchQueue.main.async {
                    var count = 0
                    if let sharingRequests = requests {
                        for request in sharingRequests {
                            if request.request_status?.lowercased() == "pending" {
                                count += 1
                            }
                        }
                    }
                    if count > 0 {
                        self.notificationCount.text = "\(count)"
                        self.notificationView.isHidden = false
                    } else {
                        self.notificationCount.text = ""
                        self.notificationView.isHidden = true
                    }
                }
                return
            }
        }
    }
}

extension SettingsPageViewController: ESPLogoutUserPresentationLogic, ESPNoRefreshTokenLogic {
    
    func userLoggedOut(withError error: ESPAPIError?) {
        self.clearUserData()
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            self.tabBarController?.selectedIndex = 0
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            if let nav = storyboard.instantiateViewController(withIdentifier: "signInController") as? UINavigationController {
                if let _ = nav.viewControllers.first as? SignInViewController, let tab = self.tabBarController {
                    nav.modalPresentationStyle = .fullScreen
                    tab.present(nav, animated: true, completion: nil)
                }
            }
        }
    }
}
