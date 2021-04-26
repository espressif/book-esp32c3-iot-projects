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
//  UILabel+GetViewHeight.swift
//  ESPRainMaker
//

import Foundation
import UIKit

extension UILabel {
    
    func getNameViewHeight(height: CGFloat, width: CGFloat) -> CGFloat {
        var result = 0.0
        let singleLineHeight = "*".getViewHeight(labelWidth: width, font: self.font)
        var actualLineHeight = "*".getViewHeight(labelWidth: width, font: self.font)
        if let text = self.text {
            actualLineHeight = text.getViewHeight(labelWidth: width, font: self.font)
        }
        if actualLineHeight > singleLineHeight {
            let diff = actualLineHeight - singleLineHeight
            result = height + diff
        } else {
            result = 46.0
        }
        return result
    }
}
