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
        
        let initialRequest = URLRequest(url: self.initialURL)
        
        self.webView = UIWebView(frame: self.view.bounds)
        self.webView.delegate = self
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.view.addSubview(self.webView)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.done))
        
        self.webView.loadRequest(initialRequest)
    }
    
    func done() {
        
        print ("\n_done ... exit the webView\n")
        
        self.delegate?.webViewControllerDidFinish(self)
        self.presentingViewController?.dismiss(animated: true, completion: { _ in })
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        print ("_webViewDidFinishLoad")
        
        if !self.loadComplete {
            delegate?.webViewController?(self, didCompleteInitialLoad: true)
            self.loadComplete = true
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
        if !self.loadComplete {
            
            delegate?.webViewController?(self, didCompleteInitialLoad: true)
            self.loadComplete = true
        }
    }
    
    init(url URL: URL) {
        
        super.init(nibName: nil, bundle: nil)
        self.initialURL = URL as URL!
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
}
