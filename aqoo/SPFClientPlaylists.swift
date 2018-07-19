//
//  SPFClientPlaylists.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 14.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class SPFClientPlaylists: NSObject {
    
    let notifier = SPFEventNotifier()
    
    var playlistsInCache = [StreamPlayList]()
    var playlistsInCloud = [SPTPartialPlaylist]()
    var playlistsInCloudExtended = [StreamPlayListExtended]()
    
    var playListHashesInCloud = [String]()
    var playListHashesInCache = [String]()
    var playListDefaultImage: UIImage?
    
    func handlePlaylistTracks(_ playistItems : [SPTPartialPlaylist], _ accessToken: String ) {
        
        for _playlist in playistItems  {
            
            let stringFromUrl = _playlist.uri.absoluteString
            let uri = URL(string: stringFromUrl)
            // use SPTPlaylistSnapshot to get fetch playlist snapshots incl tracks
            SPTPlaylistSnapshot.playlist(withURI: uri, accessToken: accessToken) {
                (error, snap) in
                
                print ("== try to handle: \(_playlist.name!)")
                
                if  let _snapshot = snap as? SPTPlaylistSnapshot {
                    
                    print ("   handle:okay")
                    var _playlistsExtended = StreamPlayListExtended(
                        _playlist.name!,
                        _playlist.getMD5Identifier(),
                        _snapshot.snapshotId!,
                        _snapshot.followerCount)
                    
                    self.playlistsInCloudExtended.append(_playlistsExtended)
                }   else {
                    
                    print ("    error!")
                }
            }
        }
    }
    
    func handlePlaylistGetNextPage(
       _ currentPage: SPTListPage,
       _ accessToken: String) {
        
        currentPage.requestNextPage(
            
            withAccessToken: accessToken,
            callback: {
                
                ( error, response ) in
                
                if  let _nextPage = response as? SPTListPage,
                    let _playlists = _nextPage.items as? [SPTPartialPlaylist] {
                    
                    self.playlistsInCloud.append(contentsOf: _playlists)
                    self.handlePlaylistTracks(_playlists, accessToken)
                    
                    if _nextPage.hasNextPage == false {
                        // no further entries in pagination? send completion call now ...
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.notifier.notifyPlaylistLoadCompleted),
                            object: self
                        )
                        
                    } else { self.handlePlaylistGetNextPage( _nextPage, accessToken ) }
                }
            }
        )
    }
    
    func handlePlaylistGetFirstPage(
       _ username: String,
       _ accessToken: String) {
        
        playlistsInCloud.removeAll()
        playlistsInCloudExtended.removeAll()
        
        SPTPlaylistList.playlists(
            
            forUser: username,
            withAccessToken: accessToken,
            callback: {
                
                ( error, response ) in
                
                if  let _firstPage = response as? SPTPlaylistList,
                    let _playlists = _firstPage.items as? [SPTPartialPlaylist] {
                    
                    self.playlistsInCloud = _playlists
                    self.handlePlaylistTracks(_playlists, accessToken)
                    
                    if _firstPage.hasNextPage == false {
                        // no further entries in pagination? send completed call!
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.notifier.notifyPlaylistLoadCompleted),
                            object: self
                        )
                        
                    } else { self.handlePlaylistGetNextPage( _firstPage, accessToken ) }
                }
            }
        )
    }
    
    fileprivate func stringFromTimeInterval(interval: TimeInterval) -> String {
        
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
