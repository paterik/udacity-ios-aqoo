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

    @IBOutlet weak var imgSpotifyStatus: UIImageView!
    @IBOutlet weak var btnSpotifyLogin: UIButton!
    @IBOutlet weak var btnSpotifyLogout: UIButton!
    @IBOutlet weak var lblSpotifySessionStatus: UILabel!
    
    var authViewController: UIViewController?
    
    //
    // MARK: Class Special Constants
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.updateAfterSuccessLogin),
            name: NSNotification.Name(rawValue: spotifyClient.notifier.notifySessionRequestSuccess),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.updateAfterCancelLogin),
            name: NSNotification.Name(rawValue: spotifyClient.notifier.notifySessionRequestCanceled),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        setupUILoginControls()
        
        if  spotifyClient.spfEnforceSessionKill == true {
            return
        }
    
        if  spotifyClient.isSpotifyTokenValid() {

            lblSpotifySessionStatus.text = "CONNECTED"
            showAppLandingPage()
        
        } else {
            
            if  spotifyClient.spfAuth.hasTokenRefreshService {
        
                lblSpotifySessionStatus.text = "REFRESH TOKEN"
                renewTokenAndShowAppLandingPage() 
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    @IBAction func btnSpotifyLoginAction(_ sender: SPTConnectButton) {

        if SPTAuth.supportsApplicationAuthentication() {
            
            UIApplication.shared.open( spotifyClient.spfLoginUrl!, options: [:], completionHandler: nil)
            
        }   else {
            
            self.authViewController = self.getAuthViewController(withURL: spotifyClient.spfLoginUrl!)
            self.definesPresentationContext = true
            self.present(self.authViewController!, animated: true)
        }
    }
    
    @IBAction func btnSpotifyLogoutAction(_ sender: Any) {
        
        spotifyClient.closeSpotifySession()
    }
}

