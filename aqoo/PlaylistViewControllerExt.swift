//
//  PlaylistViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 20.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

extension PlaylistViewController {
    
    func SetupUILoadPlaylist() {
        
        print ("\nI've found \(_playlists.count) playlists for current user\n")
        print ("==\n")
        for (index, item) in _playlists.enumerated() {
            print ("list: #\(index)")
            print ("name: \(item.name!), \(item.trackCount) songs")
            print ("uri: \(item.playableUri!)")
            print ("\n--\n")
        }
    }
    
    func handleNewUserPlaylistSession() {
        
        _handlePlaylistGetFirstPage(
            appDelegate.spfUsername,
            appDelegate.spfCurrentSession!.accessToken!
        )
    }
    
    func _handlePlaylistGetNextPage(_ currentPage: SPTListPage, _ accessToken: String) {
        
        currentPage.requestNextPage(
            
            withAccessToken: accessToken,
            callback: {
                
               ( error, response ) in
                
                if  let _nextPage = response as? SPTListPage,
                    let _playlists = _nextPage.items as? [SPTPartialPlaylist] {
                    
                    self._playlists.append(contentsOf: _playlists)
                    
                    // check for additional subPages
                    if _nextPage.hasNextPage == false {
                        // no further entries in pagination? send completed call!
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.appDelegate.spfSessionPlaylistLoadCompletedNotifierId),
                            object: self
                        )
                        
                    } else { self._handlePlaylistGetNextPage(_nextPage, accessToken) }
                }
            }
        )
    }
    
    func _handlePlaylistGetFirstPage(_ username: String, _ accessToken: String) {
        
        SPTPlaylistList.playlists(
            
            forUser: username,
            withAccessToken: accessToken,
            callback: {
                
               ( error, response ) in
                
                if  let _firstPage = response as? SPTPlaylistList,
                    let _playlists = _firstPage.items as? [SPTPartialPlaylist] {
                    
                    self._playlists = _playlists
                    
                    // check for additional pages
                    if _firstPage.hasNextPage == false {
                        // no further entries in pagination? send completed call!
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.appDelegate.spfSessionPlaylistLoadCompletedNotifierId),
                            object: self
                        )
                        
                    } else { self._handlePlaylistGetNextPage(_firstPage, accessToken) }
                }
            }
        )
    }
}
