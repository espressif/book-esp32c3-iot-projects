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
//  DeviceControlHelper.swift
//  ESPRainMaker
//

import Foundation

///  Protocol to update listeners about failure in updating params
protocol ParamUpdateProtocol {
    func failureInUpdatingParam()
}

enum DeviceControlHelper {
    static func updateParam(nodeID: String?, parameter: [String: Any], delegate: ParamUpdateProtocol?, completionHandler: ((ESPCloudResponseStatus) -> Void)? = nil) {
        NetworkManager.shared.setDeviceParam(nodeID: nodeID, parameter: parameter) { result in
            switch result {
            case .failure:
                delegate?.failureInUpdatingParam()
            case .success:
                completionHandler?(result)
            default:
                break
            }
        }
    }
}
