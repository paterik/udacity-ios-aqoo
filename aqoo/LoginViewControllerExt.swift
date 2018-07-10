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

    func renewTokenAndShowLandingPage() {
        
        spotifyClient.spfAuth.renewSession(spotifyClient.spfCurrentSession) { error, session in
            
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
        
        //
        // lets start with users playlistView
        //
        
        performSegue(withIdentifier: _defaultLandingPageSegueId, sender: self)
    }
    
    func getAuthViewController(withURL url: URL) -> UIViewController {
        
        let webView = WebViewController(url: url)
            webView.delegate = self
        
        return UINavigationController(rootViewController: webView)
    }
    
    @objc
    func updateAfterCancelLogin() {
        
        self.presentedViewController?.dismiss(animated: true, completion: { self.setupUILoginControls() })
    }
    
    @objc
    func updateAfterSuccessLogin(_ notification: NSNotification?) {
        
        if  spotifyClient.isSpotifyTokenValid() {
            showLandingPage()
            
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
        
        btnSpotifyLogin.isEnabled =  _tokenIsValid
        btnSpotifyLogin.isEnabled = !_tokenIsValid
        
        lblSpotifySessionStatus.text = "NOT CONNECTED"
        imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusLocked_v1")
        spotifyClient.spfIsLoggedIn = false
        
        if _tokenIsValid == true {
            spotifyClient.spfIsLoggedIn = true
            lblSpotifySessionStatus.text = "CONNECTED"
            imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusConnected_v1")
        }
    }
    
    func webViewControllerDidFinish(_ controller: WebViewController) { }

}
