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

class ConfirmSignUpViewController: UIViewController {
    var sentTo: String?
    var confirmExistingUser = false

    @IBOutlet var sentToLabel: UILabel!
    @IBOutlet var code: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let sent = sentTo {
            sentToLabel.text = sent
        }
        code.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.title = ""
        navigationItem.backBarButtonItem?.tintColor = UIColor(red: 234.0 / 255.0, green: 92.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0)
        code.setBottomBorder()
    }

    // MARK: IBActions

    @IBAction func cancelClicked(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    // handle confirm sign up
    @IBAction func confirm(_: AnyObject) {
        guard let confirmationCodeValue = code.text, !confirmationCodeValue.isEmpty else {
            let alertController = UIAlertController(title: "Confirmation code missing.",
                                                    message: "Please enter a valid confirmation code.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)
            return
        }
        Utility.showLoader(message: "", view: view)
        let service = ESPCreateUserService(presenter: self)
        service.confirmUser(name: sentTo!, verificationCode: code.text!)
    }

    // handle code resend action
    @IBAction func resend(_: AnyObject) {
        
        let service = ESPCreateUserService(presenter: self)
        service.createNewUser(name: User.shared.username, password: User.shared.password)
    }
}

extension ConfirmSignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        code.resignFirstResponder()
        confirm(textField)
        return true
    }
}

extension ConfirmSignUpViewController: ESPCreateUserPresentationLogic {
    
    func verifyUser(withName name: String, andPassword password: String, withError error: ESPAPIError?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            if error != nil {
                self.handleError(error: error, buttonTitle: "Retry")
            } else {
                let alertController = UIAlertController(title: "Code Resent",
                                                        message: User.shared.username,
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func userVerified(withError error: ESPAPIError?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
        if error == nil {
            if self.confirmExistingUser {
                self.confirmExistingUser = false
                let alertController = UIAlertController(title: "Success",
                                                        message: "User has been confirmed. Please enter your credentials in login page to sign in with this user.",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    self.navigationController?.popToRootViewController(animated: true)
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                User.shared.automaticLogin = true
                _ = self.navigationController?.popToRootViewController(animated: true)
            }
        } else {
            self.handleError(error: error, buttonTitle: "Ok")
        }
    }
}
