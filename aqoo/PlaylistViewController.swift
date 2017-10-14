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
    
    //
    // MARK: Class IBOutlet definitions
    //
    
    @IBOutlet weak var btnRefreshPlaylist: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    let _supportedProviderTag = "_spotify"
    
    //
    // MARK: Class Variables
    //
    
    var _defaultStreamingProvider: StreamProvider?
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUITableView()
        setupUIEventObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        handlePlaylistCloudRefresh()
    }
    
    //
    // MARK: Class Table Delegates
    //
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return spotifyClient.playlistsInCache.count
    }
    
    func tableView(
       _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let list = spotifyClient.playlistsInCache[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "playListItem", for: indexPath) 
        
        cell.detailTextLabel?.text = list.name
        cell.textLabel?.text = list.name
        
        return cell
    }
    
    //
    // MARK: Class IBAction Methods
    //
    
    @IBAction func btnRefreshPlaylistAction(_ sender: Any) {
        
        handlePlaylistCloudRefresh()
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        _ = self.navigationController!.popViewController(animated: true)
    }
}
