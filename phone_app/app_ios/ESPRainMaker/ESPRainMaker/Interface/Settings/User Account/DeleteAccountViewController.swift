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
//  DeleteAccountViewController.swift
//  ESPRainMaker
//

import Foundation


import UIKit

class DeleteAccountViewController: UIViewController {
    
    @IBOutlet var confirmationView: UIView!
    @IBOutlet weak var confirmationCodeTextField: UITextField!
    
    let apiManager = ESPAPIManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func confirmDeletePressed(_ sender: Any) {
        view.endEditing(true)
        Utility.showLoader(message: "Deleting account...", view: self.view)
        if let verificationCode = confirmationCodeTextField.text {
            apiManager.genericAuthorizedJSONRequest(url: Constants.deleteUserAccount + "?verification_code=" + verificationCode, parameter: nil, method: .delete) { response, error in
                Utility.hideLoader(view: self.view)
                if let statusJSON = response as? [String: Any], let status = statusJSON["status"] as? String {
                    let description = statusJSON["description"] as? String
                    if status.lowercased() == "success" {
                        // Account deleted successfully.
                        DispatchQueue.main.async {
                            self.showSuccessAlert()
                        }
                        return
                    }
                    Utility.showToastMessage(view: self.view, message: description ?? "Unable to process request.", duration: 5.0)
                } else if let apiError = error {
                    Utility.showToastMessage(view: self.view, message: apiError.description, duration: 5.0)
                    return
                }
            }
        } else {
            Utility.showToastMessage(view: self.view, message: "Please enter verification code.", duration: 5.0)
        }
    }
    
    @IBAction func deleteAccountPressed(_ sender: Any) {
        // Adds confirmation pop-up before intiating the delete request.
        let alertController = UIAlertController(title: "Warning!", message: "This will permanently delete your account and all information associated with it, including all the devices. Proceed with caution.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let confirmAction = UIAlertAction(title: "Proceed", style: .destructive) { _ in
            Utility.showLoader(message: "", view: self.view)
            self.apiManager.genericAuthorizedJSONRequest(url: Constants.deleteUserAccount + "?request=true", parameter: nil, method: .delete) { response, error in
                Utility.hideLoader(view: self.view)
                if let statusJSON = response as? [String: Any], let status = statusJSON[Constants.statusKey] as? String {
                    let description = statusJSON[Constants.descriptionKey] as? String
                    if status.lowercased() == Constants.successKey {
                        DispatchQueue.main.async {
                            // Verification code is sent to the user email.
                            // Shows UI for entering the code.
                            self.confirmationView.isHidden = false
                        }
                        return
                    }
                    Utility.showToastMessage(view: self.view, message: description ?? "Unable to process request.", duration: 5.0)
                } else if let apiError = error {
                    Utility.showToastMessage(view: self.view, message: apiError.description, duration: 5.0)
                    return
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func backClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func showSuccessAlert() {
        let alertController = UIAlertController(title: "", message: "Your account has been deleted successfully!", preferredStyle: .alert)
        let okButton = UIAlertAction(title: "Ok", style: .default) { _ in
            Utility.showLoader(message: "", view: self.view)
            // Logs out user if user account is deleted.
            let service = ESPLogoutService(presenter: self)
            service.logoutUser()
        }
        alertController.addAction(okButton)
        present(alertController, animated: true, completion: nil)
    }
    
}

extension DeleteAccountViewController: ESPLogoutUserPresentationLogic, ESPNoRefreshTokenLogic {
    
    func userLoggedOut(withError error: ESPAPIError?) {
        self.clearUserData()
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            self.navigationController?.popToRootViewController(animated: false)
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
