//
//  WebViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 19.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import PKHUD
import WebKit
import GradientLoadingBar

@objc
protocol WebViewControllerDelegate {
    func webViewControllerDidFinish(_ controller: WebViewController)
    @objc optional func webViewController(_ controller: WebViewController, didCompleteInitialLoad didLoadSuccessfully: Bool)
}

class WebViewController: UIViewController, UIWebViewDelegate {
    
    var loadComplete: Bool = false
    var initialURL: URL!
    var webView: UIWebView!
    var delegate: WebViewControllerDelegate?
    var webViewGradientLoadingBar = GradientLoadingBar()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let initialRequest = URLRequest(url: initialURL)
        
        // prepare main HUD settings
        HUD.dimsBackground = false
        HUD.allowsInteraction = false
        HUD.flash(.label("connect to spotify"), delay: 2.175)
        
        webView = UIWebView(frame: view.bounds)
        webView.delegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(webView)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(done)
        )
        
        webViewGradientLoadingBar = GradientLoadingBar(
            height: 5,
            durations: Durations(fadeIn: 0.975, fadeOut: 1.375, progress: 2.725),
            gradientColorList: [
                UIColor(netHex: 0x1ED760), // 0x1ED760 | 0x4CD964
                UIColor(netHex: 0xff2D55)  // 0xff2D55 | 0xff2D55
            ],
            onView: webView
        );  webViewGradientLoadingBar.show()
        
        webView.loadRequest(initialRequest)
    }
    
    @objc
    func done() {
        
        delegate?.webViewControllerDidFinish(self)
        presentingViewController?.dismiss(animated: true)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        if !self.loadComplete {
            delegate?.webViewController?(self, didCompleteInitialLoad: true)
            loadComplete = true
            HUD.flash(.label("connected"), delay: 1.175)
            webViewGradientLoadingBar.hide()
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
        if !self.loadComplete {
            
            delegate?.webViewController?(self, didCompleteInitialLoad: true)
            loadComplete = true
        }
    }
    
    init(url URL: URL) {
        
        super.init(nibName: nil, bundle: nil)
        initialURL = URL as URL!
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
}
