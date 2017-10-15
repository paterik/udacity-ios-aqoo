//
//  PlaylistViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import Kingfisher

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
    let _playlistCellIdentifier = "playListItem"
    
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
    
        let playlistData = spotifyClient.playlistsInCache[indexPath.row]
        let playlistCell = tableView.dequeueReusableCell(withIdentifier: _playlistCellIdentifier, for: indexPath) as! PlaylistTableCell

        playlistCell.lblPlaylistName.text = playlistData.name
        playlistCell.lblPlaylistTrackCount.text = "\(playlistData.trackCount)"
        
        /*cell.detailTextLabel?.text = list.name
        cell.textLabel?.text = list.name
        cell.imageView?.image = spotifyClient.spfUserDefaultImage
        */
        
        
        // let processor = OverlayImageProcessor(overlay: .random, fraction: 0.875)
        // cell.imageView?.kf.setImage(with: spotifyClient.spfUserDefaultImageUrl!, options: [.processor(processor)])
        
        return playlistCell
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
