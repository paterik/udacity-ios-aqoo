//
//  PlaylistContentViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import NotificationBannerSwift
import MaterialComponents.MaterialProgressView
import fluid_slider

extension PlaylistContentViewController {
 
    func setupUIBase() {
        
        var _noCoverImageAvailable : Bool = true
        var _usedCoverImageCacheKey : String?
        var _usedCoverImageURL : URL?
        
        // try to bound cover image using user generated image (cover override)
        if  playListInDb!.coverImagePathOverride != nil {
            if  let _image = getImageByFileName(playListInDb!.coverImagePathOverride!) {
                trackControlView.imageViewPlaylistCover.image = _image
            }   else {
                handleErrorAsDialogMessage("IO Error (Read)", "unable to load own cover image for your playlist")
            }
            
        }   else {
            
            // try to bound cover image using largestImageURL
            if  playListInDb!.largestImageURL != nil {
               _usedCoverImageURL = URL(string: playListInDb!.largestImageURL!)
               _usedCoverImageCacheKey = String(format: "d0::%@", _usedCoverImageURL!.absoluteString).md5()
               _noCoverImageAvailable = false
            }
            
            // no large image found? try smallestImageURL instead
            if  playListInDb!.smallestImageURL != nil && _noCoverImageAvailable == true {
               _usedCoverImageURL = URL(string: playListInDb!.smallestImageURL!)
               _usedCoverImageCacheKey = String(format: "d0::%@", _usedCoverImageURL!.absoluteString).md5()
               _noCoverImageAvailable = false
            }
            
            // call cover image handler for primary coverImageView
            if _noCoverImageAvailable == false {
                handleCoverImageByCache(
                    trackControlView.imageViewPlaylistCover,
                    _usedCoverImageURL!,
                    _usedCoverImageCacheKey!,
                    [ .transition(.fade(0.1875)) ]
                )
            }
        }
        
        // add some additional meta data for our current playlist trackView
        trackControlView.lblPlaylistName.text = playListInDb!.metaListInternalName
        trackControlView.lblPlaylistTrackCount.text = String(format: "%D", playListInDb!.trackCount)
        if  let playlistOverallPlaytime = playListInDb!.metaListOverallPlaytimeInSeconds as? Int32 {
            trackControlView.lblPlaylistOverallPlaytime.text = getSecondsAsHoursMinutesSecondsDigits(Int(playlistOverallPlaytime))
        }
        
        setupUIPlayModeControls()
    }
    
