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
//  ESPExtendSessionService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPExtendSessionLogic {
    func validateUserSession()
}

class ESPExtendSessionService: ESPExtendSessionLogic {
    
    var tokenWorker: ESPTokenWorker
    var presenter: ESPExtendSessionPresentationLogic?
    
    convenience init(presenter: ESPExtendSessionPresentationLogic? = nil) {
        self.init(tokenWorker: ESPTokenWorker.shared,
                  presenter: presenter)
    }
    
    private init(tokenWorker: ESPTokenWorker,
         presenter: ESPExtendSessionPresentationLogic? = nil) {
        self.tokenWorker = tokenWorker
        self.presenter = presenter
    }
    
    /// Check if user is logged in or not
    func validateUserSession() {
        if let _ = self.tokenWorker.refreshTokenString {
            self.presenter?.sessionValidated(withError: nil)
        } else {
            self.presenter?.sessionValidated(withError: .noRefreshToken)
        }
    }
}


