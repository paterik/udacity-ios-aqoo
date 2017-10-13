//
//  WebViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 19.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import WebKit

@objc protocol WebViewControllerDelegate {
    func webViewControllerDidFinish(_ controller: WebViewController)
    @objc optional func webViewController(_ controller: WebViewController, didCompleteInitialLoad didLoadSuccessfully: Bool)
}

class WebViewController: UIViewController, UIWebViewDelegate {
    
    var loadComplete: Bool = false
    var initialURL: URL!
    var webView: UIWebView!
    var delegate: WebViewControllerDelegate?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let initialRequest = URLRequest(url: initialURL)
        
        webView = UIWebView(frame: view.bounds)
        webView.delegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(webView)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        webView.loadRequest(initialRequest)
    }
    
    @objc func done() {
        
        delegate?.webViewControllerDidFinish(self)
        presentingViewController?.dismiss(animated: true)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        if !self.loadComplete {
            delegate?.webViewController?(self, didCompleteInitialLoad: true)
            loadComplete = true
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
