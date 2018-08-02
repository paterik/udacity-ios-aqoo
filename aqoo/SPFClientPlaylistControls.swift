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
    
    func setTrackInPlayState(_ trackInDb : StreamPlayListTracks, _ isPlaying: Bool) {
        
        // set new playMode for current track now
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in trackInDb.metaTrackIsPlaying = isPlaying },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }
                case .success(let userInfo):
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist] : set playState for [\(trackInDb.trackName)] to [\(isPlaying)]")
                    }
                }
            }
        )
    }
    
    func setTrackTimePositionWhilePlaying(_ trackInDb : StreamPlayListTracks, _ newTrackTimePosition: Int ) {
        
        // set new time position for current track
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                guard let track = transaction.fetchOne(
                    From<StreamPlayListTracks>()
                        .where(\.trackIdentifier == trackInDb.trackIdentifier)
                    ) as? StreamPlayListTracks else {
                    
                        print ("__ track not found :(")
                        return
                }
                
                track.metaTrackLastTrackPosition = newTrackTimePosition
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }
                case .success(let userInfo):
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist] : set timeframe position for [\(trackInDb.trackName)] to [\(newTrackTimePosition)]")
                    }
                }
            }
        )
    }
    
    func setPlayModeOnPlaylist(_ playlistInDb : StreamPlayList, _ newPlayMode: Int16) {
        
        // set new playMode for current playlist now
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in playlistInDb.currentPlayMode = newPlayMode },
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
        
        if  let _playListPlayModeCache = CoreStore.defaultStack.fetchAll(From<StreamPlayList>()) as? [StreamPlayList] {
            for playlist in _playListPlayModeCache {
                
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
