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
//  AppConstants.swift
//  ESPRainMaker
//
//  Created by Vikas Chandra on 30/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import Foundation
import UIKit

class AppConstants {
    let defaultBGColor = "#8265E3"
    static let shared = AppConstants()
    var appThemeColor: UIColor?
    var appBGImage: UIImage?

    private init() {
        appThemeColor = UserDefaults.standard.backgroundColor
        appBGImage = UserDefaults.standard.imageForKey(key: Constants.appBGKey)
    }
    
    func getBGColor() -> UIColor {
        var currentBGColor: UIColor!
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            currentBGColor = UIColor(hexString: defaultBGColor)
        }
        return currentBGColor
    }
    
    
}
