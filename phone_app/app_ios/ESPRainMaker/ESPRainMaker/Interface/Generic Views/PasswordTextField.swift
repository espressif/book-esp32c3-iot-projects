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
//  PasswordTextField.swift
//  ESPRainMaker
//

import UIKit

class PasswordTextField: UITextField {
    var tapGesture: UITapGestureRecognizer!
    let passwordImageRightView = UIImageView(frame: CGRect(x: 0, y: 0, width: 22.0, height: 16.0))
    let passwordButton = UIButton(frame: CGRect(x: 0, y: 0, width: 22.0, height: 16.0))

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        passwordButton.setImage(UIImage(named: "show_password"), for: .normal)
        rightView = passwordButton
        rightViewMode = .always
        passwordButton.addTarget(self, action: #selector(showPasswordTapped), for: .touchUpInside)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)
        rect.origin.x = rect.origin.x - 16
        return rect
    }

    @objc func showPasswordTapped() {
        togglePasswordVisibility()
        if passwordButton.image(for: .normal) == UIImage(named: "show_password") {
            passwordButton.setImage(UIImage(named: "hide_password"), for: .normal)
        } else {
            passwordButton.setImage(UIImage(named: "show_password"), for: .normal)
        }
    }
}
