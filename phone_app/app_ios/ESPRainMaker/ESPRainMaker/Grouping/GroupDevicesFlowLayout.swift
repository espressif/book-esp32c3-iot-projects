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
//  GroupDevicesFlowLayout.swift
//  ESPRainMaker
//

import UIKit

class GroupDevicesFlowLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        self.minimumLineSpacing = 20.0
        self.minimumInteritemSpacing = 20.0
        let width = UIScreen.main.bounds.width
        var cellWidth: CGFloat = 0
        if width > 450 {
            cellWidth = (width - 60) / 3.0
        } else {
            cellWidth = (width - 60) / 2.0
        }
        self.itemSize = CGSize(width: cellWidth, height: 110.0)
        self.sectionInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.minimumLineSpacing = 20.0
        self.minimumInteritemSpacing = 20.0
        let width = UIScreen.main.bounds.width
        var cellWidth: CGFloat = 0
        if width > 450 {
            cellWidth = (width - 60) / 3.0
        } else {
            cellWidth = (width - 60) / 2.0
        }
        self.itemSize = CGSize(width: cellWidth, height: 110.0)
        self.sectionInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }

}

