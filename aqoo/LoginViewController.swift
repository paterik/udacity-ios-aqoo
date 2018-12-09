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

    //
    // MARK: Class IBOutlet definitions
    //
    
    @IBOutlet weak var imgSpotifyStatus: UIImageView!
    @IBOutlet weak var btnSpotifyLogin: UIButton!
    @IBOutlet weak var btnSpotifyLogout: UIButton!
    @IBOutlet weak var lblSpotifySessionStatus: UILabel!
    
    //
    // MARK: Class Variables
    //
    
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
        
        appDelegate.restrictRotation = .portrait
        
        setupUILoginControls()
        
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
    
    //
    // MARK: Class IABaction Methods
    //
    
    @IBAction func btnSpotifyLoginAction(_ sender: SPTConnectButton) {

        if SPTAuth.supportsApplicationAuthentication() {
            
            UIApplication.shared.open( spotifyClient.spfLoginUrl!, options: [:], completionHandler: nil)
            
        }   else {
            
            authViewController = getAuthViewController(withURL: spotifyClient.spfLoginUrl!)
            definesPresentationContext = true
            present(self.authViewController!, animated: true)
        }
    }
    
    @IBAction func btnSpotifyLogoutAction(_ sender: Any) {
        
        spotifyClient.closeSpotifySession()
        setupUILoginControls()
    }
    
    @IBAction func unwindToLoginView(segue:UIStoryboardSegue) {
        
        spotifyClient.closeSpotifySession()
        setupUILoginControls()
    }
}

