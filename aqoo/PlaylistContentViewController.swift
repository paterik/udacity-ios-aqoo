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
import fluid_slider
import GradientLoadingBar
import NotificationBannerSwift
import BGTableViewRowActionWithImage

class PlaylistContentViewController: BaseViewController,
                                     UITableViewDataSource,
                                     UITableViewDelegate {
    
    //
    // MARK: Constants (class)
    //
    
    let localPlaylistControls = SPFClientPlaylistControls.sharedInstance
    let localPlayer = SPFClientPlayer.sharedInstance
    let kBaseCellHeight: CGFloat = 72.0
    
    let currentTrack = ProxyPlaylistTrack.sharedInstance
    let currentPlaylist = ProxyPlaylist.sharedInstance
    
    //
    // MARK: Class Variables
    //
    
    var trackSubControlView: TrackBaseControls?
    var trackSubControlBanner: NotificationBanner?
    var trackSliderViewControl: Slider?
    var trackIndexValueChanged: Bool = false
    var trackIndexNewValueInSeconds: Int = 0
    var trackIndexOldValueInSeconds: Int = 0
    var trackIsFinishedByLaw: Bool = false
    var trackListGradientLoadingBar = GradientLoadingBar()
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    
    //
    // MARK: Class IBOutlet definitions
    //
    
    @IBOutlet weak var trackControlView: PlaylistTracksControlView!
    @IBOutlet weak var tableView: UITableView!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUITableView()
        setupUITrackControls()
        setupPlayerAuth()
        
        loadMetaPlaylistTracksFromDb()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        appDelegate.restrictRotation = .all
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        if  currentPlaylist.trackCheckTimer != nil {
            currentPlaylist.trackCheckTimer.invalidate()
        }
    }
    
    //
    // MARK: Class Delegate Method Overloads
    //
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return currentPlaylist.tracks!.count
    }
    
    func tableView(
       _ tableView: UITableView,
         heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return kBaseCellHeight
    }
    
    func tableView(
       _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let playlistTrackCacheData = currentPlaylist.tracks![indexPath.row] as StreamPlayListTracks
        let playlistCell = tableView.dequeueReusableCell(
            withIdentifier: "playListContentItem",
            for: indexPath) as! PlaylistTracksTableCell

        var _ctd: Float = Float(TimeInterval(playlistTrackCacheData.trackDuration))
        
        var playlistCoverView: UIImageView! = playlistCell.imageViewAlbumCover
        var usedCoverImageCacheKey: String?
        var usedCoverImageURL: URL?
        
        // handle sub controls for current track, based on playing state
        toggleTrackSubControls( playlistTrackCacheData.metaTrackIsPlaying )
        
        playlistCell.state = .stopped
        
        playlistCell.lblAlbumName.text = playlistTrackCacheData.albumName
        playlistCell.lblTrackName.text = playlistTrackCacheData.trackName
        playlistCell.lblTrackPlayIndex.textColor = UIColor(netHex: 0x010101)
        playlistCell.lblTrackPlayIndex.text = String(format: "%D", (indexPath.row + 1))
        playlistCell.progressBar.progressTintColor = UIColor(netHex: 0x1DB954)
        playlistCell.progressBar.trackTintColor = UIColor.clear
        playlistCell.progressBar.isHidden = false
        
        playlistCell.imageViewTrackIsPlayingIndicator.isHidden = true
        playlistCell.imageViewTrackIsPlayingSymbol.isHidden = true
        playlistCell.lblTrackPlaytime.textColor = UIColor(netHex: 0x80C9A4)
        playlistCell.lblTrackPlaytime.text = dfDates.getSecondsAsMinutesSecondsDigits(Int(_ctd))
        playlistCell.lblTrackPlaytimeRemaining.textColor = UIColor(netHex: 0x1DB954)
        playlistCell.lblTrackPlaytimeRemaining.text = playlistCell.lblTrackPlaytime.text
        playlistCell.progressBar.progress = 0.0
    
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
        if  playlistTrackCacheData.trackExplicit {
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
        
        //
        // dynamic meta data payload
        //
        
        if  playlistTrackCacheData.metaTrackIsPlaying {
            
            playlistCell.state = .playing
            playlistCell.imageViewTrackIsPlayingIndicator.isHidden = false
            playlistCell.imageViewTrackIsPlayingSymbol.isHidden = false
            playlistCell.lblTrackPlaytime.isHidden = true
            playlistCell.lblTrackPlaytimeRemaining.isHidden = false
            playlistCell.lblTrackPlaytimeRemaining.text = dfDates.getSecondsAsMinutesSecondsDigits(Int(_ctd) - currentTrack.timePosition)
            playlistCell.progressBar.setProgress(currentTrack.timeProgress, animated: false)
            
        }   else if currentPlaylist.playMode == 0 || playlistTrackCacheData.metaTrackIsPlaying == false {
            
            playlistCell.state = .stopped
            playlistCell.imageViewTrackIsPlayingIndicator.isHidden = true
            playlistCell.imageViewTrackIsPlayingSymbol.isHidden = true
            playlistCell.lblTrackPlaytime.text = dfDates.getSecondsAsMinutesSecondsDigits(Int(_ctd))
            playlistCell.lblTrackPlaytime.isHidden = false
            playlistCell.lblTrackPlaytimeRemaining.text = playlistCell.lblTrackPlaytime.text
            playlistCell.lblTrackPlaytimeRemaining.isHidden = true
            playlistCell.progressBar.progress = 0.0
        }

        return playlistCell
    }
    
    //
    // MARK: Class IBAction Methods
    //
    
    @IBAction func btnClosePlayistContentView(_ sender: Any) {
        
        resetPlayer()
        
        dismiss(animated: true, completion: nil)
    }
}
