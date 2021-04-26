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
//  ESPPresenter.swift
//  ESPRainMaker
//

import Foundation
import UIKit

protocol ESPUserPresentationLogic {
    func userDetailsFetched(error: ESPAPIError?)
}

protocol ESPLoginPresentationLogic {
    func loginCompleted(withError error: ESPAPIError?)
}

protocol ESPExtendSessionPresentationLogic {
    func sessionValidated(withError error: ESPAPIError?)
}

protocol ESPCreateUserPresentationLogic {
    func verifyUser(withName name: String, andPassword password: String, withError error: ESPAPIError?)
    func userVerified(withError error: ESPAPIError?)
}

protocol ESPForgotPasswordPresentationLogic {
    func requestedForgotPassword(withError error: ESPAPIError?)
    func confirmForgotPassword(withError error: ESPAPIError?)
}

protocol ESPChangePasswordPresentationLogic {
    func passwordChanged(withError error: ESPAPIError?)
}

protocol ESPLogoutUserPresentationLogic {
    func userLoggedOut(withError error: ESPAPIError?)
}

protocol ESPIdProviderLoginPresenter {
    func loginFailed()
    func loginSuccess(requestToken: RequestToken)
}
