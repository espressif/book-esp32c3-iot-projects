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
//  ESPNodeSharingAddEvent+Actions.swift
//  ESPRainMaker
//

import Foundation
import UIKit

extension ESPNodeSharingAddEvent {
    func handleAction(_ actionIdentifier: String) {
        var navigationHandler = UserNavigationHandler.notificationViewController
        switch ESPNotificationsAddSharingCategory(rawValue: actionIdentifier) {
        case .accept:
            if let requestID = eventData[ESPNotificationKeys.requestIDKey] as? String {
                let parameter: [String: Any] = ["confirm_sharing": true, "request_id": requestID]
                NodeSharingManager.shared.updateSharing(parameter: parameter) { success, error in
                    DispatchQueue.main.async {
                        User.shared.updateDeviceList = true
                        navigationHandler = .homeScreen
                        navigationHandler.navigateToPage()
                    }
                }
            }
        case .decline:
            if let requestID = eventData[ESPNotificationKeys.requestIDKey] as? String {
                let parameter: [String: Any] = ["confirm_sharing": false, "request_id": requestID]
                NodeSharingManager.shared.updateSharing(parameter: parameter) { success, error in
                }
            }
        case .none:
            navigationHandler = .notificationViewController
            navigationHandler.navigateToPage()
        }
    }
}
