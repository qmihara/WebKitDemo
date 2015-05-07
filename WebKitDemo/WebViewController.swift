//
//  WebViewController.swift
//  WebKitDemo
//
//  Created by Kyusaku Mihara on 9/17/14.
//  Copyright (c) 2014 epohsoft. All rights reserved.
//

import UIKit
import WebKit

var myContext = 0

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    weak var webView: WKWebView?
    weak var progressView: WebViewProgressView?
    @IBOutlet weak var backBarButton: UIBarButtonItem!
    @IBOutlet weak var forwardBarButton: UIBarButtonItem!
    @IBOutlet weak var stopBarButton: UIBarButtonItem!
    @IBOutlet weak var refreshBarButton: UIBarButtonItem!

    deinit {
        self.webView?.removeObserver(self, forKeyPath: "loading")
        self.webView?.removeObserver(self, forKeyPath: "title")
        self.webView?.removeObserver(self, forKeyPath: "estimatedProgress")
        self.webView?.removeObserver(self, forKeyPath: "canGoBack")
        self.webView?.removeObserver(self, forKeyPath: "canGoForward")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let webViewConfiguration = WKWebViewConfiguration()

        let webView = WKWebView(frame: self.view.bounds, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        webView.UIDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        webView.addObserver(self, forKeyPath: "loading", options: .New, context: &myContext)
        webView.addObserver(self, forKeyPath: "title", options: .New, context: &myContext)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: &myContext)
        webView.addObserver(self, forKeyPath: "canGoBack", options: .New, context: &myContext)
        webView.addObserver(self, forKeyPath: "canGoForward", options: .New, context: &myContext)
        self.view.addSubview(webView)
        self.webView = webView

        let navigationBarBounds = self.navigationController?.navigationBar.bounds
        let progressView = WebViewProgressView(frame: CGRectMake(0, navigationBarBounds!.size.height - 2, navigationBarBounds!.size.width, 2))
        progressView.autoresizingMask = .FlexibleWidth | .FlexibleTopMargin
        self.navigationController?.navigationBar.addSubview(progressView)
        self.progressView = progressView

        webView.loadRequest(NSURLRequest(URL: NSURL(string: "https://www.google.co.jp")!))

        self.backBarButton.enabled = false
        self.forwardBarButton.enabled = false
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context != &myContext {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }

        if keyPath == "loading" {
            if let loading = change[NSKeyValueChangeNewKey]?.boolValue {
                self.stopBarButton?.enabled = loading
                self.refreshBarButton?.enabled = !loading
            }
            return
        }

        if keyPath == "title" {
            if let title = change[NSKeyValueChangeNewKey] as? String {
                self.navigationItem.title = title
            }
            return
        }

        if keyPath == "estimatedProgress" {
            if let progress = change[NSKeyValueChangeNewKey]?.floatValue {
                self.progressView?.setProgress(progress, animated: true)
            }
            return
        }
        
        if keyPath == "canGoBack" {
            if let canGoBack = change[NSKeyValueChangeNewKey]?.boolValue {
                self.backBarButton.enabled = canGoBack
            }
            return
        }
        
        if keyPath == "canGoForward" {
            if let canGoForward = change[NSKeyValueChangeNewKey]?.boolValue {
                self.forwardBarButton.enabled = canGoForward
            }
            return
        }
    }

    @IBAction func backBarButtonTapped(sender: AnyObject) {
        if self.webView!.canGoBack {
            self.webView!.goBack()
        }
    }

    @IBAction func forwardBarButtonTapped(sender: AnyObject) {
        if self.webView!.canGoForward {
            self.webView!.goForward()
        }
    }

    @IBAction func stopBarButtonTapped(sender: AnyObject) {
        if self.webView!.loading {
            self.webView!.stopLoading()
        }
    }

    @IBAction func refreshBarButtonTapped(sender: AnyObject) {
        self.webView?.reload()
    }

    // MARK: - WKNavigationDelegate methods

    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        println("webView:\(webView) didStartProvisionalNavigation:\(navigation)")
    }

    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation) {
        println("webView:\(webView) didCommitNavigation:\(navigation)")
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        println("webView:\(webView) decidePolicyForNavigationAction:\(navigationAction) decisionHandler:\(decisionHandler)")

        let url = navigationAction.request.URL

        switch navigationAction.navigationType {
        case .LinkActivated:
            if navigationAction.targetFrame == nil {
                self.webView?.loadRequest(navigationAction.request)
            }
        default:
            break
        }

        decisionHandler(.Allow)
    }

    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: ((WKNavigationResponsePolicy) -> Void)) {
        println("webView:\(webView) decidePolicyForNavigationResponse:\(navigationResponse) decisionHandler:\(decisionHandler)")

        decisionHandler(.Allow)
    }

    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
        println("webView:\(webView) didReceiveAuthenticationChallenge:\(challenge) completionHandler:\(completionHandler)")

        let alertController = UIAlertController(title: "Authentication Required", message: webView.URL?.host, preferredStyle: .Alert)
        weak var usernameTextField: UITextField!
        alertController.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = "Username"
            usernameTextField = textField
        }
        weak var passwordTextField: UITextField!
        alertController.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            passwordTextField = textField
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
            completionHandler(.CancelAuthenticationChallenge, nil)
        }))
        alertController.addAction(UIAlertAction(title: "Log In", style: .Default, handler: { action in
            let credential = NSURLCredential(user: usernameTextField.text, password: passwordTextField.text, persistence: NSURLCredentialPersistence.ForSession)
            completionHandler(.UseCredential, credential)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation) {
        println("webView:\(webView) didReceiveServerRedirectForProvisionalNavigation:\(navigation)")
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation) {
        println("webView:\(webView) didFinishNavigation:\(navigation)")
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation, withError error: NSError) {
        println("webView:\(webView) didFailNavigation:\(navigation) withError:\(error)")
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: NSError) {
        println("webView:\(webView) didFailProvisionalNavigation:\(navigation) withError:\(error)")
    }

    // MARK: WKUIDelegate methods
    
    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (() -> Void)) {
        println("webView:\(webView) runJavaScriptAlertPanelWithMessage:\(message) initiatedByFrame:\(frame) completionHandler:\(completionHandler)")
        
        let alertController = UIAlertController(title: frame.request.URL?.host, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            completionHandler()
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: ((Bool) -> Void)) {
        println("webView:\(webView) runJavaScriptConfirmPanelWithMessage:\(message) initiatedByFrame:\(frame) completionHandler:\(completionHandler)")
        
        let alertController = UIAlertController(title: frame.request.URL?.host, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
            completionHandler(false)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            completionHandler(true)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String!) -> Void) {
        println("webView:\(webView) runJavaScriptTextInputPanelWithPrompt:\(prompt) defaultText:\(defaultText) initiatedByFrame:\(frame) completionHandler:\(completionHandler)")
        
        let alertController = UIAlertController(title: frame.request.URL?.host, message: prompt, preferredStyle: .Alert)
        weak var alertTextField: UITextField!
        alertController.addTextFieldWithConfigurationHandler { textField in
            textField.text = defaultText
            alertTextField = textField
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
            completionHandler(nil)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            completionHandler(alertTextField.text)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }

}
