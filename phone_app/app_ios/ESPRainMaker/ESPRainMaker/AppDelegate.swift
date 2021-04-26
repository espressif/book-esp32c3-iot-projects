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
//  AppDelegate.swift
//  ESPRainMaker
//

import Alamofire
import DropDown
import ESPProvision
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var storyboard: UIStoryboard?
    var isInitialized = false
    let apiManager = ESPAPIManager()
    var deviceToken: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        // fetch the user pool client we initialized in above step
        storyboard = UIStoryboard(name: "Login", bundle: nil)
        
        setServerParams()
        setESPTokenKeys()
        migrateCode()
        
        VersionManager.shared.checkForAppUpdate()
        ESPNetworkMonitor.shared.startMonitoring()
        DropDown.startListeningToKeyboard()

        // Set tab bar appearance to match theme
        setTabBarAttribute()
        updateUIViewAppearance()

        // Uncomment the next line to see library related logs.
//        ESPProvisionManager.shared.enableLogs(true)

        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Method to set appearance of Tab Bar
    private func setTabBarAttribute() {
        var currentBGColor = UIColor(hexString: "#8265E3")
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        }
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#8265E3")], for: .selected)
        } else {
            UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor], for: .selected)
        }
    }
    
    // Method to set background color of UI components according to App Theme.
    private func updateUIViewAppearance() {
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.uiViewUpdateNotification)))
        var currentBGColor = UIColor(hexString: "#8265E3")
        if let color = AppConstants.shared.appThemeColor {
            PrimaryButton.appearance().backgroundColor = color
            TopBarView.appearance().backgroundColor = color
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                PrimaryButton.appearance().backgroundColor = UIColor(hexString: bgColor)
                TopBarView.appearance().backgroundColor = UIColor(hexString: bgColor)
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            PrimaryButton.appearance().setTitleColor(UIColor(hexString: "#8265E3"), for: .normal)
            BarButton.appearance().setTitleColor(UIColor(hexString: "#8265E3"), for: .normal)
        } else {
            PrimaryButton.appearance().setTitleColor(UIColor.white, for: .normal)
            BarButton.appearance().setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1), for: .normal)
        }
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
