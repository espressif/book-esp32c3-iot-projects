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
//  ExtensionManager.swift
//  ESPRainMaker
//
//  Created by Vikas Chandra on 29/12/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

extension UISegmentedControl {
    func removeBorder() {
        let backgroundImage = UIImage.getColoredRectImageWith(color: UIColor.clear.cgColor, andSize: bounds.size)
        setBackgroundImage(backgroundImage, for: .normal, barMetrics: .default)
        setBackgroundImage(backgroundImage, for: .selected, barMetrics: .default)
        setBackgroundImage(backgroundImage, for: .highlighted, barMetrics: .default)

        let deviderImage = UIImage.getColoredRectImageWith(color: UIColor.clear.cgColor, andSize: CGSize(width: 1.0, height: bounds.size.height))
        setDividerImage(deviderImage, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        let defaultAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor(red: 90.0 / 255.0, green: 38.0 / 255.0, blue: 192.0 / 255.0, alpha: 1.0),
        ]
        setTitleTextAttributes(defaultAttributes, for: .normal)
        setTitleTextAttributes(defaultAttributes, for: .selected)
    }

    func addUnderlineForSelectedSegment() {
        removeBorder()
        let underlineWidth: CGFloat = UIScreen.main.bounds.size.width / CGFloat(numberOfSegments)
        let underlineHeight: CGFloat = 4.0
        let underlineXPosition = CGFloat(selectedSegmentIndex * Int(underlineWidth))
        let underLineYPosition = bounds.size.height - 1.0
        let underlineFrame = CGRect(x: underlineXPosition + (underlineWidth - 100) / 2.0, y: underLineYPosition, width: 100, height: underlineHeight)
        let underline = UIView(frame: underlineFrame)
        underline.backgroundColor = UIColor(red: 83 / 255, green: 48 / 255, blue: 185 / 255, alpha: 1.0)
        underline.tag = 1
        addSubview(underline)
    }

    func changeUnderlineColor(color: UIColor) {
        guard let underline = viewWithTag(1) else { return }
        underline.backgroundColor = color
    }

    func changeUnderlinePosition() {
        guard let underline = viewWithTag(1) else { return }
        let underlineFinalXPosition = (UIScreen.main.bounds.size.width / CGFloat(numberOfSegments)) * CGFloat(selectedSegmentIndex)
        let underlineWidth: CGFloat = UIScreen.main.bounds.size.width / CGFloat(numberOfSegments)
        UIView.animate(withDuration: 0.1, animations: {
            underline.frame.origin.x = underlineFinalXPosition + (underlineWidth - 100) / 2.0
        })
    }
}

extension UIImage {
    class func getColoredRectImageWith(color: CGColor, andSize size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let graphicsContext = UIGraphicsGetCurrentContext()
        graphicsContext?.setFillColor(color)
        let rectangle = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        graphicsContext?.fill(rectangle)
        let rectangleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rectangleImage!
    }
}

extension UITextField {
    func setBottomBorder(color: CGColor = UIColor(red: 255.0 / 255.0, green: 97.0 / 255.0, blue: 99.0 / 255.0, alpha: 1.0).cgColor) {
        borderStyle = .none
        layer.backgroundColor = UIColor.clear.cgColor

        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: frame.height - 1, width: frame.width, height: 1.0)
        bottomLine.backgroundColor = color
        borderStyle = UITextField.BorderStyle.none
        layer.addSublayer(bottomLine)
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

extension UITextField {
    func togglePasswordVisibility() {
        isSecureTextEntry = !isSecureTextEntry

        if let existingText = text, isSecureTextEntry {
            /* When toggling to secure text, all text will be purged if the user
             continues typing unless we intervene. This is prevented by first
             deleting the existing text and then recovering the original text. */
            deleteBackward()

            if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
                replace(textRange, withText: existingText)
            }
        }

        /* Reset the selected text range since the cursor can end up in the wrong
         position after a toggle because the text might vary in width */
        if let existingSelectedTextRange = selectedTextRange {
            selectedTextRange = nil
            selectedTextRange = existingSelectedTextRange
        }
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as? UIViewController
            }
        }
        return nil
    }
}

