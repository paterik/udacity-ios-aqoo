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
    
    @IBOutlet weak var btnSpotifyCall: UIButton!
    @IBOutlet weak var btnExitLandingPage: UIBarButtonItem!

    var player: SPTAudioStreamingController?
    var authViewController: UIViewController?
    
    let sampleSong: String = "spotify:track:3rkge8kur9i26zpByFKvBu"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
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

    @IBAction func btnExitLandingPageAction(_ sender: Any) {
    
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnSpotifyCallAction(_ sender: Any) {
        
    }
}
