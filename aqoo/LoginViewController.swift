//
//  LoginViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class LoginViewController: BaseViewController, WebViewControllerDelegate {

    @IBOutlet weak var imgLoginLock: UIImageView!
    @IBOutlet weak var btnSpotifyLogin: UIButton!
    @IBOutlet weak var btnSpotifyLogout: UIButton!
    @IBOutlet weak var lblSpotifySessionStatus: UILabel!
    
    var authViewController: UIViewController?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.updateAfterSuccessLogin),
            name: NSNotification.Name(rawValue: appDelegate.spfSessionRequestSuccessNotifierId),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.updateAfterCancelLogin),
            name: NSNotification.Name(rawValue: appDelegate.spfSessionRequestCanceledNotifierId),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
    
        if isSpotifyTokenValid() {
            
            lblSpotifySessionStatus.text = "STILL CONNECTED"
            
            showLandingPage()
        
        } else {
            
            if appDelegate.spfAuth.hasTokenRefreshService {
        
                lblSpotifySessionStatus.text = "REFRESH TOKEN"
                
                renewTokenAndShowLandingPage()
            }
        }
    }
    
    func renewTokenAndShowLandingPage() {
        
        appDelegate.spfAuth.renewSession(appDelegate.spfCurrentSession) { error, session in
            
            SPTAuth.defaultInstance().session = session
            if error != nil {
                self.lblSpotifySessionStatus.text = "REFRESH TOKEN FAIL"
                print("_dbg: error renewing session: \(error!.localizedDescription)")
                return
            }
            
            self.showLandingPage()
        }
    }
    
    func showLandingPage() {
    
        performSegue(withIdentifier: "showLandingPage", sender: nil)
    }
    
    func getAuthViewController(withURL url: URL) -> UIViewController {

        let webView = WebViewController(url: url)
            webView.delegate = self
        
        return UINavigationController(rootViewController: webView)
    }
    
    func webViewControllerDidFinish(_ controller: WebViewController) { }
    
    func updateAfterCancelLogin() {
        
        self.presentedViewController?.dismiss(animated: true, completion: { _ in self.setupUILoginControls() })
    }
    
    func updateAfterSuccessLogin() {

        if isSpotifyTokenValid() {
            
            showLandingPage()
            
        } else { _handleErrorAsDialogMessage("Spotify Login Fail!", "Oops! I'm unable to verify valid authentication for this account!")}
        
        self.presentedViewController?.dismiss(animated: true, completion: { _ in self.setupUILoginControls() })
    }
    
    func setupUILoginControls() {
        
        let _tokenIsValid = isSpotifyTokenValid()
        
        btnSpotifyLogin.isEnabled =  _tokenIsValid
        btnSpotifyLogin.isEnabled = !_tokenIsValid
        
        lblSpotifySessionStatus.text = "NOT CONNECTED"
        if _tokenIsValid {
            lblSpotifySessionStatus.text = "LOGGED IN"
        }
    }
    
    @IBAction func btnSpotifyLoginAction(_ sender: SPTConnectButton) {
        
        if SPTAuth.supportsApplicationAuthentication() {
            
            UIApplication.shared.open(appDelegate.spfLoginUrl!, options: [:], completionHandler: nil)
            
        }   else {
            
            self.authViewController = self.getAuthViewController(withURL: appDelegate.spfLoginUrl!)
            self.definesPresentationContext = true
            self.present(self.authViewController!, animated: true, completion: { _ in })
        }
    }
    
    @IBAction func btnSpotifyLogoutAction(_ sender: Any) {
        
        let storage = HTTPCookieStorage.shared
        let userDefaults = UserDefaults.standard
        let sessionData = NSKeyedArchiver.archivedData(withRootObject: "")
        
        userDefaults.set(sessionData, forKey: appDelegate.spfSessionUserDefaultsKey)
        userDefaults.synchronize()
        
        for cookie: HTTPCookie in storage.cookies! {
            
            if  (cookie.domain as NSString).range(of: "spotify."  ).length > 0 ||
                (cookie.domain as NSString).range(of: "facebook." ).length > 0 {
                
                storage.deleteCookie(cookie)
            }
        }
    }
}