extension UserDefaults {
    func set(_ color: UIColor?, forKey defaultName: String) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard let color = color, color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        else {
            removeObject(forKey: defaultName)
            return
        }
        let count = MemoryLayout<CGFloat>.size
        set(Data(bytes: &red, count: count) +
            Data(bytes: &green, count: count) +
            Data(bytes: &blue, count: count) +
            Data(bytes: &alpha, count: count), forKey: defaultName)
    }

    func color(forKey defaultName: String) -> UIColor? {
        guard let data = data(forKey: defaultName) else {
            return nil
        }
        let size = MemoryLayout<CGFloat>.size
        return UIColor(red: data[size * 0 ..< size * 1].withUnsafeBytes { $0.load(as: CGFloat.self) },
                       green: data[size * 1 ..< size * 2].withUnsafeBytes { $0.load(as: CGFloat.self) },
                       blue: data[size * 2 ..< size * 3].withUnsafeBytes { $0.load(as: CGFloat.self) },
                       alpha: data[size * 3 ..< size * 4].withUnsafeBytes { $0.load(as: CGFloat.self) })
    }
}

extension UserDefaults {
    var backgroundColor: UIColor? {
        get {
            return color(forKey: Constants.appThemeKey)
        }
        set {
            set(newValue, forKey: Constants.appThemeKey)
        }
    }

    func imageForKey(key: String) -> UIImage? {
        var image: UIImage?
        if let imageData = data(forKey: key) {
            image = NSKeyedUnarchiver.unarchiveObject(with: imageData) as? UIImage
        }
        return image
    }

    func setImage(image: UIImage?, forKey key: String) {
        var imageData: NSData?
        if let image = image {
            imageData = NSKeyedArchiver.archivedData(withRootObject: image) as NSData?
        }
        set(imageData, forKey: key)
    }
}

extension UIView {
    func rotate360Degrees(duration: CFTimeInterval = 6) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = Float.infinity
        layer.add(rotateAnimation, forKey: nil)
    }
}

extension UIDatePicker {
    func setDate(from string: String, format: String, animated: Bool = true) {
        let formater = DateFormatter()

        formater.dateFormat = format

        let date = formater.date(from: string) ?? Date()

        setDate(date, animated: animated)
    }
}

extension Array {
    func insertionIndexOf(_ elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}

extension UIView {
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 10

        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}

extension Date {
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
}

extension UIView {
    /* Usage Example
     * bgView.addBottomRoundedEdge(desiredCurve: 1.5)
     */
    func addBottomRoundedEdge(desiredCurve: CGFloat?) {
        let offset: CGFloat = frame.width / desiredCurve!
        let bounds: CGRect = self.bounds

        let rectBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.size.width, height: bounds.size.height / 2)
        let rectPath = UIBezierPath(rect: rectBounds)
        let ovalBounds = CGRect(x: bounds.origin.x - offset / 2, y: bounds.origin.y, width: bounds.size.width + offset, height: bounds.size.height)
        let ovalPath = UIBezierPath(ovalIn: ovalBounds)
        rectPath.append(ovalPath)

        // Create the shape layer and set its path
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = rectPath.cgPath

        // Set the newly created shape layer as the mask for the view's layer
        layer.mask = maskLayer
    }
}

