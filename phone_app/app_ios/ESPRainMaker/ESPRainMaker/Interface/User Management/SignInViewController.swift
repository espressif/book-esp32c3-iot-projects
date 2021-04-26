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

import Alamofire
import AuthenticationServices
import Foundation
import JWTDecode
import SafariServices

class SignInViewController: UIViewController, ESPNoRefreshTokenLogic, UITextViewDelegate {
    
    @IBOutlet var checkBox: UIButton!
    @IBOutlet var signInTopSpace: NSLayoutConstraint!
    @IBOutlet var signUpTopView: NSLayoutConstraint!
    @IBOutlet var signInButton: PrimaryButton!
    @IBOutlet var username: UITextField!
    @IBOutlet var signUpButton: PrimaryButton!
    @IBOutlet var password: UITextField!
    @IBOutlet var topView: UIView!
    @IBOutlet var signUpView: UIView!
    @IBOutlet var signInView: UIView!
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var githubLoginButton: UIButton!
    @IBOutlet var googleLoginButton: UIButton!
    @IBOutlet var appleLoginButton: UIButton!
    @IBOutlet var appVersionLabel: UILabel!
    @IBOutlet var signupTextView: UITextView!
    @IBOutlet weak var agreementTextView: UITextView!
    @IBOutlet weak var agreementView: UIView!
    @IBOutlet weak var agreementBox: UIButton!
    var sentTo: String?

    @IBOutlet var registerPassword: UITextField!
    @IBOutlet var confirmPassword: UITextField!
    @IBOutlet var email: UITextField!

    var usernameText: String?
    var session: SFAuthenticationSession!
    var checked = false
    var agreementChecked = false
    
