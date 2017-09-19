//
//  LoginViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class LoginViewController:  BaseViewController,
                            SPTAudioStreamingPlaybackDelegate,
                            SPTAudioStreamingDelegate,
                            WebViewControllerDelegate {

    @IBOutlet weak var imgLoginLock: UIImageView!
    @IBOutlet weak var btnSpotifyLogin: UIButton!
    @IBOutlet weak var btnSpotifyLogout: UIButton!
    @IBOutlet weak var lblSpotifySessionStatus: UILabel!
    
    var currentSession: SPTSession!
    var player: SPTAudioStreamingController?
    var authViewController: UIViewController?
    
    let sampleSong: String = "spotify:track:3rkge8kur9i26zpByFKvBu"
    
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

        if  isSpotifyTokenValid() {
            initializePlayer(authSession: currentSession)
            
        } else { _handleErrorAsDialogMessage("Spotify Login Fail!", "Oops! I'm unable to verify valid authentication for this account!")}
        
        self.presentedViewController?.dismiss(animated: true, completion: { _ in self.setupUILoginControls() })
    }
    
    func initializePlayer(authSession: SPTSession) {
        
        if player != nil { return }
        
        player = SPTAudioStreamingController.sharedInstance()
        player!.delegate = self
        player!.playbackDelegate = self
            
        try! player!.start(withClientId: appDelegate.spfAuth.clientID)
        
        player!.login(withAccessToken: authSession.accessToken)
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        
        self.player!.playSpotifyURI(sampleSong, startingWith: 0, startingWithPosition: 0, callback: {
            
            error in
            
            if (error == nil) {
                print ("playing => \(self.sampleSong)")
            }   else {
                print ("_dbg: error while playing sample track \(self.sampleSong)")
            }
        })
    }
    
    func isSpotifyTokenValid() -> Bool {
    
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: appDelegate.spfSessionUserDefaultsKey) as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            currentSession = firstTimeSession
            
            return currentSession != nil && currentSession.isValid()
        }
        
        return false
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
        
        for cookie: HTTPCookie in storage.cookies! {
            
            if  (cookie.domain as NSString).range(of: "spotify."  ).length > 0 ||
                (cookie.domain as NSString).range(of: "facebook." ).length > 0 {
                
                storage.deleteCookie(cookie)
            }
        }
    }
}

