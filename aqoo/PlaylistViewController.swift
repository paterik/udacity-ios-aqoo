//
//  PlaylistViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class PlaylistViewController:   BaseViewController,
                                UITableViewDataSource,
                                UITableViewDelegate,
                                SPTAudioStreamingPlaybackDelegate,
                                SPTAudioStreamingDelegate {
    
    var authViewController: UIViewController?
    var _playlists = [SPTPartialPlaylist]()
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUITableView()
        setupMainMenuView()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.setupUILoadPlaylist),
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
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return _playlists.count
    }
    
    func tableView(
       _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let list = _playlists[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "playListItem", for: indexPath) 
        
        cell.detailTextLabel?.text = list.name
        cell.textLabel?.text = list.name
        
        return cell
        
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        // closeSession()
        
        _ = self.navigationController!.popViewController(animated: true)
    }
}
