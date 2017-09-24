//
//  PlaylistViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 20.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore

extension PlaylistViewController {
    
    func setupUILoadPlaylist() {
        
        print ("\nI've found \(_playlists.count) playlists for current user\n")
        print ("==\n")
        for (index, item) in _playlists.enumerated() {
            print ("list: #\(index)")
            print ("name: \(item.name!), \(item.trackCount) songs")
            print ("uri: \(item.playableUri!)")
            print ("\n--\n")
        }
        
        tableView.reloadData()
    }
    
    func setupUIMainMenuView() { }
    
    func setupUITableView() {
    
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func handleNewUserPlaylistSession() {
        
        _loadProvider("_spotify")
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
    
    func _loadProvider (_ tag: String) {
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> CoreStreamingProvider? in
                return transaction.fetchOne(From<CoreStreamingProvider>(), Where("tag", isEqualTo: tag))
            },
            
            success: { (transactionProvider) in
                
                if transactionProvider == nil {
                    self._handleErrorAsDialogMessage("Error Loading Provider", "Oops! No provider were found in database ...")
                }   else {
                    self._streamingProvider = transactionProvider!
                }
            },
            
            failure: { (error) in
                self._handleErrorAsDialogMessage("Error Loading Provider", "Oops! An error occured while loading provider from database ...")
            }
        )
    }
}
