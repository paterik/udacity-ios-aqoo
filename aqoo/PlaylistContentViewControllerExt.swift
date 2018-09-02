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
import MaterialComponents.MaterialProgressView

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
                handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted cover image for your playlist")
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
        if  playListTracksInCloud?.count == 0 {
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
            localPlayer.initPlayer(authSession: spotifyClient.spfCurrentSession!)
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
        playListPlayMode = usedPlayMode
    }
    
    func setPlaylistInPlayMode(
       _ usedPlayMode: Int16) {
        
        // set new playMode to corrsponding playlist now
        localPlaylistControls.setPlayModeOnPlaylist( playListInDb!, usedPlayMode )
        
        // check shuffle playMode active - reset currentTrack.index to a nice shuffle-based one
        if  usedPlayMode == playMode.PlayShuffle.rawValue {
            currentTrack.index = playListTracksShuffleKeys![currentTrack.shuffleIndex]
        }
        
        // start track playing (if usefull playMode is given)
        if  usedPlayMode != playMode.Stopped.rawValue {
            trackStartPlaying( currentTrack.index )
        }
        
        if  debugMode == true {
            print ("newPlayMode=\(usedPlayMode), oldPlayMode=\(playListPlayMode), currentPLMode=\(playListInDb!.currentPlayMode)" )
        }
    }
    
    func trackHandleCellPlaying(
       _ number: Int) -> StreamPlayListTracks?  {
        
        // evaluate plausible object range, return in case of invalid value
        if playListTracksInCloud == nil || number >= playListTracksInCloud!.count { return nil }
        
        // fetch/cast track from current playlist trackSet, dialog-error on any kind of problem there
        guard let track = playListTracksInCloud![number] as? StreamPlayListTracks else {
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
            
            // API_CALL : stop playback
            try! localPlayer.player?.setIsPlaying(false, callback: { (error) in
                self.handleAllTrackCellsPlayStateReset()
                if (error != nil) {
                    self.handleErrorAsDialogMessage("Player Controls Error PCE.02", "\(error?.localizedDescription)")
                }
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
            currentTrack.index = number
            currentTrack.selected = track
            currentTrack.interval = TimeInterval(currentTrack.timePosition)
            currentTrack.isPlaying = true
            
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
        
        switch playListPlayMode {
            
            case playMode.PlayNormal.rawValue:
                
                // last track in playlist? return false (mark this process as 'not available') ...
                if playlistFinished() == true { return false }
                
                // otherwise jump to next track in playlist
                currentTrack.index += 1
                
                break
            
            case playMode.PlayShuffle.rawValue:
                
                if currentTrack.shuffleIndex == playListTracksShuffleKeys!.count - 1 { return false }
                
                currentTrack.shuffleIndex += 1
                currentTrack.index = playListTracksShuffleKeys![currentTrack.shuffleIndex]
                
                print ("dbg [playlist/track/shuffle] : currentPosition = \(currentTrack.shuffleIndex) of \(playListTracksShuffleKeys!.count - 1)")
                
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
            currentTrack.interval = TimeInterval(currentTrack.timePosition)
            currentTrack.timeProgress = 0.0
            
            if  debugMode == true {
                print ("dbg [playlist/track] : last track finished, try to start next song ...\n")
            }
        }
        
        return _isFinished
    }
    
    func playlistFinished() -> Bool {
        
        var _isFinished: Bool = false
        
        switch playListPlayMode {
            
            case playMode.PlayRepeatAll.rawValue:
                _isFinished = false
                 break
            
            case playMode.PlayShuffle.rawValue:
                _isFinished = currentTrack.shuffleIndex == playListTracksShuffleKeys!.count - 1
                 break
            
            case playMode.PlayNormal.rawValue:
                _isFinished = currentTrack.index == playListTracksInCloud!.count - 1
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
        
        if  _trackTimer != nil {
            _trackTimer.invalidate()
        }
        
        trackControlView.imageViewPlaylistIsPlayingIndicator.isHidden = !active
        trackControlView.state = .stopped
        
        if  active == true {
            
            // start playback meta timer
            _trackTimer = Timer.scheduledTimer(
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
    func handleSingleTrackTimerEvent() {
        //  track still runnning? update track timeFrama position and progressBar
        if  trackIsFinished() == false {
            
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
            
            localPlaylistControls.setTrackTimePositionWhilePlaying( currentTrack.selected!, currentTrack.timePosition )
        }
        
        if  trackIsFinished() == true {
            
            trackStopPlaying( currentTrack.index )
            
            if  playlistFinished() == false {
                
                if  trackJumpToNext() == true {
                    trackStartPlaying( currentTrack.index )
                }
                
            }   else {
                
               _trackTimer.invalidate()
                handlePlaylistCompleted()
            }
        }
    }
    
    func handlePlaylistCompleted() {
        
        // call playlistPlayMode with playListPlayMode to simmulate users "stop" click
        handlePlaylistPlayMode( playListPlayMode )
        // reset player meta and track state settings
        resetLocalPlayerMetaSettings()
        resetLocalTrackStateStettings()
        
        // reset playMode for all (spotify) playlists in cache
        localPlaylistControls.resetPlayModeOnAllPlaylists()
        
        // reset playMode/timeFrame-Meta-Information for all (spotify) playlistTracks in cache
        localPlaylistControls.resetPlayModeOnAllPlaylistTracks()
    }
    
    func resetLocalPlayerMetaSettings() {

        playListTracksShuffleKeys = []
        playListPlayMode = 0
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
        playListTracksInCloud = CoreStore.defaultStack.fetchAll(
             From<StreamPlayListTracks>()
                .where(\StreamPlayListTracks.playlist == playListInDb)
                .orderBy(.ascending(\StreamPlayListTracks.trackAddedAt))
        )
        
        // load playlist local cache from db (refresh)
        playListInDb = CoreStore.defaultStack.fetchOne(
            From<StreamPlayList>()
                .where(\StreamPlayList.metaListHash == playListInDb!.getMD5Identifier())
        )
        
        // init shuffled key stack for shuffle-play-mode
        if  playListTracksInCloud != nil {
            playListTracksShuffleKeys = getRandomUniqueNumberArray(
                forLowerBound: 0,
                andUpperBound: playListTracksInCloud!.count,
                andNumNumbers: playListTracksInCloud!.count
            )
            
            if  debugMode == true {
                print ("dbg [playlist/track/shuffle] : keys = [\(playListTracksShuffleKeys!)]")
            }
        }
    }
}
