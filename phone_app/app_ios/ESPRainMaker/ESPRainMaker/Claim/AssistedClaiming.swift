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
//  AssistedClaiming.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation

class AssistedClaiming {
    var device: ESPDevice!
    var csrData: Data!
    var certificateData: Data!
    var datacount = 1

    init(espDevice: ESPDevice) {
        device = espDevice
        csrData = nil
        certificateData = nil
    }

    /// Start the process of assisted claiming from iOS
    ///
    /// - Parameters:
    ///   - completionHandler: block invoked will contain the result of claiming process and error if claim process fails.
    func initiateAssistedClaiming(completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let payloadData = try createClaimStartRequest()
            if let data = payloadData {
                device.sendData(path: Constants.claimPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        switch error {
                        case let .sendDataError(dataError as NSError):
                            if dataError.domain == "com.espressif.ble", dataError.code == 1 {
                                completionHandler(false, "BLE characteristic related with claiming cannot be found.")
                            } else {
                                fallthrough
                            }
                        default:
                            completionHandler(false, "Sending claim start request to device failed with error:\(error!.localizedDescription)")
                        }
                        return
                    }
                    self.readDeviceInfo(responseData: response!, completionHandler: completionHandler)
                }
            } else {
                completionHandler(false, "Failed to generate payload data for sending claim start request to device.")
            }
        } catch {
            completionHandler(false, "Generating claim start request throws exception:\(error.localizedDescription)")
        }
    }

    private func getCSRFromDevice(response: Data?, completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            var payloadData: Data!
            if csrData == nil {
                payloadData = try createClaimInitRequest(response: response!)
            } else {
                payloadData = try createSubsequentRequest()
            }
            if let data = payloadData {
                device.sendData(path: Constants.claimPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        completionHandler(false, "Failed to get CSR from device with error:\(error!.description)")
                        return
                    }
                    self.processCSRResponse(response: response!, completionHandler: completionHandler)
                }
            } else {
                completionHandler(false, "Failed to generate payload data for sending claim init response to device.")
            }
        } catch {
            completionHandler(false, "Generating claim init request throws exception:\(error.localizedDescription)")
        }
    }

    private func sendCertificateToDevice(completionHandler: @escaping (Bool, String?) -> Void, offset: Int = 0) {
        do {
            var payload: Data!
            if offset + datacount > certificateData.count {
                payload = certificateData.subdata(in: Range(offset ... certificateData.count - 1))
            } else {
                payload = certificateData.subdata(in: Range(offset ... offset + datacount - 1))
            }
            let payloadData = try createClaimVerifyRequest(data: payload, offset: offset)
            if let data = payloadData {
                device.sendData(path: Constants.claimPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        completionHandler(false, "Failed to send certificated to device with error:\(error!.description)")
                        return
                    }
                    if offset + self.datacount >= self.certificateData.count {
                        completionHandler(true, nil)
                    } else {
                        self.sendCertificateToDevice(completionHandler: completionHandler, offset: offset + self.datacount)
                    }
                }
            } else {
                completionHandler(false, "Failed to generate payload data for sending certificate to device.")
            }
        } catch {
            completionHandler(false, "Generating claim verify request throws exception:\(error.localizedDescription)")
        }
    }

    private func abortDevice(message: String, completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let payloadData = try createClaimAbortRequest()
            if let data = payloadData {
                device.sendData(path: Constants.claimPath, data: data) { _, _ in
                    completionHandler(false, message)
                }
            } else {
                completionHandler(false, message)
            }
        } catch {
            completionHandler(false, message)
        }
    }

    // MARK: - Claim API Calls

    private func sendDeviceInfoToCloud(response: [String: Any], completionHandler: @escaping (Bool, String?) -> Void) {
        NetworkManager.shared.genericAuthorizedDataRequest(url: Constants.claimInitPath, parameter: response) { data, error in
            if data == nil {
                completionHandler(false, "Error while sending device info to cloud:\(error!.description)")
                return
            }
            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: String] {
                    if let status = responseJSON["status"] {
                        if status.lowercased() == "failure" {
                            var failDescription = "Claim init failed"
                            if let description = responseJSON["description"] {
                                failDescription = description
                            }
                            self.abortDevice(message: failDescription, completionHandler: completionHandler)
                            return
                        }
                    }
                }
                self.getCSRFromDevice(response: data!, completionHandler: completionHandler)
            } catch {
                completionHandler(false, "Serializing response of request to send device info to cloud throws exception:\(error.localizedDescription)")
            }
        }
    }

    private func sendCSRToAPI(completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let response = try JSONSerialization.jsonObject(with: csrData, options: .allowFragments) as? [String: String] ?? [:]
            NetworkManager.shared.genericAuthorizedDataRequest(url: Constants.claimVerifyPath, parameter: response) { data, error in
                if data == nil {
                    completionHandler(false, "Error while sending CSR to cloud:\(error!.description)")
                    return
                }
                do {
                    if let responseJSON = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: String] {
                        if let status = responseJSON["status"] {
                            if status.lowercased() == "failure" {
                                var failDescription = "Claim verify failed"
                                if let description = responseJSON["description"] {
                                    failDescription = description
                                }
                                self.abortDevice(message: failDescription, completionHandler: completionHandler)
                                return
                            }
                        }
                    }
                    self.certificateData = data!
                    self.sendCertificateToDevice(completionHandler: completionHandler, offset: 0)
                } catch {
                    completionHandler(false, "Serializing response of request to send CSR to cloud throws exception:\(error.localizedDescription)")
                }
            }
        } catch {
            completionHandler(false, "Serializing CSR data to send as paramater throws exception:\(error.localizedDescription)")
        }
    }

    // MARK: - Process Response

    private func readDeviceInfo(responseData: Data, completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let response = try RmakerClaim_RMakerClaimPayload(serializedData: responseData)
            if response.respPayload.status == .success {
                sendDeviceInfoToCloud(response: try (JSONSerialization.jsonObject(with: response.respPayload.buf.payload, options: .allowFragments) as? [String: Any] ?? [:]), completionHandler: completionHandler)
            } else {
                completionHandler(false, "Failure sending claim start request to device with status:\(response.respPayload.status)")
            }
        } catch {
            completionHandler(false, "Serializing response of claim start request to device throws exception:\(error.localizedDescription)")
        }
    }

    private func processCSRResponse(response: Data, completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let response = try RmakerClaim_RMakerClaimPayload(serializedData: response)
            if response.respPayload.status == .success {
                let payload = response.respPayload.buf
                if payload.offset == 0 {
                    datacount = payload.payload.count
                    csrData = payload.payload
                } else {
                    csrData.append(payload.payload)
                }
                if csrData.count >= payload.totalLen {
                    sendCSRToAPI(completionHandler: completionHandler)
                } else {
                    getCSRFromDevice(response: nil, completionHandler: completionHandler)
                }
            } else {
                completionHandler(false, "Failure getting CSR from device with status:\(response.respPayload.status)")
            }
        } catch {
            completionHandler(false, "Serializing CSR response from device throws exception:\(error.localizedDescription)")
        }
    }

    // MARK: - Create request payload

    private func createClaimStartRequest() throws -> Data? {
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimStart
        payload.cmdPayload = RmakerClaim_PayloadBuf()
        return try payload.serializedData()
    }

    private func createClaimInitRequest(response: Data) throws -> Data? {
        var payloadBuf = RmakerClaim_PayloadBuf()
        payloadBuf.offset = 0
        payloadBuf.totalLen = UInt32(response.count)
        payloadBuf.payload = response
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimInit
        payload.cmdPayload = payloadBuf
        return try payload.serializedData()
    }

    private func createSubsequentRequest() throws -> Data? {
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimInit
        payload.cmdPayload = RmakerClaim_PayloadBuf()
        return try payload.serializedData()
    }

    private func createClaimVerifyRequest(data: Data, offset: Int) throws -> Data? {
        var payloadBuf = RmakerClaim_PayloadBuf()
        payloadBuf.offset = UInt32(offset)
        payloadBuf.totalLen = UInt32(certificateData.count)
        payloadBuf.payload = data
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimVerify
        payload.cmdPayload = payloadBuf
        return try payload.serializedData()
    }

    private func createClaimAbortRequest() throws -> Data? {
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimAbort
        return try payload.serializedData()
    }
}
