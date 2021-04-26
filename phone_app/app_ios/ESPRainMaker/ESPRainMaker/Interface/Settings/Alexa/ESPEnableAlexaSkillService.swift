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
//  EnableAlexaSkillService.swift
//  ESPRainMaker
//

import Foundation
import UIKit
import AuthenticationServices
import SafariServices
import AVFoundation
import Alamofire
import WebKit

/// Skill state for which webview is to be shown i.e. login to amazon, enable skill linking and login to rainmaker
enum ESPEnableSkillState {
    case loginWithAmazon
    case rainMakerAuthCode
    case none
}

// MARK: Protocol defines methods used to initiate alexa app to app linking
protocol ESPEnableAlexaFlowInitiationDelegate {
    func initiateEnableSkillFlow()
    func isAccountLinked(completion: @escaping (Bool) -> Void)
    func invokeAlexaAppFlow(_ completionHandler: @escaping () -> Void)
    func invokeLWAFlow()
}

// MARK: Protocol defines methods for various API calls required for enabling/disabling alexa app to app linking
protocol ESPEnableAlexaAPIDelegate {
    
    func getAlexaAccessToken(code: String)
    func getAPIEndPoint()
    func getLinkingStatus(completionHandler: @escaping (Bool, Error?) -> Void)
    func enableSkill(code: String)
    func disableSkill()
    func getAlexaAccessTokenWithRefreshToken(completionHandler: @escaping (String?) -> Void)
    func loginViaRainmaker()
}

// MARK: Class is responsible for initiating and executing enable/disable app to app linking
class ESPEnableAlexaSkillService: NSObject {
    
    var presenter: ESPEnableAlexaSkillPresenter?
    var apiWorker: ESPAlexaAPIWorker!
    var apiService: ESPAlexaAPIService!
    var skillState: ESPEnableSkillState = .none
    
    init(presenter: ESPEnableAlexaSkillPresenter?) {
        self.presenter = presenter
        self.apiWorker = ESPAlexaAPIWorker()
        self.apiService = ESPAlexaAPIService()
    }
    
    /*
     Checked linking status and if unlinked show login to rainmaker webview.
     If access token has expired restart the linking process by fetching access token again.
     Else show error alert to user.
     */
    func getLinkingStatusAndLoginToRainmaker() {
        self.getLinkingStatus() { status, error in
            if status {
                self.presenter?.showToast(message: ESPAlexaServiceConstants.accountLinked)
                self.presenter?.accountLinked(status: true)
            } else {
                if let error = error as? ESPAlexaAPIStatus {
                    switch error {
                    case .alexaAccessTokenExpired:
                        self.restartEnableProcess()
                    case .accountNotLinked:
                        self.loginViaRainmaker()
                    default:
                        self.presenter?.showToast(message: ESPAlexaServiceConstants.accountLinkingFailed)
                    }
                } else {
                    self.presenter?.showToast(message: ESPAlexaServiceConstants.accountLinkingFailed)
                }
            }
        }
    }
    
    /// Clear access token. Restart app-app linking process.
    func restartEnableProcess() {
        ESPAlexaTokenWorker.shared.clearAccessToken()
        initiateEnableSkillFlow()
    }
    
    /// Clear access token if it is expired. Restart unlinking process by fetching access token again
    func restartDisableProcess() {
        ESPAlexaTokenWorker.shared.clearAccessToken()
        self.presenter?.showLoader(message: "")
        self.getAlexaAccessToken() { accessToken in
            self.presenter?.hideLoader()
            if let _ = accessToken {
                self.disableSkill()
            }
        }
    }
    
    /// Method returns the url by replacing the state value with a random string
    /// - Parameter url: url in which the state is to be replaced
    /// - Parameter skillState: enable skill state for which method is invoked
    /// - Returns: url with replaced state
    private func getURLWithState(url: String, skillState: ESPEnableSkillState) -> URL? {
        var state = ""
        if skillState == .rainMakerAuthCode {
            state = "\(ESPAlexaServiceConstants.rainmakerCode)\(Configuration.shared.espAlexaConfiguration.urlState)"
        } else {
            state = Configuration.shared.espAlexaConfiguration.urlState
        }
        let urlString = url.replacingOccurrences(of: Configuration.shared.espAlexaConfiguration.state, with: state)
        if let alexaURL = URL(string: urlString) {
            UserDefaults.standard.set(state, forKey: ESPAlexaServiceConstants.alexaState)
            return alexaURL
        }
        return nil
    }
    
