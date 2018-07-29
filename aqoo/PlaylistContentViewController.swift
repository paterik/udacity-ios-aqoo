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
import CryptoSwift
import BGTableViewRowActionWithImage

class PlaylistContentViewController: BaseViewController,
                                     UITableViewDataSource,
                                     UITableViewDelegate {
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListTracksInCloud: [StreamPlayListTracks]?
    
    @IBOutlet weak var trackControlView: PlaylistTracksControlView!
    @IBOutlet weak var tableView: UITableView!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUITableView()
        
        loadMetaPlaylistTracksFromDb()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
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
        
        playlistCell.lblAlbumName.text = playlistTrackCacheData.albumName
        playlistCell.lblTrackName.text = playlistTrackCacheData.trackName
        playlistCell.lblTrackPlayIndex.text = String(format: "%D", (indexPath.row + 1))
        if  let trackDuration = playlistTrackCacheData.trackDuration as? Int32 {
            playlistCell.lblTrackPlaytime.text = getSecondsAsHoursMinutesSecondsDigits(Int(trackDuration))
        }
        
        var playlistCoverView: UIImageView! = playlistCell.imageViewAlbumCover
        var usedCoverImageCacheKey: String?
        var usedCoverImageURL: URL?
        
        playlistCell.imageViewAlbumCover.image = UIImage.makeLetterAvatar(withUsername: playlistTrackCacheData.trackName)
    
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
    
    @IBAction func btnClosePlayistContentView(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
}
