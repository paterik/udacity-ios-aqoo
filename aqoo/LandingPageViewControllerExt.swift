//
//  LandingPageViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 20.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

extension LandingPageViewController {

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
}