    // String constants
    let privacyLink = "privacy"
    let termsOfUseLink = "termsOfUse"
    let appDelegate = UIApplication.shared.delegate as? AppDelegate

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentationController?.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: animated)
        segmentControl.selectedSegmentIndex = 0
        changeSegment()
        password.text = ""
        username.text = ""
        registerPassword.text = ""
        confirmPassword.text = ""
        email.text = ""
        checked = false
        checkBox.setImage(UIImage(named: "checkbox_unchecked"), for: .normal)

        githubLoginButton.layer.backgroundColor = UIColor.white.cgColor
        githubLoginButton.layer.shadowColor = UIColor.lightGray.cgColor
        githubLoginButton.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        githubLoginButton.layer.shadowRadius = 0.5
        githubLoginButton.layer.shadowOpacity = 0.5
        githubLoginButton.layer.masksToBounds = false

        googleLoginButton.layer.backgroundColor = UIColor.white.cgColor
        googleLoginButton.layer.shadowColor = UIColor.lightGray.cgColor
        googleLoginButton.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        googleLoginButton.layer.shadowRadius = 0.5
        googleLoginButton.layer.shadowOpacity = 0.5
        googleLoginButton.layer.masksToBounds = false

        appleLoginButton.layer.shadowColor = UIColor.lightGray.cgColor
        appleLoginButton.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        appleLoginButton.layer.shadowRadius = 0.5
        appleLoginButton.layer.shadowOpacity = 0.5
        appleLoginButton.layer.masksToBounds = false

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        var currentBGColor: UIColor!
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            currentBGColor = UIColor(hexString: "#8265E3")
        }
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any], for: .normal)
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any], for: .selected)
        segmentControl.changeUnderlineColor(color: currentBGColor)
        agreementView.isHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if User.shared.automaticLogin {
            User.shared.automaticLogin = false
            password.text = User.shared.password
            username.text = User.shared.username
            signIn(username: User.shared.username, password: User.shared.password)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        // Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.title = ""
        navigationItem.backBarButtonItem?.tintColor = UIColor(red: 234.0 / 255.0, green: 92.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        if #available(iOS 13.0, *) {
            isModalInPresentation = false
        } else {
            // Fallback on earlier versions
        }
        segmentControl.addUnderlineForSelectedSegment()
        appVersionLabel.text = "App Version - v" + Constants.appVersion + " (\(GIT_SHA_VERSION))"
        agreementTextView.delegate = self
        signupTextView.delegate = self

        let regularText = NSMutableAttributedString(string: "By proceeding, I confirm that I have read and agree to the ", attributes: [ NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)])

        // Sets attributes for clickable text in the UITextView string.
        let attributes:[NSAttributedString.Key : Any] = [NSAttributedString.Key.underlineStyle: 1, NSAttributedString.Key.underlineColor: UIColor.blue, NSAttributedString.Key.foregroundColor: UIColor.blue, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let privacyText = NSMutableAttributedString(string: "Privacy Policy")
        privacyText.addAttributes(attributes, range: NSMakeRange(0, privacyText.length))
        privacyText.addAttributes([NSAttributedString.Key.link: privacyLink], range: NSMakeRange(0, privacyText.length))
        regularText.append(privacyText)
        regularText.append(NSMutableAttributedString(string: " and ", attributes: [ NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]))
        let termsOfUseText = NSMutableAttributedString(string: "Terms of Use.")
        termsOfUseText.addAttributes(attributes, range: NSMakeRange(0, termsOfUseText.length))
        termsOfUseText.addAttributes([NSAttributedString.Key.link: termsOfUseLink], range: NSMakeRange(0, termsOfUseText.length))
        regularText.append(termsOfUseText)
        
        signupTextView.attributedText = regularText
        agreementTextView.attributedText = regularText
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if let signUpConfirmationViewController = segue.destination as? ConfirmSignUpViewController {
            signUpConfirmationViewController.sentTo = sentTo
        }
    }
    
    // UITextViewDelegate method to handle callbacks for clickable text.
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == privacyLink {
            openPrivacy(self)
            return false
        } else if URL.absoluteString == termsOfUseLink {
            openTC(self)
            return false
        }
        return true
    }
    
    @IBAction func segmentChange(sender _: UISegmentedControl) {
        changeSegment()
    }

    @IBAction func clickOnAgree(_: Any) {
        checked = !checked
        if checked {
            checkBox.setImage(UIImage(named: "checkbox_checked"), for: .normal)
        } else {
            checkBox.setImage(UIImage(named: "checkbox_unchecked"), for: .normal)
        }
    }

    func changeSegment() {
        if segmentControl.selectedSegmentIndex == 1 {
            UIView.animate(withDuration: 0.5) {
                self.signInView.isHidden = true
                self.signUpView.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.signInView.isHidden = false
                self.signUpView.isHidden = true
            }
        }
        segmentControl.changeUnderlinePosition()
    }

    @IBAction func loginWithGoogle(_: Any) {
        loginWith(idProvider: "Google")
    }

    @IBAction func loginWithApple(_: Any) {
        loginWith(idProvider: "SignInWithApple")
    }

    @IBAction func loginWithGithub(_: Any) {
        loginWith(idProvider: "GitHub")
    }

    func loginWith(idProvider: String) {
        
        let service = ESPIdProviderLoginService(presenter: self)
        service.loginWith(idProvider: idProvider)
    }

    func requestToken(code: String) {
        let url = Configuration.shared.awsConfiguration.authURL + "/token"
        let parameters = ["grant_type": "authorization_code", "client_id": Configuration.shared.awsConfiguration.appClientId!, "code": code, "redirect_uri": Configuration.shared.awsConfiguration.redirectURL]
        let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
        NetworkManager.shared.genericRequest(url: url, method: .post, parameters: parameters, encoding: URLEncoding.default,
                                             headers: headers) { response in
            if let json = response {
                if let idToken = json["id_token"] as? String, let refreshToken = json["refresh_token"] as? String, let accessToken = json["access_token"] as? String {
                    User.shared.updateUserInfo(token: idToken, provider: .other)
                    User.shared.updateDeviceList = true
                    let refreshTokenInfo = ["token": refreshToken, "time": Date(), "expire_in": json["expires_in"] as? Int ?? 3600] as [String: Any]
                    User.shared.accessToken = accessToken
                    UserDefaults.standard.set(refreshTokenInfo, forKey: Constants.refreshTokenKey)
                    UserDefaults.standard.set(accessToken, forKey: Constants.accessTokenKey)
                    DispatchQueue.main.async {
                        // Configure remote notification.
                        self.appDelegate?.configureRemoteNotifications()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }

    func getViewController() -> UIViewController {
        return self
    }

    @IBAction func signInPressed(_: AnyObject) {
        dismissKeyboard()
        signInButton.isEnabled = false
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            guard let usernameValue = username.text, !usernameValue.isEmpty, let password = password.text, !password.isEmpty else {
                let alertController = UIAlertController(title: "Missing information",
                                                        message: "Please enter a valid user name and password",
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)
                present(alertController, animated: true, completion: nil)
                signInButton.isEnabled = true
                return
            }
            signIn(username: usernameValue, password: password)
        }
    }

    func signIn(username: String, password: String) {
        Utility.showLoader(message: "Signing in", view: view)
        User.shared.username = username
        let service = ESPLoginService(presenter: self)
        service.loginUser(name: username, password: password)
    }

    func showAlert() {
        let alertController = UIAlertController(title: "Failure",
                                                message: "Failed to login. Please try again.",
                                                preferredStyle: .alert)
        let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func signUp(_ sender: AnyObject) {
        dismissKeyboard()
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            guard let userNameValue = email.text, !userNameValue.isEmpty,
                  let passwordValue = registerPassword.text, !passwordValue.isEmpty
            else {
                let alertController = UIAlertController(title: "Missing Required Fields",
                                                        message: "Username / Password are required for registration.",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return
            }

            if let confirmPasswordValue = confirmPassword.text, confirmPasswordValue != passwordValue {
                let alertController = UIAlertController(title: "Mismatch",
                                                        message: "Re-entered password do not match.",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return
            }

            if !checked {
                let alertController = UIAlertController(title: "Error!!",
                                                        message: "Please accept our terms and condition before signing up",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return
            }
            signUpButton.isEnabled = false
            Utility.showLoader(message: "", view: view)

            // sign up the user
            let service = ESPCreateUserService(presenter: self)
            service.createNewUser(name: userNameValue, password: passwordValue)
        }
    }

    @objc func keyboardNotification(notification _: NSNotification) {}

    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    @objc func keyboardWillShow(notification _: NSNotification) {
        if signUpView.isHidden {
            UIView.animate(withDuration: 0.45, animations: {
                self.signInTopSpace.constant = -100.0
            })
        } else {
            UIView.animate(withDuration: 0.45, animations: {
                self.signUpTopView.constant = -50.0
            })
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        if signUpView.isHidden {
            UIView.animate(withDuration: 0.45, animations: {
                self.signInTopSpace.constant = 0
            })
        } else {
            UIView.animate(withDuration: 0.45, animations: {
                self.signUpTopView.constant = 0
            })
        }
    }

    @IBAction func openPrivacy(_: Any) {
        showDocumentVC(url: Configuration.shared.externalLinks.privacyPolicyURL)
    }

    @IBAction func openDocumentation(_: Any) {
        showDocumentVC(url: Configuration.shared.externalLinks.documentationURL)
    }

    @IBAction func openTC(_: Any) {
        showDocumentVC(url: Configuration.shared.externalLinks.termsOfUseURL)
    }

    func showDocumentVC(url: String) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let documentVC = storyboard.instantiateViewController(withIdentifier: "documentVC") as! DocumentViewController
        modalPresentationStyle = .popover
        documentVC.documentLink = url
        present(documentVC, animated: true, completion: nil)
    }
    
    func getUserInfo(token: String, provider: ServiceProvider) {
        do {
            let json = try decode(jwt: token)
            User.shared.userInfo.username = json.body["cognito:username"] as? String ?? ""
            User.shared.userInfo.email = json.body["email"] as? String ?? ""
            User.shared.userInfo.userID = json.body["custom:user_id"] as? String ?? ""
            User.shared.userInfo.loggedInWith = provider
            User.shared.userInfo.saveUserInfo()
        } catch {
            print("error parsing token")
        }
        User.shared.updateDeviceList = true
    }

    func goToConfirmUserScreen() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let confirmUserVC = storyboard.instantiateViewController(withIdentifier: "confirmSignUpVC") as! ConfirmSignUpViewController
        confirmUserVC.confirmExistingUser = true
        confirmUserVC.sentTo = username.text ?? ""
        navigationController?.pushViewController(confirmUserVC, animated: true)
    }

    func resendConfirmationCode() {
        
        let service = ESPCreateUserService(presenter: self)
        service.createNewUser(name: username.text ?? "", password: password.text ?? "")
    }
    
    // MARK: Landing View
    
    @IBAction func agreementBoxClicked(_ sender: Any) {
        agreementChecked = !agreementChecked
        if agreementChecked {
            agreementBox.setImage(UIImage(named: "checkbox_checked"), for: .normal)
        } else {
            agreementBox.setImage(UIImage(named: "checkbox_unchecked"), for: .normal)
        }
    }
    
    @IBAction func proceedClicked(_ sender: Any) {
        if !agreementChecked {
            let alertController = UIAlertController(title: "Error!!",
                                                    message: "Please accept our terms and condition before signing up",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        } else {
            UIView.transition(with: agreementView, duration: 1.0, options: .transitionFlipFromRight) {
                self.agreementView.isHidden = true
            }
        }
    }
}

extension SignInViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.fullScreen
    }
}

extension SignInViewController: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}

extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case username:
            password.becomeFirstResponder()
        case password:
            password.resignFirstResponder()
            signInPressed(textField)
        case email:
            registerPassword.becomeFirstResponder()
        case registerPassword:
            confirmPassword.becomeFirstResponder()
        case confirmPassword:
            confirmPassword.resignFirstResponder()
        default:
            return true
        }
        return true
    }
}

