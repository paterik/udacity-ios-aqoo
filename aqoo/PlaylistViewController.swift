//
//  PlaylistViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class PlaylistViewController: BaseTableViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    var authViewController: UIViewController?
    var _playlists = [SPTPartialPlaylist]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.SetupUILoadPlaylist),
            name: NSNotification.Name(rawValue: appDelegate.spfSessionPlaylistLoadCompletedNotifierId),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if appDelegate.isSpotifyTokenValid() {
            
            //
            // call API :: instantiate new playlist request
            //
            
            handleNewUserPlaylistSession()
            
            print("\ndbg: session => \(appDelegate.spfCurrentSession!.accessToken!)")
            print("dbg: username => \(appDelegate.spfUsername)\n")
        }
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        // closeSession()
        
        _ = self.navigationController!.popViewController(animated: true)
    }
}
