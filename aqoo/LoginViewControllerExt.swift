//
//  LoginViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 20.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

extension LoginViewController {

    func renewTokenAndShowAppLandingPage() {
        
        spotifyClient.spfAuth.renewSession(spotifyClient.spfCurrentSession!) { error, session in
            
            SPTAuth.defaultInstance().session = session
            if  error != nil {
                self.lblSpotifySessionStatus.text = "REFRESH TOKEN FAIL"
                
                return
            }
            
            self.showAppLandingPage()
        }
    }
    
    func showAppLandingPage() {
        
        //
        // reset sessionKillSwitch and start with landingPage (playlistView :: "showAllUserPlaylists")
        //
        
        spotifyClient.spfEnforceSessionKill == false
        
        performSegue(withIdentifier: _defaultLandingPageSegueId, sender: self)
    }
    
    func getAuthViewController(withURL url: URL) -> UIViewController {
        
        let spotifyWebView = WebViewController(url: url)
            spotifyWebView.delegate = self
        
        return UINavigationController(rootViewController: spotifyWebView)
    }
    
    @objc
    func updateAfterCancelLogin() {
        
        self.presentedViewController?.dismiss(animated: true, completion: { self.setupUILoginControls() })
    }
    
    @objc
    func updateAfterSuccessLogin(_ notification: NSNotification?) {
        
        if  spotifyClient.isSpotifyTokenValid() {
            
            showAppLandingPage()
            
        }   else {
            
            handleErrorAsDialogMessage(
                "Spotify Login Fail!",
                "Oops! I'm unable to verify valid authentication for your spotify account!"
            )
        }
        
        self.presentedViewController?.dismiss(animated: true, completion: { self.setupUILoginControls() })
    }
    
    func setupUILoginControls() {
        
        let _tokenIsValid = spotifyClient.isSpotifyTokenValid()
        
        btnSpotifyLogin.isEnabled =  !_tokenIsValid
        
        lblSpotifySessionStatus.text = "NOT CONNECTED"
        imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusLocked_v1")
        spotifyClient.spfIsLoggedIn = false
        
        if _tokenIsValid == true {
            spotifyClient.spfIsLoggedIn = true
            lblSpotifySessionStatus.text = "CONNECTED"
            imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusConnected_v1")
        }
    }
    
    //
    // this function register all global available timer based event
    // up for now I'll use this to check device connetion state to the
    // web only ...
    //
    func setupUIGlobalTimerEvents() {
        
        if  connectionCheckTimer != nil {
            connectionCheckTimer.invalidate()
        }
        
        // start connection check timer
        connectionCheckTimer = Timer.scheduledTimer(
            timeInterval : TimeInterval(_sysConnectionCheckTimerInterval),
            target       : self,
            selector     : #selector(handleConnectivityCheck),
            userInfo     : nil,
            repeats      : true
        )
    }
    
    @objc
    func handleConnectivityCheck() {
     
        var statusVerb: String = "undefined"
        
        DFNetworkManager.isReachable { networkManagerInstance in
            statusVerb = "pass"
        }
        
        DFNetworkManager.isUnreachable { networkManagerInstance in
            statusVerb = "fail"
            self.handleErrorAsDialogMessage(
                "Spotify Connection Fail!",
                "Oops! I'm unable connect to public network - please check your connections settings"
            )
        }
        
        // disabled ... to noisy ;)
        /*
         if  self.debugMode == true {
            print ("dbg [login/con] : connection check ➡ \(statusVerb)")
         }
         */
    }
    
    func webViewControllerDidFinish(_ controller: WebViewController) { }

}
