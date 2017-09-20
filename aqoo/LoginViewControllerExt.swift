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
        
        performSegue(withIdentifier: segueIdentLandingPage, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // handlie landingPage segue
        if segue.identifier == segueIdentLandingPage {
            let controller = segue.destination as! LandingPageViewController
            self.show(controller, sender: self)
        }
    }
    
    func getAuthViewController(withURL url: URL) -> UIViewController {
        
        let webView = WebViewController(url: url)
            webView.delegate = self
        
        return UINavigationController(rootViewController: webView)
    }
    
    func updateAfterCancelLogin() {
        
        self.presentedViewController?.dismiss(animated: true, completion: { _ in self.setupUILoginControls() })
    }
    
    func updateAfterSuccessLogin() {
        
        if isSpotifyTokenValid() {
            
            showLandingPage()
            
        } else {
            
           _handleErrorAsDialogMessage("Spotify Login Fail!", "Oops! I'm unable to verify valid authentication for this account!")
        }
        
        self.presentedViewController?.dismiss(animated: true, completion: { _ in self.setupUILoginControls() })
    }
    
    func setupUILoginControls() {
        
        let _tokenIsValid = isSpotifyTokenValid()
        
        btnSpotifyLogin.isEnabled =  _tokenIsValid
        btnSpotifyLogin.isEnabled = !_tokenIsValid
        
        lblSpotifySessionStatus.text = "NOT CONNECTED"
        imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusLocked_v1")
        if _tokenIsValid {
            lblSpotifySessionStatus.text = "CONNECTED"
            imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusConnected_v1")
        }
    }
    
    func webViewControllerDidFinish(_ controller: WebViewController) { }

}
