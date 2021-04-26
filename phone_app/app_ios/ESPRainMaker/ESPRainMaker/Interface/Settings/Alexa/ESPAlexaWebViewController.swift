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
//  ESPAlexaWebViewController.swift
//  ESPRainMaker
//

import UIKit
import WebKit

/// Protocol defines functions to be invoked when code is extracted from url or error occurred
protocol ESPAlexaWebViewDelegate: AnyObject {
    
    func extractCode(url: String, state: ESPEnableSkillState)
    func errorOccurred(message: String)
}

/// View controller to show WKWebview for login to Amazon, link Alexa skill 
class ESPAlexaWebViewController: UIViewController {
    
    static let storyboardId = "ESPAlexaWebViewController"
    @IBOutlet weak var webView: WKWebView!
    var skillState: ESPEnableSkillState = .none
    weak var delegate: ESPAlexaWebViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
    }
    
    /// Clear WKWebview cookies
    func clearCookies() {
        WKWebView.clean()
    }
    
    /// Launch WKWebiew
    /// - Parameters:
    ///   - url: url to be loaded with WKWebview
    ///   - state: enable skill state
    ///   - presenter: viewcontroller the webview is invoked from
    func launchWebview(url: URL, state: ESPEnableSkillState, presenter: UIViewController) {
        self.skillState = state
        self.webView.load(URLRequest(url: url))
    }
    
    /// WKWebview cancelled
    /// - Parameter sender: sender
    @IBAction func cancelClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ESPAlexaWebViewController: WKNavigationDelegate {
    
    /// WKWebiew navigation started callback
    /// - Parameters:
    ///   - webView: WKWebView for loading URL
    ///   - navigation: navigation description
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
    }
    
    /// WKWebiew navigation finished callback
    /// - Parameters:
    ///   - webView: WKWebView for loading URL
    ///   - navigation: navigation description
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            if let url = webView.url {
                if url.absoluteString.hasPrefix(
                    Configuration.shared.espAlexaConfiguration.redirectURI) {
                    self.dismiss(animated: true, completion: {
                        self.delegate?.extractCode(url: url.absoluteString, state: self.skillState)
                    })
                }
            }
        }
    }
    
    /// WKWebiew navigation failed callback
    /// - Parameters:
    ///   - webView: WKWebView for loading URL
    ///   - navigation: navigation description
    ///   - error: error occurred for navigation
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            print(error.localizedDescription)
            self.dismiss(animated: true, completion: {
                self.delegate?.errorOccurred(message: error.localizedDescription)
            })
        }
    }
}

extension WKWebView {
    /// Clear cache and cookies for WKWebsiteDataStore
    class func clean() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
}
