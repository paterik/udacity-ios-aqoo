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

    var authViewController: UIViewController?
    
    let _player = SPTAudioStreamingController.sharedInstance()
    let sampleSong: String = "spotify:track:3rkge8kur9i26zpByFKvBu"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        mnuTopStatus.title = "TOKEN INVALID"
        if  isSpotifyTokenValid() {
            mnuTopStatus.title = "CONNECTED"
            handleNewSession()
            print("dbg: session => \(appDelegate.spfCurrentSession!.accessToken!)")
        }
    }

    override var prefersStatusBarHidden: Bool { return true }
    
    func handleNewSession() {
        
        if (_player?.loggedIn)! { return }
        
        do {
            
            try _player?.start(
                withClientId: appDelegate.spfAuth.clientID,
                audioController: nil,
                allowCaching: true
            )
            
            _player?.delegate = self
            _player?.playbackDelegate = self
            _player?.diskCache = SPTDiskCache()
            _player?.login(withAccessToken: appDelegate.spfCurrentSession!.accessToken!)
            
        } catch let error {
            
            let alert = UIAlertController(title: "Error Init Player", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: { _ in self.closeSpotifySession() })
        }
    }
    
    func closeSession() {
        
        do {
            
            try _player?.stop()
                 closeSpotifySession()
            
            _ = self.navigationController!.popViewController(animated: true)
            
        } catch let error {
            
            let alert = UIAlertController(title: "Error Closing Player", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: { _ in self.closeSpotifySession() })
        }
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        //
        // if you close this view, your spotify session will be closed (!!!)
        //
        // closeSession()
        
        _ = self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func btnSpotifyCallAction(_ sender: Any) {
        
        print ("btnSpotifyCallAction()")
    }
}
