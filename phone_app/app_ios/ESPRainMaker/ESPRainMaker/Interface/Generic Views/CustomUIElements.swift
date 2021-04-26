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
//  TopBarView.swift
//  ESPRainMaker
//

import UIKit

class TopBarView: UIView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        borderWidth = 1.0
        borderColor = UIColor.lightGray
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
        if let color = AppConstants.shared.appThemeColor {
            backgroundColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                backgroundColor = UIColor(hexString: bgColor)
            }
        }
    }
}

class PrimaryButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        cornerRadius = 10.0
        borderWidth = 1.0
        borderColor = UIColor.lightGray
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
        var currentBGColor = UIColor(hexString: "#8265E3")
        if let color = AppConstants.shared.appThemeColor {
            setTitleColor(color, for: .normal)
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                backgroundColor = UIColor(hexString: bgColor)
                currentBGColor = backgroundColor!
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            backgroundColor = UIColor(hexString: "#8265E3")
        } else {
            backgroundColor = .white
        }
    }
}

class SecondaryButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
        var currentBGColor = UIColor(hexString: "#8265E3")
        if let color = AppConstants.shared.appThemeColor {
            setTitleColor(color, for: .normal)
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                setTitleColor(UIColor(hexString: bgColor), for: .normal)
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            setTitleColor(UIColor(hexString: "#8265E3"), for: .normal)
        }
    }
}

class RemoveScheduleButton: UIButton {
    
    let removeThemeColor = "#F45C10"
    let removeBackgroundColor = "#FFECE4"

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layer.borderWidth = CGFloat(2.0)
        self.layer.borderColor = UIColor(hexString: removeThemeColor).cgColor
        self.layer.cornerRadius = CGFloat(10.0)
        self.backgroundColor = UIColor(hexString: removeBackgroundColor)
        self.setTitleColor(UIColor(hexString: removeThemeColor), for: .normal)
    }
}

class BGImageView: UIImageView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentMode = .scaleAspectFill
        backgroundColor = .clear
        if let appBGImage = AppConstants.shared.appBGImage {
            image = appBGImage
        }
    }

    override func setNeedsDisplay() {
        if let appBGImage = AppConstants.shared.appBGImage {
            image = appBGImage
        } else {
            image = nil
        }
    }
}

class BarButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
        var currentBGColor: UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            setTitleColor(UIColor(hexString: "#8265E3"), for: .normal)
        } else {
            setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1), for: .normal)
        }
    }
}

class BarTitle: UILabel {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
        var currentBGColor: UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            textColor = UIColor.black
        } else {
            textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        }
    }
}

// Class that enables copying text on UILabel
class SelectableLabel: UILabel {
    // MARK: - Setup

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextSelection()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTextSelection()
    }

    private func setupTextSelection() {
        layer.addSublayer(selectionOverlay)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
        addGestureRecognizer(longPress)
        isUserInteractionEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(didHideMenu), name: UIMenuController.didHideMenuNotification, object: nil)
    }

    private let selectionOverlay: CALayer = {
        let layer = CALayer()
        layer.cornerRadius = 8
        layer.backgroundColor = UIColor.black.withAlphaComponent(0.14).cgColor
        layer.isHidden = true
        return layer
    }()

    // MARK: - Showing and hiding the menu

    private func cancelSelection() {
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }

    @objc private func didHideMenu(_: Notification) {
        selectionOverlay.isHidden = true
    }

    @objc private func didLongPress(_: UILongPressGestureRecognizer) {
        guard let text = text, !text.isEmpty else { return }
        becomeFirstResponder()

        let menu = menuForSelection()
        if !menu.isMenuVisible {
            selectionOverlay.isHidden = false
            menu.setTargetRect(textRect(), in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    private func textRect() -> CGRect {
        let inset: CGFloat = -4
        return textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).insetBy(dx: inset, dy: inset)
    }

    private func menuForSelection() -> UIMenuController {
        let menu = UIMenuController.shared
        menu.menuItems = [
            UIMenuItem(title: "Copy", action: #selector(copyText)),
        ]
        return menu
    }

    // MARK: - Menu item actions

    @objc private func copyText(_: Any?) {
        cancelSelection()
        let board = UIPasteboard.general
        board.string = text
        _ = resignFirstResponder()
    }

    // MARK: - UIView overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        selectionOverlay.frame = textRect()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func resignFirstResponder() -> Bool {
        cancelSelection()
        return super.resignFirstResponder()
    }
}
