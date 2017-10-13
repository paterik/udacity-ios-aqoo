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
                                SPTAudioStreamingPlaybackDelegate,
                                SPTAudioStreamingDelegate,
                                UITableViewDataSource,
                                UITableViewDelegate {
    
    let _defaultStreamingProviderTag: String = "_spotify"
    
    var _defaultStreamingProvider: StreamProvider?
    var _playlistsInCloud = [SPTPartialPlaylist]()
    var _playlistsInDb = [StreamPlayList]()
    var _playListHashesInDb = [String]()
    var _playListHashesInCloud = [String]()
    var _playListProvider: StreamProvider?
    
    @IBOutlet weak var btnRefreshPlaylist: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUITableView()
        setupUIMainMenuView()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.setupUILoadCloudPlaylists),
            name: NSNotification.Name(rawValue: appDelegate.spfSessionPlaylistLoadCompletedNotifierId),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self, selector: #selector(self.setupUILoadExtendedPlaylists),
            name: NSNotification.Name(rawValue: appDelegate.spfCachePlaylistLoadCompletedNotifierId),
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
        }
    }
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return _playlistsInDb.count
    }
    
    func tableView(
       _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let list = _playlistsInDb[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "playListItem", for: indexPath) 
        
        cell.detailTextLabel?.text = list.name
        cell.textLabel?.text = list.name
        
        return cell
        
    }
    
    @IBAction func btnRefreshPlaylistAction(_ sender: Any) {
        
        print ("REFRESH PLAYLIST")
        
        NotificationCenter.default.post(
            name: NSNotification.Name.init(rawValue: self.appDelegate.spfCachePlaylistLoadCompletedNotifierId),
            object: self
        )
        
    }
    
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        // closeSession()
        
        _ = self.navigationController!.popViewController(animated: true)
    }
}
