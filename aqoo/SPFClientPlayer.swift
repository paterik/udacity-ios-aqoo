//
//  SPFClientPlayer.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 02.08.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//
//  https://spotify.github.io/ios-sdk/Protocols/SPTAudioStreamingPlaybackDelegate.html
//  https://spotify.github.io/ios-sdk/Protocols/SPTAudioStreamingDelegate.html
//

import UIKit
import Spotify

class SPFClientPlayer: NSObject, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    //
    // MARK: Constants (Statics)
    //
    
    static let sharedInstance = SPFClientPlayer()
    
    //
    // MARK: Base Constants
    //
    
    let spotifyClient = SpotifyClient.sharedInstance
    
    //
    // MARK: Base Variables
    //
    
    var player: SPTAudioStreamingController?
    
    //
    // MARK: Player Functions
    //
    
    func initPlayer(authSession : SPTSession){
        
        if  player != nil {
            print ("_ player already initialized ...")
            return
        }
        
        player = SPTAudioStreamingController.sharedInstance()
        player!.playbackDelegate = self
        player!.delegate = self
        try! player!.start(withClientId:    spotifyClient.spfAuth.clientID)
        try! player!.login(withAccessToken: spotifyClient.spfCurrentSession?.accessToken)
    }
}
