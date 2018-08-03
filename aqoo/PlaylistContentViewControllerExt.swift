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
import BGTableViewRowActionWithImage
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
        
        // reset (all) playMode controls
        trackControlView.mode = .clear
        // set current playMode for internal usage
        currentPlayMode = usedPlayMode
        
        print (currentPlayMode, playListInDb!.currentPlayMode, playMode.PlayNormal.rawValue)
        
        switch currentPlayMode {
            
            case playMode.PlayNormal.rawValue:
                if  playListInDb!.currentPlayMode != playMode.PlayNormal.rawValue {
                    setPlaylistPlayMode( playMode.PlayNormal.rawValue )
                    trackControlView.mode = .playNormal
                    togglePlayMode( true )
                }   else {
                    setPlaylistPlayMode( playMode.Default.rawValue )
                    trackControlView.mode = .clear
                    togglePlayMode( false )
                };  break
            
     
            case playMode.PlayShuffle.rawValue:
                if  playListInDb!.currentPlayMode != playMode.PlayShuffle.rawValue {
                    setPlaylistPlayMode( playMode.PlayShuffle.rawValue )
                    trackControlView.mode = .playShuffle
                    togglePlayMode( true )
                }   else {
                    setPlaylistPlayMode( playMode.Default.rawValue )
                    trackControlView.mode = .clear
                    togglePlayMode( false )
                };  break
            
            case playMode.PlayRepeatAll.rawValue:
                if  playListInDb!.currentPlayMode != playMode.PlayRepeatAll.rawValue {
                    setPlaylistPlayMode( playMode.PlayRepeatAll.rawValue )
                    trackControlView.mode = .playLoop
                    togglePlayMode( true )
                }   else {
                    setPlaylistPlayMode( playMode.Default.rawValue )
                    trackControlView.mode = .clear
                    togglePlayMode( false )
                };  break
            
            default:
                
                trackControlView.mode = .clear
                togglePlayMode( false )
                break
        }
    }
    
    func setPlaylistPlayMode(
       _ usedPlayMode: Int16) {
        
        // reset playMode for all (spotify) playlists in cache
        localPlaylistControls.resetPlayModeOnAllPlaylists()
        // set new playMode to corrsponding playlist now
        localPlaylistControls.setPlayModeOnPlaylist( playListInDb!, usedPlayMode )
        // start playing tracks using -1 as init position for trackJumpToNext() call
        currentTrackPosition = -1
        if  trackJumpToNext() == true {
            trackStartPlaying( currentTrackPosition )
        }
    }
    
    func trackStopPlaying(
       _ number: Int) {

        if playListTracksInCloud == nil || number > playListTracksInCloud!.count { return }
        
        guard let _trackCell = getTableCellForTrackPosition( number ) as? PlaylistTracksTableCell else {
            return
        }; currentTrackCell = _trackCell
           currentTrackCell!.progressBar.setHidden(true, animated: true)
        
        // fetch track from current playlist trackSet
        let track = playListTracksInCloud![number] as! StreamPlayListTracks
        
        // update local persistance layer for tracks, set track to mode "isPlaying"
        localPlaylistControls.setTrackInPlayState( track, false )
        
        // handle corresponding cell UI
        handleTrackPlayingCellUI( number, isPlaying: false )
        
        // stop playback
        try! localPlayer.player?.setIsPlaying(false, callback: { (error) in
            if (error != nil) {
                self.handleErrorAsDialogMessage("Player Controls Error", "\(error?.localizedDescription)")
            }
        })
    }
    
    func trackStartPlaying(
       _ number: Int) {
        
        if  playListTracksInCloud == nil || number >= playListTracksInCloud!.count { return }
        
        guard let _trackCell = getTableCellForTrackPosition( currentTrackPosition ) as? PlaylistTracksTableCell else {
            return
        };  currentTrackCell = _trackCell
        
        // fetch track from current playlist trackSet
        let track = playListTracksInCloud![number] as! StreamPlayListTracks
        
        // update local persistance layer for tracks, set track to mode "isPlaying"
        localPlaylistControls.setTrackInPlayState( track, true )
        
        // set active meta object of active (playing) track
        currentTrackPlaying  = track
        
        // set active meta object, (re)evaluate current trackInterval
        currentTrackInterval = TimeInterval(currentTrackTimePosition)
        
        // handle corresponding CellUI
        handleTrackPlayingCellUI( number, isPlaying: true )
        
        // start playback using spotify api call
        localPlayer.player?.playSpotifyURI(
            currentTrackPlaying!.trackURIInternal,
            startingWith: 0,
            startingWithPosition: currentTrackInterval!,
            callback: { (error) in
                if (error != nil) {
                    self.handleErrorAsDialogMessage("Player Controls Error", "\(error?.localizedDescription)")
                }
            }
        )
    }
    
    func trackJumpToNext() -> Bool {
        
        currentTrackTimePosition = 0
        
        switch currentPlayMode {
            
            case playMode.PlayNormal.rawValue:
                
                // last track in playlist? return false (mark this process as 'not available') ...
                if playlistFinished() == true { return false }
                // otherwise jump to next track in playlist
                currentTrackPosition += 1
                
                break
            
            case playMode.PlayShuffle.rawValue:
            
                if playListTracksShuffleKeyPosition == playListTracksShuffleKeys!.count { return false }
                
                currentTrackPosition = playListTracksShuffleKeys![playListTracksShuffleKeyPosition]
                playListTracksShuffleKeyPosition += 1
                
                print ("__ shuffleKeyPosition = \(playListTracksShuffleKeyPosition)")
                print ("__ shuffleKeys = \(playListTracksShuffleKeys!)")
                print ("__ shuffleKeyCount = \(playListTracksShuffleKeys!.count)")
                print ("__ currentTrackPosition = \(currentTrackPosition)\n")
                
                break
            
            case playMode.PlayRepeatAll.rawValue:
        
                // last track in playlist? jump to first track again otherwise jump to next track in PL
                if  playlistFinished() == true {
                    currentTrackPosition  = 0
                }   else {
                    currentTrackPosition += 1
                }
            
                break
            
            default:
                return false
        }
        
        return true
    }
    
    func trackIsFinished() -> Bool {
        
        let _isFinished: Bool = currentTrackTimePosition == Int(currentTrackPlaying!.trackDuration)
        if  _isFinished == true && debugMode == true {
            print ("dbg [playlist/track] : \(currentTrackPlaying!.trackIdentifier!) finished, try to start next song ...\n")
        }
        
        return _isFinished
    }
    
    func playlistFinished() -> Bool {
        
        var _isFinished: Bool = false
        
        switch currentPlayMode {
            
            case playMode.PlayRepeatAll.rawValue:
                _isFinished = false
                break
            
            case playMode.PlayShuffle.rawValue:
                _isFinished = playListTracksShuffleKeyPosition == playListTracksShuffleKeys!.count
                break
            
            case playMode.PlayNormal.rawValue:
                _isFinished = currentTrackPosition == playListTracksInCloud!.count - 1
                break
        
            default: break
        }
        
        if  _isFinished == true && debugMode == true {
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
        
        if  active == false {
            
            trackStopPlaying( currentTrackPosition )
            
        }   else {
        
            // start playback meta timer
            _trackTimer = Timer.scheduledTimer(
                timeInterval : TimeInterval(1),
                target       : self,
                selector     : #selector(handleTrackTimerEvent),
                userInfo     : nil,
                repeats      : true
            );  trackControlView.state = .playing
        }
    }
    
    func getTableCellForTrackPosition(_ trackPosition: Int) -> PlaylistTracksTableCell? {
        
        guard let _trackCell = tableView.cellForRow(at: IndexPath(row: trackPosition, section: 0)) as? PlaylistTracksTableCell else {
            
            if  debugMode == true {
                print ("dbg [playlist/track] : cell not found <return>")
            }
            
            return nil
        }
        
        return _trackCell
    }
    
    @objc
    func handleTrackTimerEvent() {
        
        //  track still runnning? update track timeFrama position and progressBar
        if  trackIsFinished() == false {
            
            currentTrackTimePosition += 1
            currentTrackInterval = TimeInterval(currentTrackTimePosition)
            
            localPlaylistControls.setTrackTimePositionWhilePlaying( currentTrackPlaying!, currentTrackTimePosition )
            
            var _ctp: Float = Float(currentTrackTimePosition)
            var _ctd: Float = Float(currentTrackPlaying!.trackDuration)
            var _progress: Float = (_ctp / _ctd)
            
            currentTrackCell!.progressBar.setProgress(_progress, animated: true)
        }
        
        if  trackIsFinished() == true {
            trackStopPlaying( currentTrackPosition )
            
            if  playlistFinished() == false {
                
                if  trackJumpToNext() == true {
                    trackStartPlaying( currentTrackPosition )
                }
                
            }   else {
                
               _trackTimer.invalidate()
                handlePlaylistCompleted()
            }
        }
    }
    
    func handlePlaylistCompleted() {
        
        handlePlaylistPlayMode( 0 )
        resetLocalPlayerMetaSettings()
        localPlaylistControls.resetPlayModeOnAllPlaylists()
    }
    
    func handleTrackPlayingCellUI(_ number: Int, isPlaying: Bool) {
        
        guard let _trackCell = getTableCellForTrackPosition( number ) as? PlaylistTracksTableCell else {
            return
        }
        
        _trackCell.imageViewTrackIsPlayingIndicator.isHidden = !isPlaying
        _trackCell.imageViewTrackIsPlayingSymbol.isHidden = !isPlaying
        _trackCell.progressBar.isHidden = true
        _trackCell.state = .stopped
        
        if  isPlaying == true {
           _trackCell.state = .playing
           _trackCell.progressBar.isHidden = false
           _trackCell.progressBar.progress = 0
           _trackCell.progressBar.progressTintColor = UIColor(netHex: 0x1DB954)
           _trackCell.progressBar.trackTintColor = UIColor.clear
           _trackCell.progressBar.setHidden(false, animated: true)
        }
        
        currentTrackCell = _trackCell
    }
    
    func resetLocalPlayerMetaSettings() {

        currentTrackTimePosition = 0
        currentTrackPlaying = nil
        currentTrackInterval = 0
        currentTrackPosition = 0
        currentPlayMode = 0
        currentTrackCell = nil
        
        playListTracksShuffleKeyPosition = 0
        playListTracksShuffleKeys = []
    }
    
    func loadMetaPlaylistTracksFromDb() {
        
        // load all tracks from db
        playListTracksInCloud = CoreStore.defaultStack.fetchAll(
             From<StreamPlayListTracks>()
                .where(\StreamPlayListTracks.playlist == playListInDb)
                .orderBy(.ascending(\StreamPlayListTracks.trackAddedAt))
        )
        
        print (playListTracksInCloud?.count)
        
        // load playlist local cache from db (refresh)
        playListInDb = CoreStore.defaultStack.fetchOne(
            From<StreamPlayList>()
                .where(\StreamPlayList.metaListHash == playListInDb!.getMD5Identifier())
        )
        
        print (playListInDb?.getMD5Identifier())
        
         // init shuffled key stack for shuffle-play-mode
        if  playListTracksInCloud != nil {
            playListTracksShuffleKeys = getRandomUniqueNumberArray(
                forLowerBound: 0,
                andUpperBound: playListTracksInCloud!.count,
                andNumNumbers: playListTracksInCloud!.count
            )
        }
    }
}
