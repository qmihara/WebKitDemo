//
//  WebViewController.swift
//  WebKitDemo
//
//  Created by Kyusaku Mihara on 9/17/14.
//  Copyright (c) 2014 epohsoft. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    weak var webView: WKWebView!
    weak var progressView: WebViewProgressView!
    @IBOutlet weak var backBarButton: UIBarButtonItem!
    @IBOutlet weak var forwardBarButton: UIBarButtonItem!
    @IBOutlet weak var stopBarButton: UIBarButtonItem!
    @IBOutlet weak var refreshBarButton: UIBarButtonItem!

    private var keyValueObservations: [NSKeyValueObservation] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.preferences.isElementFullscreenEnabled = true

        let webView = WKWebView(frame: view.bounds, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isFindInteractionEnabled = true
        webView.allowsBackForwardNavigationGestures = false
        keyValueObservations.append(webView.observe(\.isLoading, options: [.new]) { [weak self] _, change in
            guard let isLoading = change.newValue else { return }
            self?.stopBarButton.isEnabled = isLoading
            self?.refreshBarButton.isEnabled = !isLoading
        })
        keyValueObservations.append(webView.observe(\.title, options: [.new]) { [weak self] _, change in
            guard let title = change.newValue else { return }
            self?.navigationItem.title = title
        })
        keyValueObservations.append(webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            guard let progress = change.newValue else { return }
            self?.progressView.setProgress(Float(progress), animated: true)
        })
        keyValueObservations.append(webView.observe(\.canGoBack, options: [.new]) { [weak self] _, change in
            guard let canGoBack = change.newValue else { return }
            self?.backBarButton.isEnabled = canGoBack
        })
        keyValueObservations.append(webView.observe(\.canGoForward, options: [.new]) { [weak self] _, change in
            guard let canGoForward = change.newValue else { return }
            self?.forwardBarButton.isEnabled = canGoForward
        })
        keyValueObservations.append(webView.observe(\.fullscreenState, options: [.new]) { object, _ in
            print("WebView fullscreen state did change:\(object.fullscreenState)")
        })
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        self.webView = webView

        if let navigationBar = navigationController?.navigationBar {
            let progressView = WebViewProgressView()
            progressView.translatesAutoresizingMaskIntoConstraints = false
            navigationBar.addSubview(progressView)
            NSLayoutConstraint.activate([
                progressView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
                progressView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
                progressView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
                progressView.heightAnchor.constraint(equalToConstant: 2)
            ])
            self.progressView = progressView
        }

        webView.load(URLRequest(url: URL(string: "https://duckduckgo.com")!))

        backBarButton.isEnabled = false
        forwardBarButton.isEnabled = false
    }

    @IBAction func backBarButtonTapped(_ sender: AnyObject) {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @IBAction func forwardBarButtonTapped(_ sender: AnyObject) {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    @IBAction func stopBarButtonTapped(_ sender: AnyObject) {
        if webView.isLoading {
            webView.stopLoading()
        }
    }

    @IBAction func refreshBarButtonTapped(_ sender: AnyObject) {
        _ = webView.reload()
    }

    @IBAction func searchBarButtonTapped(_ sender: Any) {
        webView.findInteraction?.presentFindNavigator(showingReplace: false)
    }

    // MARK: - WKNavigationDelegate methods

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        print("webView:\(webView) didStartProvisionalNavigation:\(navigation)")
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
        print("webView:\(webView) didCommitNavigation:\(navigation)")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (@escaping (WKNavigationActionPolicy) -> Void)) {
        print("webView:\(webView) decidePolicyForNavigationAction:\(navigationAction) decisionHandler:\(String(describing: decisionHandler))")

        switch navigationAction.navigationType {
        case .linkActivated:
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
        default:
            break
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: (@escaping (WKNavigationResponsePolicy) -> Void)) {
        print("webView:\(webView) decidePolicyForNavigationResponse:\(navigationResponse) decisionHandler:\(String(describing: decisionHandler))")

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("webView:\(webView) didReceiveAuthenticationChallenge:\(challenge) completionHandler:\(String(describing: completionHandler))")

        switch (challenge.protectionSpace.authenticationMethod) {
        case NSURLAuthenticationMethodHTTPBasic:
            let alertController = UIAlertController(title: "Authentication Required", message: webView.url?.host, preferredStyle: .alert)
            weak var usernameTextField: UITextField!
            alertController.addTextField { textField in
                textField.placeholder = "Username"
                usernameTextField = textField
            }
            weak var passwordTextField: UITextField!
            alertController.addTextField { textField in
                textField.placeholder = "Password"
                textField.isSecureTextEntry = true
                passwordTextField = textField
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                completionHandler(.cancelAuthenticationChallenge, nil)
            }))
            alertController.addAction(UIAlertAction(title: "Log In", style: .default, handler: { action in
                guard let username = usernameTextField.text, let password = passwordTextField.text else {
                    completionHandler(.rejectProtectionSpace, nil)
                    return
                }
                let credential = URLCredential(user: username, password: password, persistence: URLCredential.Persistence.forSession)
                completionHandler(.useCredential, credential)
            }))
            present(alertController, animated: true, completion: nil)
        default:
            completionHandler(.rejectProtectionSpace, nil);
        }
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation) {
        print("webView:\(webView) didReceiveServerRedirectForProvisionalNavigation:\(navigation)")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        print("webView:\(webView) didFinishNavigation:\(navigation)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        print("webView:\(webView) didFailNavigation:\(navigation) withError:\(error)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: Error) {
        print("webView:\(webView) didFailProvisionalNavigation:\(navigation) withError:\(error)")
    }

    // MARK: WKUIDelegate methods
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (@escaping () -> Void)) {
        print("webView:\(webView) runJavaScriptAlertPanelWithMessage:\(message) initiatedByFrame:\(frame) completionHandler:\(String(describing: completionHandler))")
        
        let alertController = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (@escaping (Bool) -> Void)) {
        print("webView:\(webView) runJavaScriptConfirmPanelWithMessage:\(message) initiatedByFrame:\(frame) completionHandler:\(String(describing: completionHandler))")
        
        let alertController = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            completionHandler(false)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler(true)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        print("webView:\(webView) runJavaScriptTextInputPanelWithPrompt:\(prompt) defaultText:\(String(describing: defaultText)) initiatedByFrame:\(frame) completionHandler:\(String(describing: completionHandler))")
        
        let alertController = UIAlertController(title: frame.request.url?.host, message: prompt, preferredStyle: .alert)
        weak var alertTextField: UITextField!
        alertController.addTextField { textField in
            textField.text = defaultText
            alertTextField = textField
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            completionHandler(nil)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler(alertTextField.text)
        }))
        present(alertController, animated: true, completion: nil)
    }

}

extension WKWebView.FullscreenState: CustomDebugStringConvertible {
    public var debugDescription: String {
        let text: String
        switch self {
        case .notInFullscreen:
            text = "notInFullscreen"
        case .enteringFullscreen:
            text = "enteringFullscreen"
        case .inFullscreen:
            text = "inFullscreen"
        case .exitingFullscreen:
            text = "exitingFullscreen"
        @unknown default:
            text = "unknown"
        }
        return "\(text)(\(rawValue))"
    }
}