    /// Get access token from userdefaults if valid. If access token is invalid or expired then get new access token using refresh token.
    /// - Parameter completionHandler: callback invoked with access token if fetched or nil if not available
    private func getAlexaAccessToken(completionHandler: @escaping (String?) -> Void) {
        if let accessToken = ESPAlexaTokenWorker.shared.getAccessToken {
            completionHandler(accessToken)
        } else if let _ = ESPAlexaTokenWorker.shared.getRefreshToken {
            self.getAlexaAccessTokenWithRefreshToken() { accessToken in
                completionHandler(accessToken)
            }
        } else {
            completionHandler(nil)
        }
    }
    
    /// Get current top view controller
    /// - Returns: top viewcontroller in the app
    static func getTopVC() -> UIViewController? {
        if let root = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            if let nav = root.selectedViewController as? UINavigationController {
                let viewControllers = nav.viewControllers
                if viewControllers.count > 0 {
                    return viewControllers.last
                }
            }
        }
        return nil
    }
    
    /// Returns instance to AlexaWebViewController
    /// - Returns: AlexaWebViewController instance
    static func getWebviewVC() -> ESPAlexaWebViewController? {
        let storyboard = UIStoryboard(name: ESPAlexaServiceConstants.alexaViewsStoryboard, bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: ESPAlexaWebViewController.storyboardId) as? ESPAlexaWebViewController {
            return vc
        }
        return nil
    }
    
    /// Returns instance of AlexaConnectViewController
    /// - Returns: AlexaConnectViewController object
    static func getConnectToAlexaVC() -> ESPAlexaConnectViewController? {
        let storyboard = UIStoryboard(name: ESPAlexaServiceConstants.alexaViewsStoryboard, bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: ESPAlexaConnectViewController.storyboardId) as? ESPAlexaConnectViewController {
            return vc
        }
        return nil
    }
    
    static func isAlexaConfigValid() -> Bool {
        if let alexaConfig = Configuration.shared.espAlexaConfiguration {
            if alexaConfig.appClientId.count > 0, alexaConfig.appClientSecret.count > 0, alexaConfig.skillStage.count > 0, alexaConfig.redirectURI.count > 0, alexaConfig.skillId.count > 0, alexaConfig.clientId.count > 0, alexaConfig.fetchAccessTokenURL.count > 0 {
                return true
            }
        }
        return false
    }
}

// MARK: Webview delegate methods
extension ESPEnableAlexaSkillService: ESPAlexaWebViewDelegate {
    
    /// Extract auth code for rainmaker or amazon from URL
    /// - Parameters:
    ///   - url: URL containing code
    ///   - state: Skill state (get auth code for amazon alexa or rainmaker)
    func extractCode(url: String, state: ESPEnableSkillState) {
        if let presenter = self.presenter {
            presenter.actOnURL(url: url, state: state)
        }
    }
    
    /// Show error alert if auth code cannot be extracted from URL for amazon alexa or ranmaker login
    /// - Parameter message: Error message to be shown
    func errorOccurred(message: String) {
        self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: message)
    }
}


// MARK: Methods for initiating app to app linking
extension ESPEnableAlexaSkillService: ESPEnableAlexaFlowInitiationDelegate {
    
    /// Called to initiate enable app to app linking flow
    func initiateEnableSkillFlow() {
        self.getAlexaAccessToken() { accessToken in
            if let _ = accessToken {
                if let _ = ESPAlexaTokenWorker.shared.getAlexaURLEndPoints {
                    self.getLinkingStatusAndLoginToRainmaker()
                } else {
                    self.getAPIEndPoint()
                }
            } else {
                self.invokeAlexaAppFlow() {
                    self.invokeLWAFlow()
                }
            }
        }
    }
    
