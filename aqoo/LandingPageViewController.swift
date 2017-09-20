//
//  LandingPageViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class LandingPageViewController: BaseViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    @IBOutlet weak var mnuTopStatus: UINavigationItem!
    @IBOutlet weak var btnSpotifyCall: UIButton!
    @IBOutlet weak var btnExitLandingPage: UIBarButtonItem!

    var player: SPTAudioStreamingController?
    var authViewController: UIViewController?
    
    let sampleSong: String = "spotify:track:3rkge8kur9i26zpByFKvBu"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        handleNewSession()
        
        mnuTopStatus.title = "TOKEN INVALID"
        if  isSpotifyTokenValid() {
            mnuTopStatus.title = "CONNECTED"
            
            print("dbg: session => \(appDelegate.spfCurrentSession!.accessToken!)")
        }
    }

    override var prefersStatusBarHidden: Bool { return true }
    
    func handleNewSession() {
        
        do {
            
            try SPTAudioStreamingController.sharedInstance().start(
                withClientId: appDelegate.spfAuth.clientID,
                audioController: nil,
                allowCaching: true
            )
            
            SPTAudioStreamingController.sharedInstance().delegate = self
            SPTAudioStreamingController.sharedInstance().playbackDelegate = self
            SPTAudioStreamingController.sharedInstance().diskCache = SPTDiskCache()
            SPTAudioStreamingController.sharedInstance().login(withAccessToken: appDelegate.spfCurrentSession!.accessToken!)
            
        } catch let error {
            
            let alert = UIAlertController(title: "Error init", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: { _ in self.closeSpotifySession() })
        }
    }
    
    func closeSession() {
        
        do {
            
            try SPTAudioStreamingController.sharedInstance().stop()
            
                closeSpotifySession()
            
            _ = self.navigationController!.popViewController(animated: true)
            
        } catch let error {
            
            let alert = UIAlertController(title: "Error Closing Streaming", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: { _ in self.closeSpotifySession() })
        }
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        _ = self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func btnSpotifyCallAction(_ sender: Any) {
        
        closeSession()
    }
}
