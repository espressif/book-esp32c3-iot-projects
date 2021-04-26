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
//  ESPNotificationKeys.swift
//  ESPRainMaker
//

import Foundation

// Notification payload keys.
struct ESPNotificationKeys {
    static let apsKey = "aps"
    static let alertkey = "alert"
    static let titleKey = "title"
    static let bodyKey = "body"
    static let eventDataPayloadKey = "event_data_payload"
    static let timestampKey = "timestamp"
    static let eventDataKey = "event_data"
    static let eventTypeKey = "event_type"
    static let nodeIDKey = "node_id"
    static let messageBodyKey = "message_body"
    static let primaryUserNameKey = "primary_user_name"
    static let secondaryUserNameKey = "secondary_user_name"
    static let metadataKey = "metadata"
    static let devicesKeys = "devices"
    static let nameKey = "name"
    static let nodesKey = "nodes"
    static let acceptKey = "accept"
    static let connectivityKey = "connectivity"
    static let connectedKey = "connected"
}