    func setupUIPlayModeControls() {
        
        toggleActiveMode( true )
        if  currentPlaylist.tracks?.count == 0 {
            toggleActiveMode( false )
        }
        
        trackControlView.btnPlayShuffleMode.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(PlaylistContentViewController.handlePlaylistPlayShuffleMode))
        )
        
        trackControlView.btnPlayNormalMode.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(PlaylistContentViewController.handlePlaylistPlayNormalMode))
        )
        
        trackControlView.btnPlayRepeatMode.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(PlaylistContentViewController.handlePlaylistPlayRepeatMode))
        )
    }
    
    func setupPlayerAuth() {
        
        if  spotifyClient.isSpotifyTokenValid() {
            
            if  localPlayer.player?.loggedIn == true {
                if  self.debugMode == true {
                    print ("dbg [playlist/track] : player was previously initialized, start refreshing session")
                };  localPlayer.player?.logout()
            };      localPlayer.initPlayer(authSession: spotifyClient.spfCurrentSession!)
            
        }   else {
            
            // @todo: exit view, return to login page!
            self.handleErrorAsDialogMessage(
                "Spotify Session Closed",
                "Oops! your spotify session is not valid anymore, please (re)login again ..."
            )
        }
    }
    
    func setupUITableView() {
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func handleInitValuesForTrackControl() {
        
        var sliderView = getSliderTrackIndexUIControl() as? Slider
        if  sliderView == nil {
            
            return
        }
        
        sliderView!.fraction = CGFloat(0.0)
        sliderView!.shadowColor = UIColor(white: 0, alpha: 0.1)
        sliderView!.contentViewColor = UIColor(netHex: 0x1DB954)
        sliderView!.valueViewColor = .white
        
        sliderView!.addTarget(self, action: #selector(dbg_handleInputPlaylistRatingChanged), for: .valueChanged)
    }
    
    func handleRuntimeValuesForTrackControl(
       _ minValue: CGFloat,
       _ maxValue: CGFloat,
       _ currentValue: CGFloat) {
        
        var sliderView = getSliderTrackIndexUIControl() as? Slider
        if  sliderView == nil || sliderView!.isSliderTracking {
            return
        }
        
        sliderView!.attributedTextForFraction = { fraction in
            
            let formatter = NumberFormatter()
                formatter.maximumIntegerDigits = 4
                formatter.maximumFractionDigits = 0
                
            let currentTimePosAsString = formatter.string(from: (currentValue) as NSNumber) ?? ""
            
            return NSAttributedString(string: currentTimePosAsString, attributes: [
                    .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
            )
        }
        
        let labelTextAttributes: [NSAttributedStringKey : Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        sliderView!.setMinimumLabelAttributedText(NSAttributedString(
            string: "", attributes: labelTextAttributes)
        )
         
        sliderView!.setMaximumLabelAttributedText(NSAttributedString(
            string: "\(maxValue)s", attributes: labelTextAttributes)
        )
        
        let fractionStepper: CGFloat = 1 / maxValue
        
        sliderView!.fraction += (fractionStepper * 1000).rounded() / 1000
        
        print ("___ currentFraction == \(sliderView!.fraction)")
    }
    
    func getSliderTrackIndexUIControl() -> Slider? {
        
        guard let sliderView = trackSubControlView?.cViewTrackPositionIndex as? Slider else {
            self.handleErrorAsDialogMessage("UI Rendering Error", "unable to get track position slider controls")
            
            return nil
        }
        
        return sliderView
    }
    
    func setupUITrackControls() {
        
        trackSubControlView = TrackBaseControls.fromNib(nibName: "TrackBaseControls")
        trackSubControlBanner = NotificationBanner(customView: trackSubControlView!)
        trackSubControlBanner!.autoDismiss = false
        
        handleInitValuesForTrackControl()
    }
    
    @objc
    func dbg_handleInputPlaylistRatingChanged(slider: Slider) {
        
        let trackIndexValueRaw = (slider.fraction * 100).rounded() / 100
        
        print ("trackIndexValue: \(trackIndexValueRaw)")
    }
    
    @objc
    func handlePlaylistPlayShuffleMode(sender: UITapGestureRecognizer) {
        
        if (sender.state != .ended) { return }
        
        handlePlaylistPlayMode(playMode.PlayShuffle.rawValue)
    }
    
    @objc
    func handlePlaylistPlayNormalMode(sender: UITapGestureRecognizer) {
        
        if (sender.state != .ended) { return }
        
        handlePlaylistPlayMode(playMode.PlayNormal.rawValue)
    }
    
    @objc
    func handlePlaylistPlayRepeatMode(sender: UITapGestureRecognizer) {
        
        if (sender.state != .ended) { return }
        
        handlePlaylistPlayMode(playMode.PlayRepeatAll.rawValue)
    }
    
    func handlePlaylistPlayMode(
       _ usedPlayMode: Int16) {
        
        //
        // stop everything and reset cache meta information (from status play to stop) also
        //
        
        // A) always reset (all) playMode controls and stop playback first
        trackControlView.mode = .clear // place pause definition logic here!
        setPlaylistInPlayMode( playMode.Stopped.rawValue )
        togglePlayMode( false )
        
        // B) also reset playMode/timeFrame-Meta-Information for all (spotify) playlists and playlistTracks in dbcache
        localPlaylistControls.resetPlayModeOnAllPlaylistTracks()
        localPlaylistControls.resetPlayModeOnAllPlaylists()
        tableView.reloadData()
        
        //
        // real playmode change in process? set new playmode and play
        //

        if  usedPlayMode != playListInDb!.currentPlayMode {
            
            setPlaylistInPlayMode( usedPlayMode )
            togglePlayMode( true )
            
            switch usedPlayMode {
                
                case playMode.PlayNormal.rawValue:
                     trackControlView.mode = .playNormal
                    
                     break
                
                case playMode.PlayShuffle.rawValue:
                     trackControlView.mode = .playShuffle
                    
                     break
                
                case playMode.PlayRepeatAll.rawValue:
                     trackControlView.mode = .playLoop
                    
                     break
                
                default: break
            }
        }
        
        // (re)set current playMode for internal usage
        currentPlaylist.playMode = usedPlayMode
    }
    
    func setPlaylistInPlayMode(
       _ usedPlayMode: Int16) {
        
        // set new playMode to corrsponding playlist now
        localPlaylistControls.setPlayModeOnPlaylist( playListInDb!, usedPlayMode )
        
        // check shuffle playMode active - reset currentTrack.index to a nice shuffle-based one
        if  usedPlayMode == playMode.PlayShuffle.rawValue {
            currentTrack.index = currentPlaylist.shuffleKeys![currentTrack.shuffleIndex]
        }
        
        // start track playing (if usefull playMode is given)
        if  usedPlayMode != playMode.Stopped.rawValue {
            trackStartPlaying( currentTrack.index )
        }
        
        if  debugMode == true {
            print ("newPlayMode=\(usedPlayMode), oldPlayMode=\(currentPlaylist.playMode), currentPLMode=\(playListInDb!.currentPlayMode)" )
        }
    }
    
    func trackHandleCellPlaying(
       _ number: Int) -> StreamPlayListTracks?  {
        
        // evaluate plausible object range, return in case of invalid value
        if currentPlaylist.tracks == nil || number >= (currentPlaylist.tracks?.count)! { return nil }
        
        // fetch/cast track from current playlist trackSet, dialog-error on any kind of problem there
        guard let track = currentPlaylist.tracks![number] as? StreamPlayListTracks else {
            self.handleErrorAsDialogMessage("Track Rendering Error", "unable to fetch track #\(number) as playable object")
            
            return nil
        }
        
        // visual jump to track position inside corresponding table
        jumpToActiveTrackCellByTrackPosition( number )
        
        return track
    }
    
    func trackStopPlaying(
       _ number: Int) {

        if  let track = trackHandleCellPlaying( number ) as? StreamPlayListTracks {
            // update local persistance layer for tracks, set track to mode "isStopped"
            localPlaylistControls.setTrackInPlayState( track, false )
            
            // API_CALL : stop playback - ignore incoming error, just reset cell playState
            try! localPlayer.player?.setIsPlaying(false, callback: { (error) in
                self.handleAllTrackCellsPlayStateReset()
            })
        }
        
        // set active meta object (track and index) of active (playing) track
        currentTrack.index = 0
        currentTrack.selected = nil
        currentTrack.isPlaying = false
    }
    
    func trackStartPlaying(
       _ number: Int) {
        
        if  let track = trackHandleCellPlaying( number ) as? StreamPlayListTracks {
            // update local persistance layer for tracks, set track to mode "isPlaying"
            localPlaylistControls.setTrackInPlayState( track, true )
            
            // set active meta object (track and index) of active (playing) track, (re)evaluate current trackInterval
            currentTrack.isPlaying = true
            currentTrack.index = number
            currentTrack.selected = track
            currentTrack.interval = TimeInterval(currentTrack.timePosition)
            
            // API_CALL :: start playback using spotify api call
            localPlayer.player?.playSpotifyURI(
                currentTrack.selected!.trackURIInternal,
                startingWith: 0,
                startingWithPosition: currentTrack.interval!,
                callback: { (error) in
                    if (error != nil) {
                        self.handleErrorAsDialogMessage("Player Controls Error PCE.01", "\(error?.localizedDescription)")
                        
                        return
                    }
                }
            )
        }
    }
    
    func trackJumpToNext() -> Bool {
        
        switch currentPlaylist.playMode {
            
            case playMode.PlayNormal.rawValue:
                
                // last track in playlist? return false (mark this process as 'not available') ...
                if playlistFinished() == true { return false }
                
                // otherwise jump to next track in playlist
                currentTrack.index += 1
                
                break
            
            case playMode.PlayShuffle.rawValue:
                
                if currentTrack.shuffleIndex == currentPlaylist.shuffleKeys!.count - 1 { return false }
                
                currentTrack.shuffleIndex += 1
                currentTrack.index = currentPlaylist.shuffleKeys![currentTrack.shuffleIndex]
                
                print ("dbg [playlist/track/shuffle] : currentPosition = \(currentTrack.shuffleIndex) of \(currentPlaylist.shuffleKeys!.count - 1)")
                
                break
            
            case playMode.PlayRepeatAll.rawValue:
        
                // jump to next track in current playlist
                currentTrack.index += 1
                // check playlist finished state, jump to first track again on "repeatAll" mode
                if  playlistFinished() == true {
                    currentTrack.index = 0
                }
            
                break
            
            default: return false
        }
        
        return true
    }
    
    func trackIsFinished() -> Bool {
        
        var _isFinished: Bool = true
        
        if  currentTrack.selected != nil {
           _isFinished = currentTrack.timePosition == Int(currentTrack.selected!.trackDuration)
        }
        
        if _isFinished == true {
            
            currentTrack.timePosition = 0
            currentTrack.timeProgress = 0.0
            currentTrack.interval = TimeInterval(currentTrack.timePosition)
            
            if  debugMode == true {
                print ("dbg [playlist/track] : last track finished, try to start next song ...\n")
            }
        }
        
        return _isFinished
    }
    
    func playlistFinished() -> Bool {
        
        var _isFinished: Bool = false
        
        switch currentPlaylist.playMode {
            
            case playMode.PlayRepeatAll.rawValue:
                _isFinished = false
                 break
            
            case playMode.PlayShuffle.rawValue:
                _isFinished = currentTrack.shuffleIndex == currentPlaylist.shuffleKeys!.count - 1
                 break
            
            case playMode.PlayNormal.rawValue:
                _isFinished = currentTrack.index == currentPlaylist.tracks!.count - 1
                 break
            
            case playMode.Stopped.rawValue:
                _isFinished = true
                 break
        
            default: break
        }
        
        if _isFinished == true && debugMode == true {
            print ("dbg [playlist/track] : \(playListInDb!.metaListHash) finished, no more songs available ...\n")
        }
        
        return _isFinished
    }
    
    func toggleTrackSubControls(
       _ active: Bool) {
        
        // prevent calls on uninitialized controls
        if  trackSubControlBanner == nil {
            return
        }
        
        if  active == true {
            trackSubControlBanner!.show(bannerPosition: .bottom)
        }   else {
            trackSubControlBanner!.dismiss()
        }
    }
    
    func toggleActiveMode(
       _ active: Bool) {
        
        trackControlView.btnPlayRepeatMode.isEnabled = active
        trackControlView.btnPlayNormalMode.isEnabled = active
        trackControlView.btnPlayShuffleMode.isEnabled = active
        
        trackControlView.btnPlayRepeatMode.isUserInteractionEnabled = active
        trackControlView.btnPlayNormalMode.isUserInteractionEnabled = active
        trackControlView.btnPlayShuffleMode.isUserInteractionEnabled = active
    }

    func togglePlayMode (
       _ active: Bool) {
        
        if  currentPlaylist.trackCheckTimer != nil {
            currentPlaylist.trackCheckTimer.invalidate()
        }
        
        trackControlView.imageViewPlaylistIsPlayingIndicator.isHidden = !active
        trackControlView.state = .stopped
        
        if  active == true {
            
            // start playback meta timer
            currentPlaylist.trackCheckTimer = Timer.scheduledTimer(
                timeInterval : TimeInterval(1),
                target       : self,
                selector     : #selector(handlePlaylistTrackTimerEvent),
                userInfo     : nil,
                repeats      : true
            );  trackControlView.state = .playing
            
        }   else {
        
            // stop playback using direct api call
            trackStopPlaying( currentTrack.index )
        }
    }
    
    func handleActiveTrackCellByTrackPosition(_ trackPosition: Int) {
        
        // do not update cell completely if in editMode (swiped)
        if tableView.isEditing == true { return }
        
        var trackIndexPath = IndexPath(row: trackPosition, section: 0)
        
        tableView.reloadRows(at: [trackIndexPath], with: .none)
    }
    
    func jumpToActiveTrackCellByTrackPosition(_ trackPosition: Int) {
     
        // evaluate indexPath
        var trackIndexPath = IndexPath(row: trackPosition, section: 0)
        // scroll to current trackPosition
        tableView.scrollToRow(at: trackIndexPath, at: .top, animated: true)
        // try to postFetch ballistic meta data from current tableQueue to get active track cell (majic)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
            
            self.currentTrack.cell = nil
            let _trackCell = self.tableView.cellForRow(at: trackIndexPath) as? PlaylistTracksTableCell
            if  _trackCell != nil {
                 self.currentTrack.cell = _trackCell
            }
        }
    }
    
    func handleAllTrackCellsPlayStateReset() {
        
        for trackCell in tableView.visibleCells as! [PlaylistTracksTableCell] {
            
            trackCell.state = .stopped
            trackCell.imageViewTrackIsPlayingIndicator.isHidden = true
            trackCell.imageViewTrackIsPlayingSymbol.isHidden = true
            
            trackCell.lblTrackPlaytime.textColor = UIColor(netHex: 0x80C9A4)
            trackCell.lblTrackPlaytime.isHidden = false
            
            trackCell.lblTrackPlaytimeRemaining.isHidden = true
            trackCell.progressBar.setProgress(0.0, animated: false)
        }
    }
    
    @objc
    func handlePlaylistTrackTimerEvent() {

        // trace cell for this track
        handleActiveTrackCellByTrackPosition( currentTrack.index )

        //  track still runnning? update track timeFrama position and progressBar
        if  trackIsFinished() == false {
            
            currentTrack.timePosition += 1
            currentTrack.timeProgress = (Float(currentTrack.timePosition) / Float(currentTrack.selected!.trackDuration))
            currentTrack.interval = TimeInterval(currentTrack.timePosition)
            
            // handle track time position for track control slider
            handleRuntimeValuesForTrackControl(
                0.0,
                CGFloat(currentTrack.selected!.trackDuration),
                CGFloat(currentTrack.timePosition)
            )
            
            localPlaylistControls.setTrackTimePositionWhilePlaying( currentTrack.selected!, currentTrack.timePosition )
        }
        
        if  trackIsFinished() == true {
            
            trackStopPlaying( currentTrack.index )
            
            if  playlistFinished() == false {
                
                if  trackJumpToNext() == true {
                    trackStartPlaying( currentTrack.index )
                }
                
            }   else {
                
                handlePlaylistCompleted()
            }
        }
    }
    
    func handlePlaylistCompleted() {
        
        // call playlistPlayMode with playListPlayMode to simmulate users "stop" click
        handlePlaylistPlayMode( currentPlaylist.playMode )
        
        // reset player meta and track state settings
        resetLocalPlayerMetaSettings()
        resetLocalTrackStateStettings()
        
        // reset playMode for all (spotify) playlists in cache
        localPlaylistControls.resetPlayModeOnAllPlaylists()
        
        // reset playMode/timeFrame-Meta-Information for all (spotify) playlistTracks in cache
        localPlaylistControls.resetPlayModeOnAllPlaylistTracks()
        
        // reset primary track/check timer
        if  currentPlaylist.trackCheckTimer != nil {
            currentPlaylist.trackCheckTimer.invalidate()
        }
    }
    
    func resetLocalPlayerMetaSettings() {

        currentPlaylist.shuffleKeys = []
        currentPlaylist.playMode = 0
        currentTrack.cell = nil
        currentTrack.shuffleIndex = 0
    }
    
    func resetLocalTrackStateStettings() {
        
        currentTrack.timePosition = 0
        currentTrack.selected = nil
        currentTrack.isPlaying = false
        currentTrack.interval = 0
        currentTrack.index = 0
    }
    
    func loadMetaPlaylistTracksFromDb() {
        
        // load all tracks from db
        currentPlaylist.tracks = CoreStore.defaultStack.fetchAll(
             From<StreamPlayListTracks>()
                .where(\StreamPlayListTracks.playlist == playListInDb)
                .orderBy(.ascending(\StreamPlayListTracks.trackAddedAt))
        )
        
        // init shuffled key stack for shuffle-play-mode
        if  currentPlaylist.tracks != nil {
            currentPlaylist.shuffleKeys = getRandomUniqueNumberArray(
                forLowerBound: 0,
                andUpperBound: currentPlaylist.tracks!.count,
                andNumNumbers: currentPlaylist.tracks!.count
            )
            
            if  debugMode == true {
                print ("dbg [playlist/track/shuffle] : keys = [\(currentPlaylist.shuffleKeys!)]")
            }
        }
        
        // load playlist local cache from db (refresh)
        playListInDb = CoreStore.defaultStack.fetchOne(
            From<StreamPlayList>()
                .where(\StreamPlayList.metaListHash == playListInDb!.getMD5Identifier())
        )
    }
}
