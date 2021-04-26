// Copyright 2022 Espressif Systems
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
//  ESPSceneConstants.swift
//  ESPRainMaker
//

import Foundation

class ESPSceneConstants {
    
    //MARK: constant strings:
    static let nodeIdKey = "node_id"
    static let payloadKey = "payload"
    static let saveSceneFailureMessage: String = "Failed to save scene for"
    static let partialDeleteSceneFailureMessage: String = "Failed to delete scene for"
    static let deleteSceneFailureMessage: String = "Failed to delete scene"
    static let partialActivateSceneFailureMessage: String = "Failed to activate scene for"
    static let activateSceneSuccessMessage: String = "Scene activated successfully"
    static let activateSceneFailureMessage: String = "Failed to activate scene"
    static let failedToUpdateErrorMessage: String = "Failed to update scene"
    static let nameNotAddedErrorMessage: String = "Please enter a name for the scene to proceed."
    
    static let sceneAddedSuccessMessage: String = "Scene added successfully"
    static let sceneUpdatedSuccessMessage: String = "Scene updated successfully"
    static let sceneDeletedSuccessMessage: String = "Scene deleted successfully"
    
}
