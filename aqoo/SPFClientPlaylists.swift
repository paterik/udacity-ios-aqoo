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
    
    //
    // MARK: Constants (Special)
    //
    
    let debugMode: Bool = false
    let notifier = SPFEventNotifier()
    let playlistCoverDefaultURL = "https://www.dropbox.com/s/t2aaqgqhojmvxw8/img_cover_override%20255x255%20v1.png"
    
    //
    // MARK: Variables
    //
    
    // primary api proxy meta objects
    var playlistsInCache = [StreamPlayList]()
    var playlistsInCloud = [SPTPartialPlaylist]()
    var playlistsInCloudExtended = [ProxyStreamPlayListExtended]()
    var playlistTracksInCloud = [ProxyStreamPlayListTrack]()
    var playlistTracksLastUpdate = Date()
    var playlistRefreshEnforced: Bool = false
    
    // secondary internal proxy meta objects
    var playListHashesInCloud = [String]()
    var playListHashesInCache = [String]()
    
    // some helper vars
    var playListDefaultImage: UIImage?
    var playlistInCloudExtendedHandled: Int = 0
    
    //
    // MARK: API Methods
    //
    
    func handlePlaylistTrackByProxy(_ track: SPTPlaylistTrack, _ playlist: SPTPartialPlaylist) -> String? {
        
        if track.isPlayable == false { return nil }
        
        let playlistIdentifier = playlist.getMD5Identifier()
        
        if  debugMode == true {
            var _dateAdded : NSDate = track.addedAt as! NSDate
            var _dateAddedHR : String = _dateAdded.dateToString(_dateAdded as Date!, "dd.MM.Y hh:mm") as String
            
            print("-<n>-[\(playlistIdentifier)] Track=[\(track.name)]")
            print("     id = \(track.identifier)")
            print("     artist = \(track.artists.count)")
            print("     uri_internal = \(track.uri.absoluteString)")
            print("     duration = \(self.stringFromTimeInterval(interval: track.duration))")
            print("     accessable = \(track.isPlayable)")
            print("     explicit = \(track.flaggedExplicit)")
            print("     popularity = \(track.popularity)")
            print("     album_name = \(track.album.name)")
            print("     album_disc_number = \(track.discNumber)")
            print("     album_track_number = \(track.trackNumber)")
            print("     added_at = \(_dateAddedHR)")
            if  track.discNumber != 0 {
                print("     album_cover_largest_src = \(track.album.largestCover.imageURL.absoluteString)")
                print("     album_cover_smallest_src = \(track.album.smallestCover.imageURL.absoluteString)")
            }
        }
        
        var trackArtists = [SPTPartialArtist]()
        
        for artist in track.artists {
            trackArtists.append(artist as! SPTPartialArtist)
        }
        
        var playlistsTrack = ProxyStreamPlayListTrack(
            plIdentifier : playlistIdentifier,
            tIdentifier : track.identifier,
            tURIInternal : track.uri,
            tDuration : track.duration,
            tExplicit : track.flaggedExplicit,
            tPopularity : track.popularity,
            tAddedAt: track.addedAt as! NSDate,
            tTrackNumber : track.trackNumber,
            tDiscNumber : track.discNumber,
            tName : track.name,
            tArtists: trackArtists,
            aName : track.album.name
        )
        
        // discNumber = 0 means single song / may direct spotify production, no album available
        if  track.discNumber != 0 {
            playlistsTrack.albumCoverLargestImageURL = track.album.largestCover.imageURL.absoluteString
            playlistsTrack.albumCoverSmallestImageURL = track.album.smallestCover.imageURL.absoluteString
        }
        
        self.playlistTracksInCloud.append(playlistsTrack)
        
        var coverUrl = playlistCoverDefaultURL
        
        if  track.album.largestCover != nil {
            coverUrl = track.album.largestCover.imageURL.absoluteString
        }
        
        if  track.album.smallestCover != nil {
            coverUrl = track.album.smallestCover.imageURL.absoluteString
        }
        
        return coverUrl
    }
    
    func handlePlaylistTracksGetNextPage(
        _ playlist: SPTPartialPlaylist,
        _ currentPage: SPTListPage,
        _ accessToken: String) {
        
        currentPage.requestNextPage(
            
            withAccessToken: accessToken,
            callback: {
                
                ( error, response ) in
                
                if  let _nextPage = response as? SPTListPage,
                    let _playlistTracks = _nextPage.items as? [SPTPlaylistTrack] {
                   
                    for _track in _playlistTracks {
                        if  let _playlistTrack = _track as? SPTPlaylistTrack {
                            self.handlePlaylistTrackByProxy( _playlistTrack, playlist )
                        }
                    }
                    
                    if _nextPage.hasNextPage == true {
                        self.handlePlaylistTracksGetNextPage( playlist, _nextPage, accessToken )
                    }
                }
            }
        )
    }
    
    func handlePlaylistTracksGetFirstPage(
       _ playistItems : [SPTPartialPlaylist],
       _ accessToken: String ) {
        
        for playlist in playistItems  {
            
            let uri = URL(string: playlist.uri.absoluteString)
            var playlistCoverURLFromFirstTrack: String?
            
            // use SPTPlaylistSnapshot to get fetch playlist snapshots incl tracks
            SPTPlaylistSnapshot.playlist(withURI: uri!, accessToken: accessToken) {
                (error, snap) in
                
                self.playlistInCloudExtendedHandled += 1
                
                if  let _snapshot = snap as? SPTPlaylistSnapshot {
                    
                    // all playlist items handled? Send completion call ...
                    if  self.playlistInCloudExtendedHandled == self.playlistsInCloud.count {
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.notifier.notifyPlaylistMetaExtendLoadCompleted),
                            object: self
                        )
                    }
                    
                    // handle firstPage track objects
                    let _firstPage : SPTListPage = _snapshot.firstTrackPage
                    for (index, _track) in _firstPage.items.enumerated() {
                        
                        if let _playlistTrack = _track as? SPTPlaylistTrack {
                            var tmpCover = self.handlePlaylistTrackByProxy( _playlistTrack, playlist )
                            if  index == 0 {
                                // set the playlistCover based on first Track of this list
                                playlistCoverURLFromFirstTrack = tmpCover
                            }
                        }
                    }
                    
                    // extend playlist with addtional meta information using proxy collection object
                    var playlistsExtended = ProxyStreamPlayListExtended(
                        identifier: playlist.getMD5Identifier(),
                        snapshotId: _snapshot.snapshotId,
                        followerCount: _snapshot.followerCount,
                        coverUrl: playlistCoverURLFromFirstTrack ?? nil
                    );  self.playlistsInCloudExtended.append(playlistsExtended)
                    
                    // handle all nextPage track objects
                    if _firstPage.hasNextPage {
                        self.handlePlaylistTracksGetNextPage(playlist, _firstPage, accessToken)
                    }
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
                    self.handlePlaylistTracksGetFirstPage(_playlists, accessToken)
                    
                    if _nextPage.hasNextPage == false {
                        // no further entries in pagination? send completion call ...
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
        
        // clear proxy meta collections
        playlistsInCloud.removeAll()
        playlistsInCloudExtended.removeAll()
        playlistTracksInCloud.removeAll()
        
        SPTPlaylistList.playlists(
            
            forUser: username,
            withAccessToken: accessToken,
            callback: {
                
                ( error, response ) in
                
                if  let _firstPage = response as? SPTPlaylistList,
                    let _playlists = _firstPage.items as? [SPTPartialPlaylist] {
                    
                    self.playlistsInCloud = _playlists
                    self.handlePlaylistTracksGetFirstPage(_playlists, accessToken)
                    
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
    
    //
    // MARK: Helper Methods (internal)
    //
    
    fileprivate func stringFromTimeInterval(interval: TimeInterval) -> String {
        
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
