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
//  DeviceAssociation.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation
import SwiftProtobuf

enum AssociationError: Error {
    case runtimeError(String)

    var description: String {
        switch self {
        case let .runtimeError(message):
            return message
        }
    }
}

protocol DeviceAssociationProtocol {
    func deviceAssociationFinishedWith(success: Bool, nodeID: String?, error: AssociationError?)
}

class DeviceAssociation {
    let secretKey: String

    var delegate: DeviceAssociationProtocol?
    var device: ESPDevice

    /// Create DeviceAssociation object that sends configuration data
    /// Required for sending data related to assoicating device with app user
    ///
    /// - Parameters:
    ///   - session: Initialised session object
    ///   - secretId: a unique key to authenticate user-device mapping
    init(secretId: String, device: ESPDevice) {
        secretKey = secretId
        self.device = device
    }

    /// Method to start user device mapping
    /// Info like userID and secretKey are sent from user to device
    ///
    func associateDeviceWithUser() {
        do {
            let payloadData = try createAssociationConfigRequest()

            if let data = payloadData {
                device.sendData(path: Constants.associationPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        self.delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil, error: AssociationError.runtimeError(error!.localizedDescription))
                        return
                    }
                    self.processResponse(responseData: response!)
                }
            } else {
                delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil, error: AssociationError.runtimeError("Unable to fetch request payload."))
            }
        } catch {
            delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil, error: AssociationError.runtimeError("Unable to fetch request payload."))
        }
    }

    /// Prcocess response to check status of mapping
    /// Info like userID and secretKey are sent from user to device
    ///
    /// - Parameters:
    ///   - responseData: Response recieved from device after sending mapping payload
    func processResponse(responseData: Data) {
        do {
            let response = try Rainmaker_RMakerConfigPayload(serializedData: responseData)
            if response.respSetUserMapping.status == .success {
                delegate?.deviceAssociationFinishedWith(success: true, nodeID: response.respSetUserMapping.nodeID, error: nil)
            } else {
                delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil, error: AssociationError.runtimeError("User node mapping failed."))
            }
        } catch {
            delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil, error: AssociationError.runtimeError(error.localizedDescription))
        }
    }

    /// Method to convert device association payload into encrypted data
    /// This info is sent to device
    ///
    private func createAssociationConfigRequest() throws -> Data? {
        var configRequest = Rainmaker_CmdSetUserMapping()
        configRequest.secretKey = secretKey
        configRequest.userID = User.shared.userInfo.userID
        var payload = Rainmaker_RMakerConfigPayload()
        payload.msg = Rainmaker_RMakerConfigMsgType.typeCmdSetUserMapping
        payload.cmdSetUserMapping = configRequest
        return try payload.serializedData()
    }
}
