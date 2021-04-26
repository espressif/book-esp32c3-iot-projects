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

import UIKit
import Foundation

class ForgotPasswordViewController: UIViewController {
    
    @IBOutlet var username: UITextField!
    var sender: AnyObject!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if let newPasswordViewController = segue.destination as? ResetPasswordViewController {
            newPasswordViewController.userName = self.username.text
        }
    }

    @IBAction func cancelPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - IBActions

    // handle forgot password
    @IBAction func forgotPassword(_ sender: AnyObject) {
        self.sender = sender
        guard let username = self.username.text, !username.isEmpty else {
            let alertController = UIAlertController(title: "Missing UserName",
                                                    message: "Please enter a valid user name.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)
            return
        }
        
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        let service = ESPForgotPasswordService(presenter: self)
        service.requestForgotPassword(name: self.username.text!)
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        username.resignFirstResponder()
        forgotPassword(textField)
        return true
    }
}

extension ForgotPasswordViewController: ESPForgotPasswordPresentationLogic {
    
    func requestedForgotPassword(withError error: ESPAPIError?) {
        DispatchQueue.main.async { [self] in
            Utility.hideLoader(view: self.view)
            if let err = error {
                self.handleError(error: error, buttonTitle: "Ok")
            } else {
                if let sender = self.sender {
                    self.performSegue(withIdentifier: "confirmForgotPasswordSegue", sender: sender)
                }
            }
        }
    }
    
    func confirmForgotPassword(withError error: ESPAPIError?) {}
    
}
