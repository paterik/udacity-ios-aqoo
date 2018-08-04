//
//  PlaylistContentViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher

class PlaylistContentViewController: BaseViewController,
                                     UITableViewDataSource,
                                     UITableViewDelegate {
    
    let localPlaylistControls = SPFClientPlaylistControls.sharedInstance
    let localPlayer = SPFClientPlayer.sharedInstance
    
    var currentTrackPlaying: StreamPlayListTracks?
    var currentTrackTimePosition: Int = 0
    var currentTrackInterval: TimeInterval?
    var currentTrackPosition: Int = 0
    var currentTrackCell: PlaylistTracksTableCell?
    var currentPlayMode: Int16 = 0
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListTracksInCloud: [StreamPlayListTracks]?
    var playListTracksShuffleKeys: [Int]?
    var playListTracksShuffleKeyPosition: Int = 0
    var _trackTimer: Timer!
    
    @IBOutlet weak var trackControlView: PlaylistTracksControlView!
    @IBOutlet weak var tableView: UITableView!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUITableView()
        setupPlayerAuth()
        
        loadMetaPlaylistTracksFromDb()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        if  _trackTimer != nil {
            _trackTimer.invalidate()
        }
    }
    
    //
    // MARK: Class Table Delegates
    //
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return playListTracksInCloud!.count
    }
    
    func tableView(
       _ tableView: UITableView,
         heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 72.0
    }
    
    func tableView(
       _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let playlistTrackCacheData = playListTracksInCloud![indexPath.row] as StreamPlayListTracks
        let playlistCell = tableView.dequeueReusableCell(
            withIdentifier: "playListContentItem",
            for: indexPath) as! PlaylistTracksTableCell

        var _ctp: Float = 0.0
        var _ctd: Float = Float(TimeInterval(playlistTrackCacheData.trackDuration))
        
        var playlistCoverView: UIImageView! = playlistCell.imageViewAlbumCover
        var usedCoverImageCacheKey: String?
        var usedCoverImageURL: URL?
        
        playlistCell.lblAlbumName.text = playlistTrackCacheData.albumName
        playlistCell.lblTrackName.text = playlistTrackCacheData.trackName
        playlistCell.lblTrackPlayIndex.textColor = UIColor(netHex: 0xffffff)
        playlistCell.lblTrackPlayIndex.text = String(format: "%D", (indexPath.row + 1))
        
        // setup progressBar
        playlistCell.progressBar.progressTintColor = UIColor(netHex: 0x1DB954)
        playlistCell.progressBar.trackTintColor = UIColor.clear
    
        // try to bind album cover to track, use avatar (v1) if nothing found
        if  playlistTrackCacheData.albumCoverLargestImageURL != nil {
            usedCoverImageURL = URL(string: playlistTrackCacheData.albumCoverLargestImageURL!)
            usedCoverImageCacheKey = String(format: "a0::%@", playlistTrackCacheData.albumCoverLargestImageURL!).md5()
        }   else if playlistTrackCacheData.albumCoverSmallestImageURL != nil {
            usedCoverImageURL = URL(string: playlistTrackCacheData.albumCoverSmallestImageURL!)
            usedCoverImageCacheKey = String(format: "a1::%@", playlistTrackCacheData.albumCoverSmallestImageURL!).md5()
        }
        
        // check explicit state of current track and activate icon if needed/required
        playlistCell.imageViewTrackIsExplicit.isHidden = true
        if  playlistTrackCacheData.trackExplicit == true {
            playlistCell.imageViewTrackIsExplicit.isHidden = false
        }
        
        playlistCell.imageViewAlbumCover.image = UIImage.makeLetterAvatar(withUsername: playlistTrackCacheData.trackName)
        if  usedCoverImageURL != nil {
            handleCoverImageByCache(
                playlistCoverView,
                usedCoverImageURL!,
                usedCoverImageCacheKey!,
                [.transition(.fade(0.1875))]
            )
        }
        
        return playlistCell
    }
    
    func resetPlayer() {
        
        // reset (all) playMode controls
        trackControlView.mode = .clear
        // reset playMode for all (spotify) playlists in cache
        localPlaylistControls.resetPlayModeOnAllPlaylists()
        // reset playMode/timeFrame-Meta-Information for all (spotify) playlistTracks in cache
        localPlaylistControls.resetPlayModeOnAllPlaylistTracks()
        // clear local playlist playback meta
        resetLocalPlayerMetaSettings()
        // clear local track playback meta
        resetLocalTrackStateStettings()
        // logout from player
        localPlayer.player?.logout()
    }
    
    @IBAction func btnClosePlayistContentView(_ sender: Any) {
        
        resetPlayer()
        
        dismiss(animated: true, completion: nil)
    }
}
