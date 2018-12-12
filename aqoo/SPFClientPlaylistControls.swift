//
//  SPFClientPlaylistControls.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 02.08.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import CryptoSwift

class SPFClientPlaylistControls {
    
    //
    // MARK: Constants
    //
    
    static let sharedInstance = SPFClientPlaylistControls()
    
    let debugMode: Bool = true
    
    func setTrackInPlayState(
       _ trackInDb : StreamPlayListTracks,
       _ isPlaying: Bool) {
        
        // set new playMode for current track now
        CoreStore.defaultStack.perform(
            
            asynchronous: { (transaction) -> Void in
                
                let trackInDb = transaction.edit(trackInDb)!
                    trackInDb.metaTrackIsPlaying = isPlaying
                
                if  isPlaying == false {
                    trackInDb.metaTrackLastTrackPosition = 0
                }
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode { print (error) }
                case .success(let userInfo):
                    
                    if  self.debugMode {
                        print ("dbg [playlist/track] : set playState for [\(trackInDb.trackIdentifier!)] to [\(isPlaying)]")
                    }
                }
            }
        )
    }
    
    func setTrackTimePositionWhilePlaying(
       _ trackInDb : StreamPlayListTracks,
       _ newTrackTimePosition: Int ) {
        
        // set new timeFrame position for current track
        CoreStore.defaultStack.perform(
            
            asynchronous: { (transaction) -> Void in
                
                let trackInDb = transaction.edit(trackInDb)!
                    trackInDb.metaTrackLastTrackPosition = newTrackTimePosition
                
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode { print (error) }
                case .success(let userInfo):
                    
                    if  self.debugMode {
                        print ("dbg [playlist/track] : playing stream, set timeFrame position for [\(trackInDb.trackIdentifier!)] to [\(newTrackTimePosition)]")
                    }
                }
            }
        )
    }
    
    func setPlayModeOnPlaylist(
       _ playlistInDb : StreamPlayList,
       _ newPlayMode: Int16) {
        
        // set new playMode for current playlist now
        CoreStore.defaultStack.perform(
            
            asynchronous: { (transaction) -> Void in
                
                let playlistInDb = transaction.edit(playlistInDb)!
                    playlistInDb.currentPlayMode = newPlayMode
                
                if  newPlayMode != 0 {
                    playlistInDb.metaNumberOfPlayedPartly += 1
                    playlistInDb.metaNumberOfPlayed += 1
                    if  self.debugMode {
                        print ("dbg [playlist] : add metaNumberOfPlayedPartly stats to [\(playlistInDb.metaListInternalName)]")
                    }
                }
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode { print (error) }
                case .success(let userInfo):
                    
                    if  self.debugMode {
                        print ("dbg [playlist] : set playMode for [\(playlistInDb.metaListInternalName)] to [\(newPlayMode)]")
                    }
                }
            }
        )
    }
    
    func resetPlayModeOnAllPlaylists() {
        
        if  let playListPlayModeCache = CoreStore.defaultStack.fetchAll(From<StreamPlayList>()) as? [StreamPlayList] {
            for playlist in playListPlayModeCache {
                
                CoreStore.defaultStack.perform(
                    asynchronous: { (transaction) -> Void in playlist.currentPlayMode = 0 },
                    completion: { (result) -> Void in
                        switch result {
                        case .failure(let error): if self.debugMode { print (error) }
                        case .success(let userInfo): break }
                    }
                )
            }
        }
    }
    
    func resetPlayModeOnAllPlaylistTracks() {
        
        if  let playListTracksInCache = CoreStore.defaultStack.fetchAll(From<StreamPlayListTracks>()) as? [StreamPlayListTracks] {
            for playlistTrack in playListTracksInCache {
                
                CoreStore.defaultStack.perform(
                    asynchronous: { (transaction) -> Void in
                        
                        playlistTrack.metaTrackIsPlaying = false
                        playlistTrack.metaTrackLastTrackPosition = 0
                        
                    },
                    completion: { (result) -> Void in
                        switch result {
                        case .failure(let error): if self.debugMode { print (error) }
                        case .success(let userInfo): break }
                    }
                )
            }
        }
    }
}
