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
//  DocumentViewController.swift
//  ESPRainMaker
//

import UIKit
import WebKit

class DocumentViewController: UIViewController {
    var documentLink: String!
    @IBOutlet var webView: WKWebView!
    @IBOutlet var backButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        if let documentURL = URL(string: documentLink) {
            webView.load(URLRequest(url: documentURL))
        } else {
            Utility.showToastMessage(view: view, message: "Webpage URL is incorrect or invalid.", duration: 4.0)
        }
    }

    @IBAction func backButtonPressed(_: Any) {
        webView.goBack()
    }

    @IBAction func closeWebView(_: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension DocumentViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            guard let url = navigationAction.request.url else { return }
            webView.load(URLRequest(url: url))
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        if webView.canGoBack {
            backButton.isHidden = false
        } else {
            backButton.isHidden = true
        }
    }
}
