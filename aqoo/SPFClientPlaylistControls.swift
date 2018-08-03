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
    
    static let sharedInstance = SPFClientPlaylistControls()
    
    let debugMode: Bool = true
    
    func setTrackInPlayState(
       _ trackInDb : StreamPlayListTracks,
       _ isPlaying: Bool) {
        
        // set new playMode for current track now
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                let trackInDb = transaction.edit(trackInDb)!
                    trackInDb.metaTrackIsPlaying = isPlaying
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }
                case .success(let userInfo):
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist/track] : set playState for [\(trackInDb.trackName)] to [\(isPlaying)]")
                    }
                }
            }
        )
    }
    
    func setTrackTimePositionWhilePlaying(
       _ trackInDb : StreamPlayListTracks,
       _ newTrackTimePosition: Int ) {
        
        // set new timeFrame position for current track
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                let trackInDb = transaction.edit(trackInDb)!
                    trackInDb.metaTrackLastTrackPosition = newTrackTimePosition
                
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }
                case .success(let userInfo):
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist/track] : set timeFrame position for [\(trackInDb.trackName)] to [\(newTrackTimePosition)]")
                    }
                }
            }
        )
    }
    
    func setPlayModeOnPlaylist(
       _ playlistInDb : StreamPlayList,
       _ newPlayMode: Int16) {
        
        // set new playMode for current playlist now
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                let playlistInDb = transaction.edit(playlistInDb)!
                    playlistInDb.currentPlayMode = newPlayMode
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }
                case .success(let userInfo):
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist] : set playMode for [\(playlistInDb.metaListInternalName)] to [\(newPlayMode)]")
                    }
                }
            }
        )
    }
    
    func resetPlayModeOnAllPlaylists() {
        
        if  let playListPlayModeCache = CoreStore.defaultStack.fetchAll(From<StreamPlayList>()) as? [StreamPlayList] {
            for playlist in playListPlayModeCache {
                
                CoreStore.perform(
                    asynchronous: { (transaction) -> Void in playlist.currentPlayMode = 0 },
                    completion: { (result) -> Void in
                        switch result {
                        case .failure(let error): if self.debugMode == true { print (error) }
                        case .success(let userInfo): break }
                    }
                )
            }
        }
    }
}