    /// Call API to check if account is linked
    /// - Parameter completion: callback with flag informing whether account is linked or not
    func isAccountLinked(completion: @escaping (Bool) -> Void) {
        self.getAlexaAccessToken() { accessToken in
            if let _ = accessToken {
                if let _ = ESPAlexaTokenWorker.shared.getAlexaURLEndPoints {
                    self.getLinkingStatus() { status, error in
                        completion(status)
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Invoke app to app linking flow via Alexa app
    /// - Parameter completionHandler: callback with flag as to whether the alexa app was launched or not
    func invokeAlexaAppFlow(_ completionHandler: @escaping () -> Void) {
        if let alexaURL = self.getURLWithState(url: Configuration.shared.espAlexaConfiguration.alexaURL, skillState: .none) {
            if UIApplication.shared.canOpenURL(alexaURL) {
                UIApplication.shared.open(alexaURL, options: [.universalLinksOnly: true]) { launched in
                    if !launched {
                        completionHandler()
                    }
                }
            }
        }
    }
    
    /// Invoke LWA workflow
    func invokeLWAFlow() {
        if let lwaURL = self.getURLWithState(url: Configuration.shared.espAlexaConfiguration.lwaURL, skillState: .none) {
            if let vc = ESPEnableAlexaSkillService.getWebviewVC(), let presenter = self.presenter as? UIViewController {
                vc.delegate = self
                presenter.navigationController?.present(vc, animated: true) {
                    vc.clearCookies()
                    vc.launchWebview(url: lwaURL, state: .loginWithAmazon, presenter: presenter)
                }
            }
        }
    }
}

// MARK: Methods for making alexa API calls
extension ESPEnableAlexaSkillService: ESPEnableAlexaAPIDelegate {
    
    /// Call alexa API service to fetch alexa access token using alexa auth code
    /// If alexa access tolen is fetched then call get Alexa API endpoint
    /// If error occurs then show error alert
    /// - Parameter code: alexa auth code
    func getAlexaAccessToken(code: String) {
        self.presenter?.showLoader(message: "")
        apiService.getESPAlexaAccessToken(code: code) { status in
            self.presenter?.hideLoader()
            switch status {
            case .alexaAccessTokenFetched:
                self.getAPIEndPoint()
            case .serverError(let error):
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: error.localizedDescription)
            case .unauthorized:
                ESPAlexaTokenWorker.shared.clearAllClientTokens()
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: ESPAlexaServiceConstants.unauthorized)
            case .httpError(_):
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: ESPAlexaServiceConstants.accountLinkingFailed)
            default:
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: ESPAlexaServiceConstants.accountLinkingFailed)
            }
        }
    }
    
    /*
     Call API to fetch alexa API endpoint. If endpoints are fetched, then check linked status for account.
     If account is not linked get linked status and invoke webview to login to rainmaker to get rainmaker auth code.
     If alexa token has expired call restart app linking process by making user login to amazon and allow linking accounts and get alexa auth code, use that to get alexa tokens and restart the linking process.
     */
    func getAPIEndPoint() {
        self.presenter?.showLoader(message: "")
        apiService.getESPAPIEndPoint() { status in
            self.presenter?.hideLoader()
            switch status {
            case .apiEndpointFetched:
                self.getLinkingStatusAndLoginToRainmaker()
            case .errorMessage(let message):
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: message)
            case .serverError(let error):
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: error.localizedDescription)
            case .alexaAccessTokenExpired:
                self.restartEnableProcess()
            case .unauthorized:
                ESPAlexaTokenWorker.shared.clearAllClientTokens()
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: ESPAlexaServiceConstants.unauthorized)
            default:
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: ESPAlexaServiceConstants.accountLinkingFailed)
            }
        }
    }
    
    /*
     Call alexa api to get linking status.
     If account is linked invoke completion handler with true.
     If account is not linked invoke completion handler with false.
     If error occurs invoke callback with error.
     - Parameter completionHandler: callback invoked with true if accounts are linked and false if accounts are false.
     */
    func getLinkingStatus(completionHandler: @escaping (Bool, Error?) -> Void) {
        self.presenter?.showLoader(message: "")
        apiService.getESPLinkingStatus() { status in
            self.presenter?.hideLoader()
            switch status {
            case .unauthorized:
                ESPAlexaTokenWorker.shared.clearAllClientTokens()
                completionHandler(false, nil)
            case .accountLinked:
                completionHandler(true, nil)
            case .accountNotLinked:
                completionHandler(false, ESPAlexaAPIStatus.accountNotLinked as Error)
            case .alexaAccessTokenExpired:
                completionHandler(false, ESPAlexaAPIStatus.alexaAccessTokenExpired as Error)
            default:
                completionHandler(false, nil)
            }
        }
    }
    
    /*
     Call API to enable app-app linking.
     If account is linked to change the alexa connect viewcontroller to connected to alexa view.
     If not linked show toast message with "Account linking failed".
     If alexa token has expired restart the linking process starting with getting alexa access token.
     - Parameter code: rainmaker auth code
     */
    func enableSkill(code: String) {
        self.presenter?.showLoader(message: "")
        apiService.espEnableSkill(code: code) { status in
            self.presenter?.hideLoader()
            switch status {
            case .accountLinked:
                self.presenter?.showToast(message: ESPAlexaServiceConstants.accountLinked)
                self.presenter?.accountLinked(status: true)
            case .serverError(let error):
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: error.localizedDescription)
            case .alexaAccessTokenExpired:
                ESPAlexaTokenWorker.shared.clearAllClientTokens()
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: ESPAlexaServiceConstants.accountLinkingFailed)
            case .unauthorized:
                ESPAlexaTokenWorker.shared.clearAllClientTokens()
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: ESPAlexaServiceConstants.unauthorized)
            default:
                self.presenter?.showToast(message: ESPAlexaServiceConstants.accountLinkingFailed)
            }
        }
    }
    
    /*
     Call API to disable app-app linking.
     If account linking is removed to change the alexa connect viewcontroller to connect to alexa view.
     If alexa token has expired restart the de-linking process starting with getting alexa access token.
     */
    func disableSkill() {
        self.presenter?.showLoader(message: "")
        apiService.espDisableSkill() { status in
            self.presenter?.hideLoader()
            switch status {
            case .linkDeleted:
                ESPAlexaTokenWorker.shared.clearAllClientTokens()
                self.presenter?.showToast(message: ESPAlexaServiceConstants.accountLinkingDisabled)
                self.presenter?.accountLinked(status: false)
            case .serverError(let error):
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: error.localizedDescription)
            case .unauthorized:
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: ESPAlexaServiceConstants.unauthorized)
            case .alexaAccessTokenExpired:
                self.restartDisableProcess()
            default:
                self.presenter?.showErrorAlert(title: ESPAlexaServiceConstants.error, message: ESPAlexaServiceConstants.accountUnlinkingFailed)
            }
        }
    }
    
    /// Request alexa access token using alexa refresh token
    /// - Parameter completionHandler: callback invoked with access token is accessed ot nil if absent.
    func getAlexaAccessTokenWithRefreshToken(completionHandler: @escaping (String?) -> Void) {
        apiService.getESPAlexaAccessTokenWithRefreshToken() { status in
            switch status {
            case .alexaAccessTokenFetched:
                completionHandler(ESPAlexaTokenWorker.shared.getAccessToken)
            case .unauthorized:
                ESPAlexaTokenWorker.shared.clearAllClientTokens()
                completionHandler(nil)
            case .httpError(_):
                completionHandler(nil)
            default:
                completionHandler(nil)
            }
        }
    }
    
    /// Launch webview with rainmaker login page (hosted UI).
    func loginViaRainmaker() {
        if let rainmakerURL = self.getURLWithState(url: Configuration.shared.espAlexaConfiguration.rainmakerURL, skillState: .rainMakerAuthCode) {
            UIApplication.shared.open(rainmakerURL, options: [.universalLinksOnly: false], completionHandler: { _ in})
        }
    }
}