extension SignInViewController: ESPLoginPresentationLogic {
    func loginCompleted(withError error: ESPAPIError?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            self.signInButton.isEnabled = true
            if error != nil {
                var title: String? = "Error"
                var message: String? = ""
                switch error {
                case .serverError(let serverError):
                    if (serverError as NSError).code == 33 {
                        self.resendConfirmationCode()
                        return
                    }
                    if let text = (serverError as NSError).userInfo["__type"] as? String {
                        title = text
                    }
                    if let text = (serverError as NSError).userInfo["message"] as? String {
                        message = text
                    }
                case .errorCode(let errorCode, let desc):
                    if errorCode == ESPErrorCodeDescription.emailNotVerifiedKey {
                        self.resendConfirmationCode()
                        return
                    }
                    message = desc
                default:
                    break
                }
                let alertController = UIAlertController(title: title,
                                                        message: message,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry",
                                                style: .default,
                                                handler: nil)
                alertController.addAction(retryAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.username.text = nil
                self.password.text = nil
                User.shared.updateUserInfo = true
                // Configure remote notification.
                self.appDelegate?.configureRemoteNotifications()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension SignInViewController: ESPCreateUserPresentationLogic {
    
    func verifyUser(withName name: String, andPassword password: String, withError error: ESPAPIError?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            self.signUpButton.isEnabled = true
            if error != nil {
                self.handleError(error: error, buttonTitle: "Retry")
            } else {
                User.shared.username = name
                User.shared.password = password
                self.sentTo = name
                self.performSegue(withIdentifier: "confirmSignUpSegue", sender: self.signUpButton)
            }
        }
    }
    
    func userVerified(withError error: ESPAPIError?) {}
}

extension SignInViewController: ESPIdProviderLoginPresenter {
    
    func loginFailed() {
        self.showAlert()
    }
    
    func loginSuccess(requestToken: RequestToken) {
        let umTokenWorker = ESPTokenWorker.shared
        if let refreshToken = requestToken.refreshToken {
            umTokenWorker.save(value: refreshToken, key: Constants.refreshTokenKey)
        }
        if let idToken = requestToken.idToken {
            umTokenWorker.save(value: idToken, key: Constants.idTokenKey)
            self.getUserInfo(token: idToken, provider: .other)
        }
        if let accessToken = requestToken.accessToken {
            User.shared.accessToken = accessToken
            umTokenWorker.save(value: accessToken, key: Constants.accessTokenKey)
            DispatchQueue.main.async {
                // Configure remote notification.
                self.appDelegate?.configureRemoteNotifications()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
