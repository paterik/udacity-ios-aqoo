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
    
    var auth = SPTAuth.defaultInstance()!
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var authViewController: UIViewController?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.updateAfterFirstLogin),
            name: NSNotification.Name(rawValue: "sessionUpdated"),
            object: nil
        )
    }
    
    func getAuthViewController(withURL url: URL) -> UIViewController {

        let webView = WebViewController(url: url)
            webView.delegate = self
        
        return UINavigationController(rootViewController: webView)
    }
    
    func webViewControllerDidFinish(_ controller: WebViewController) {
        // User tapped the close button. Treat as auth error
        print ("_webViewControllerDidFinish")
    }
    
    func updateAfterFirstLogin () {

        print ("_updateAfterFirstLogin")
        
        btnSpotifyLogin.isHidden = false
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            session = firstTimeSession
            
            initializePlayer(authSession: session)
            btnSpotifyLogin.isHidden = true
        }
        
        self.presentedViewController?.dismiss(animated: true, completion: { _ in })
        
        if session != nil && session.isValid() {

            print ("!!! SUCCESS !!!")
            
        }   else {
            
            print("*** Failed to log in")
            btnSpotifyLogin.isHidden = false
        }
    }
    
    func initializePlayer(authSession:SPTSession) {
        
        print ("_initializePlayer")
        
        if self.player == nil {
            
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        
        print ("_audioStreamingDidLogin")
        
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        self.player?.playSpotifyURI("spotify:track:58s6EuEYJdlb0kO7awm3Vp", startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing => spotify:track:58s6EuEYJdlb0kO7awm3Vp")
            }
        })
    }
    
    @IBAction func btnSpotifyLoginAction(_ sender: SPTConnectButton) {
        
        print ("_btnSpotifyLoginAction")
        
        if SPTAuth.supportsApplicationAuthentication() {
            UIApplication.shared.open(appDelegate.spfLoginUrl!, options: [:], completionHandler: nil)
        } else {
            self.authViewController = self.getAuthViewController(withURL: appDelegate.spfLoginUrl!)
            self.definesPresentationContext = true
            self.present(self.authViewController!, animated: true, completion: { _ in })
        }
    }
    
    @IBAction func btnSpotifyLogoutAction(_ sender: Any) {
        
        let storage = HTTPCookieStorage.shared
        for cookie: HTTPCookie in storage.cookies! {
            if (cookie.domain as NSString).range(of: "spotify.").length > 0 || (cookie.domain as NSString).range(of: "facebook.").length > 0 {
                storage.deleteCookie(cookie)
            }
        }
    }
}

