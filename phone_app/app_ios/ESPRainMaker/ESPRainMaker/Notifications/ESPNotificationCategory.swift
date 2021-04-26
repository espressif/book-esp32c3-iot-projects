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
//  ESPNotificationCategory.swift
//  ESPRainMaker
//

import Foundation
import UIKit

// Enum containing different notification categories.
enum ESPNotificationCategory: String {
    case addSharing = "ADD_SHARING"
}

// Add Sharing Catgory with actions.
enum ESPNotificationsAddSharingCategory: String {
    // Possible actions for this category.
    case accept
    case decline
    
    // Method to add actions to the add node sharing notification category.
    static func addCategory() {
        let acceptAction = UNNotificationAction(identifier: ESPNotificationsAddSharingCategory.accept.rawValue, title: "Accept", options: .foreground)
        let declineActions = UNNotificationAction(identifier: ESPNotificationsAddSharingCategory.decline.rawValue, title: "Decline", options: .destructive)
        
        let sharingRequestCategory = UNNotificationCategory(identifier: ESPNotificationCategory.addSharing.rawValue, actions: [acceptAction, declineActions], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
        let notficationCentre = UNUserNotificationCenter.current()
        notficationCentre.setNotificationCategories([sharingRequestCategory])
    }
}
