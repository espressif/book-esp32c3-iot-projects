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
//  AppDelegate+ESPAlexa.swift
//  ESPRainMaker
//

import Foundation
import UIKit

extension AppDelegate {
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL {
                var isRainmakerAuthCode = false
                if url.absoluteString.contains(ESPAlexaServiceConstants.rainmakerCode) {
                    isRainmakerAuthCode = true
                }
                if let vc = ESPEnableAlexaSkillService.getTopVC() as? ESPEnableAlexaSkillPresenter {
                    if isRainmakerAuthCode {
                        vc.actOnURL(url: url.absoluteString, state: .rainMakerAuthCode)
                    } else {
                        vc.actOnURL(url: url.absoluteString, state: .none)
                    }
                } else {
                    if User.shared.isUserSessionActive {
                        if isRainmakerAuthCode {
                            navigateToEnableSkillPage(url: url.absoluteString, state: .rainMakerAuthCode)
                        } else {
                            navigateToEnableSkillPage(url: url.absoluteString, state: .none)
                        }
                    }
                }
            }
        }
        return false
    }
    
    
    /// Method navigates to ESPAlexaConnectViewController from whatever screen is opened in the screen.
    /// - Parameters:
    ///   - url: url: URL retrieved from WKWebview or Alexa app
    ///   - state: state for which url is retrieved
    private func navigateToEnableSkillPage(url: String, state: ESPEnableSkillState) {
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                for viewController in viewControllers {
                    if viewController.isKind(of: UserNavigationController.self) {
                        tabBarController.selectedViewController = viewController
                        if let vc = viewController as? UINavigationController {
                            for viewController in vc.viewControllers {
                                viewController.presentedViewController?.dismiss(animated: true, completion: nil)
                            }
                            vc.popToRootViewController(animated: true)
                        }
                        let settingsPageViewController = (viewController as! UINavigationController).viewControllers.first
                        if let vc = getVoicesVC(), let connectToAlexaVC = ESPEnableAlexaSkillService.getConnectToAlexaVC() {
                            settingsPageViewController?.navigationController?.pushViewController(vc, animated: true)
                            settingsPageViewController?.navigationController?.pushViewController(connectToAlexaVC, animated: true)
                            DispatchQueue.main.asyncAfter(deadline: .now()+2.0, execute: {
                                connectToAlexaVC.checkAccountLinkingAndActOnURL(url: url, state: state)
                            })
                        }
                    }
                }
            }
        }
    }
    
    /// Method gets an object of VoiceServicesViewController
    /// - Returns: instance of VoiceServicesViewController
    private func getVoicesVC() -> VoiceServicesViewController? {
        let storyboard = UIStoryboard(name: "User", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "VoiceServicesViewController") as? VoiceServicesViewController {
            return vc
        }
        return nil
    }
}