struct JSONCodingKeys: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any]? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: [Any].Type, forKey key: K) throws -> [Any]? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decode(_: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode([String: Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_: [Any].Type) throws -> [Any] {
        var array: [Any] = []
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first and prevent infite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode([String: Any].self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode([Any].self) {
                array.append(nestedArray)
            }
        }
        return array
    }

    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}

extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        // let textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
        // (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)

        // let locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
        // locationOfTouchInLabel.y - textContainerOffset.y);
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

extension String {
    func getDomain() -> String {
        let url = URL(string: self)
        return url?.host ?? ""
    }
}

extension UIViewController {
    
    func showErrorAlert(title: String, message: String, buttonTitle: String, callback: @escaping () -> Void) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: buttonTitle, style: .default, handler: {_ in
            callback()
        })
        alertController.addAction(dismissAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func handleError(error: ESPAPIError?, buttonTitle: String) {
        if let err = error {
            var title = "Error"
            var message = ""
            switch err {
            case .serverError(let serverError):
                if let text = (serverError as NSError).userInfo["__type"] as? String {
                    title = text
                }
                if let text = (serverError as NSError).userInfo["message"] as? String {
                    message = text
                }
            case.errorCode(_ ,let desc):
                message = desc
            default:
                break
            }
            let alertController = UIAlertController(title: title,
                                                    message: message,
                                                    preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension ESPNoRefreshTokenLogic {
    
    /// Clear user data on logging out
    func clearUserData() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.disablePlatformApplicationARN()
        UIApplication.shared.unregisterForRemoteNotifications()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        ESPTokenWorker.shared.deleteAll()
        ESPAlexaTokenWorker.shared.clearAllClientTokens()
        UserDefaults.standard.removeObject(forKey: Constants.wifiPassword)
        let localStorageHandler = ESPLocalStorageHandler()
        localStorageHandler.cleanupData()
        NodeGroupManager.shared.nodeGroups = []
        NodeSharingManager.shared.sharingRequestsSent = []
        NodeSharingManager.shared.sharingRequestsReceived = []
        User.shared.accessToken = nil
        User.shared.userInfo = UserInfo(username: "", email: "", userID: "", loggedInWith: .cognito)
        User.shared.associatedNodeList = nil
    }
    
    /// Is sign in view controller presented currently
    /// - Returns: true if sign in VC is present, false if absent
    func isSigninViewControllerPresented() -> Bool {
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            if tabBarController.selectedIndex == 0 {
                if let nav = tabBarController.selectedViewController as? UINavigationController, let top = nav.topViewController?.presentedViewController as? UINavigationController {
                    let vcs = top.viewControllers
                    if vcs.count > 0, let _ = vcs[0] as? SignInViewController {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    /// Present sign in view controller on the top view controller
    func presentSigninViewController() {
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            if let vcs = tabBarController.viewControllers, vcs.count > 0 {
                tabBarController.selectedIndex = 0
                let storyboard = UIStoryboard(name: "Login", bundle: nil)
                if let nav = storyboard.instantiateViewController(withIdentifier: "signInController") as? UINavigationController {
                    if let _ = nav.viewControllers.first as? SignInViewController {
                        nav.modalPresentationStyle = .fullScreen
                        tabBarController.present(nav, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    /// Sign out user if refresh token is absent
    /// - Parameter error: error
    func noRefreshSignOutUser(error: ESPAPIError) {
        switch error {
        case .errorCode(let errorCode, _):
            if ESPErrorCodeDescription.logOutUserCodes.contains(errorCode) {
                self.signOut()
            }
        default:
            break
        }
        self.clearUserData()
        DispatchQueue.main.async {
            if self.isSigninViewControllerPresented() {
                return
            }
            self.presentSigninViewController()
        }
    }
    
    /// Call sign out user
    func signOut() {
        let service = ESPLogoutService(presenter: nil)
        service.logoutUser()
    }
    
    /// Validate API response to check if the user exists and there is no issue with the user session
    /// - Parameter response: API response data
    /// - Returns: true is user session is valid and false if invalid
    func validateDataResponse(response: AFDataResponse<Data>) -> Bool  {
        var result = true
        switch response.result {
        case .success(let value):
            if let espResponse = try? JSONDecoder().decode(ESPSessionResponse.self, from: value) {
                if espResponse.status?.lowercased() == "failure" {
                    if let description = espResponse.description, description.lowercased() == "unauthorized" {
                        result = false
                    } else if let errorCode = espResponse.errorCode {
                        let code = "\(errorCode)"
                        if ESPErrorCodeDescription.logOutUserCodes.contains(code) {
                            result = false
                        }
                    }
                }
            }
        default:
            break
        }
        if !result {
            validateRefreshToken()
        }
        return result
    }
    
    /// Validate API response to check if the user exists and there is no issue with the user session
    /// - Parameter response: API response JSON
    /// - Returns: true is user session is valid and false if invalid
    func validateJSONResponse(response: AFDataResponse<Any>) -> Bool {
        var result = true
        switch response.result {
        case .success(let value):
            if let value = value as? [String: Any] {
                if let status = value["status"] as? String, status.lowercased() == "failure" {
                    if let description = value["description"] as? String, description.lowercased() == "unauthorized" {
                        result = false
                    } else if let errorCode = value["error_code"] as? Int {
                        let code = "\(errorCode)"
                        if ESPErrorCodeDescription.logOutUserCodes.contains(code) {
                            result = false
                        }
                    }
                }
            }
        default:
            break
        }
        if !result {
            validateRefreshToken()
        }
        return result
    }
    
    /*
     Clear access token and try to fetch new access token using refresh token
     */
    private func validateRefreshToken() {
        ESPTokenWorker.shared.delete(key: Constants.accessTokenKey)
        let service = ESPExtendUserSessionWorker()
        service.checkUserSession() { _, error in
            if let serverError = error {
                let parser = ESPAPIParser()
                if !parser.isRefreshTokenValid(serverError: serverError) {
                    self.clearDataAndPresentSignInVC()
                }
            }
        }
    }
    
    /*
     Clear user data and sign out of the app.
     Navigate to devices screen and present sign in screen.
     */
    private func clearDataAndPresentSignInVC() {
        self.clearUserData()
        DispatchQueue.main.async {
            if !self.isSigninViewControllerPresented() {
                self.presentSigninViewController()
            }
        }
    }
}
