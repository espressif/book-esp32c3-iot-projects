//
// Copyright 2014-2018 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License").
// You may not use this file except in compliance with the
// License. A copy of the License is located at
//
//     http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, express or implied. See the License
// for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

class ResetPasswordViewController: UIViewController {

    @IBOutlet var confirmationCode: UITextField!
    @IBOutlet var proposedPassword: UITextField!
    @IBOutlet var confirmNewPassword: UITextField!
    @IBOutlet var infoLabel: UILabel!
    
    var userName: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let username = userName {
            infoLabel.text = "To set a new password we have sent a verification code to " + username
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    // MARK: - IBActions

    @IBAction func cancelPressed(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func updatePassword(_: AnyObject) {
        guard let confirmationCodeValue = confirmationCode.text, !confirmationCodeValue.isEmpty else {
            showAlert(title: "Code is empty", message: "Please enter a valid confirmation code.")
            return
        }
        guard let newPassword = proposedPassword.text, !newPassword.isEmpty else {
            showAlert(title: "Password Field Empty", message: "Please enter a password of your choice.")
            return
        }
        guard let confirmPassword = confirmNewPassword.text, confirmPassword == newPassword else {
            showAlert(title: "Password mismatch", message: "Re-entered password do not match.")
            return
        }

        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        let service = ESPForgotPasswordService(presenter: self)
        service.confirmForgotPassword(name: self.userName ?? "", password: proposedPassword.text!, verificationCode: confirmationCodeValue)
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)
    }
}

extension ResetPasswordViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case proposedPassword:
            confirmNewPassword.becomeFirstResponder()
        case confirmNewPassword:
            confirmationCode.becomeFirstResponder()
        case confirmationCode:
            confirmationCode.resignFirstResponder()
            updatePassword(textField)
        default:
            return true
        }
        return true
    }
}

extension ResetPasswordViewController: ESPForgotPasswordPresentationLogic {
    
    func requestedForgotPassword(withError error: ESPAPIError?) {}
    
    func confirmForgotPassword(withError error: ESPAPIError?) {
        DispatchQueue.main.async { [self] in
            Utility.hideLoader(view: self.view)
            if let _ = error {
                self.handleError(error: error, buttonTitle: "Ok")
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
}
