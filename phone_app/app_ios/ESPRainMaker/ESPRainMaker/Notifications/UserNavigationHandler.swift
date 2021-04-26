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
//  UserNavigationHandler.swift
//  ESPRainMaker
//

import Foundation
import UIKit

// Handle navigation on tap of notifications
enum UserNavigationHandler {
    case homeScreen
    case notificationViewController
    
    func navigateToPage() {
        // Gets top view controller currently visible on app.
        var top = UIApplication.shared.keyWindow?.rootViewController
        if let presented = top?.presentedViewController {
            top = presented
        } else if let nav = top as? UINavigationController {
            top = nav.visibleViewController
        } else if let tab = top as? UITabBarController {
            top = tab.selectedViewController
            if top?.isKind(of: UINavigationController.self) ?? false {
                let userNavVC = top as? UINavigationController
                top = userNavVC?.visibleViewController
            }
        }
        
        switch self {
        case .homeScreen:
            // Checks if current screen is Home screen.
            if top?.isKind(of: DevicesViewController.self) ?? false {
                let devicesVC = top as? DevicesViewController
                if devicesVC?.isViewLoaded ?? false {
                    devicesVC?.refreshDeviceList()
                } else {
                    User.shared.updateDeviceList = true
                }
                return
            }
            navigateToHomeScreen()
        case .notificationViewController:
            // Checks if current screen is Notfication screen.
            if top?.isKind(of: NotificationsViewController.self) ?? false {
                if let notificationVC = top as? NotificationsViewController {
                    notificationVC.refreshData()
                    return
                }
            }
            navigateToNotificationVC()
        }
    }
    
    // Method to redirect user to Notifications screen.
    private func navigateToNotificationVC() {
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                for viewController in viewControllers {
                    if viewController.isKind(of: UserNavigationController.self) {
                        tabBarController.selectedViewController = viewController
                        tabBarController.tabBar.isHidden = true
                        let settingsPageViewController = (viewController as! UINavigationController).viewControllers.first
                        let userStoryBoard = UIStoryboard(name: "User", bundle: nil)
                        let notificationsViewController = userStoryBoard.instantiateViewController(withIdentifier: "notificationsVC") as! NotificationsViewController
                        settingsPageViewController?.navigationController?.pushViewController(notificationsViewController, animated: true)
                    }
                }
            }
        }
    }
    
    // Method to redirect user to Home Screen.
    private func navigateToHomeScreen() {
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                for viewController in viewControllers {
                    if viewController.isKind(of: DevicesNavigationController.self) {
                        tabBarController.selectedViewController = viewController
                        tabBarController.tabBar.isHidden = false
                        let navigationVC = viewController as? DevicesNavigationController
                        User.shared.updateDeviceList = true
                        navigationVC?.popToRootViewController(animated: false)
                    }
                }
            }
        }
    }
}
