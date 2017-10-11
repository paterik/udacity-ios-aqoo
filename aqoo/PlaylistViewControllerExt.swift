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
import CryptoSwift

extension PlaylistViewController {
    
    @objc func setupUILoadPlaylist() {
        
        print ("\nAQOO just found \(_playlistsInCloud.count) playlist(s) for current user in [\(_defaultStreamingProviderTag)] cloud\n")
        print ("==\n")
        
        for (index, playListInCloud) in _playlistsInCloud.enumerated() {
            
            print ("list: #\(index) containing \(playListInCloud.trackCount) playable songs")
            print ("name: \(playListInCloud.name!)")
            print ("uri: \(playListInCloud.playableUri!)")
            print ("\n--\n")
            
            handlePlaylistDbCache (playListInCloud, _defaultStreamingProviderTag)
        }
        
        tableView.reloadData()
    }
    
    func setupUITableView() {
    
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setupUIMainMenuView() { }
    
    func _handlePlaylistGetNextPage(_ currentPage: SPTListPage, _ accessToken: String) {
        
        currentPage.requestNextPage(
            
            withAccessToken: accessToken,
            callback: {
                
               ( error, response ) in
                
                if  let _nextPage = response as? SPTListPage,
                    let _playlists = _nextPage.items as? [SPTPartialPlaylist] {
                    
                    self._playlistsInCloud.append(contentsOf: _playlists)
                    
                    // check for additional subPages
                    if _nextPage.hasNextPage == false {
                        // no further entries in pagination? send completion call now ...
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
                    
                    self._playlistsInCloud = _playlists
                    
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
    
    func handleNewUserPlaylistSession() {
        
        print ("_ try to synchronize playlists for provider [\(_defaultStreamingProviderTag)] ...")
        loadProvider ( _defaultStreamingProviderTag )
    }
    
    func handlePlaylistDbCache (
       _ playListInCloud: SPTPartialPlaylist,
       _ providerTag: String ) {
        
        var _playlistInDb: StreamPlayList?

        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                // we've a corresponding (given) playlist entry in db? Check this entry again and prepare for update
                _playlistInDb = transaction.fetchOne(
                    From<StreamPlayList>(),
                    Where("metaListHash", isEqualTo: playListInCloud.playableUri.absoluteString.md5())
                )
                
                // playlist cache entry in local db not available or not fetchable? Create a new one ...
                if _playlistInDb == nil {
                    
                    _playlistInDb = transaction.create(Into<StreamPlayList>()) as StreamPlayList
                    
                    _playlistInDb!.name = playListInCloud.name
                    _playlistInDb!.trackCount = Int64(playListInCloud.trackCount)
                    _playlistInDb!.isCollaborative = playListInCloud.isCollaborative
                    _playlistInDb!.isPublic = playListInCloud.isPublic
                    _playlistInDb!.metaLastListenedAt = nil
                    _playlistInDb!.metaNumberOfUpdates = 0
                    _playlistInDb!.metaNumberOfShares = 0
                    _playlistInDb!.metaMarkedAsFavorite = false
                    _playlistInDb!.metaListHash = playListInCloud.playableUri.absoluteString.md5()
                    _playlistInDb!.createdAt = Date()
                    _playlistInDb!.owner = self.appDelegate.spfUsername
                    _playlistInDb!.provider = transaction.fetchOne(
                        From<CoreStreamingProvider>(),
                        Where("tag", isEqualTo: providerTag)
                    )
                    
                    print ("cache: playlist data hash [\(_playlistInDb!.metaListHash)] -> CREATED")
                
                // playlist cache entry found in local db? Check for changes and may update corresponding cache value ...
                } else {
                 
                    if _playlistInDb!.getMD5FingerPrint() == playListInCloud.getMD5FingerPrint() {
                        
                        print ("cache: playlist data hash [\(_playlistInDb!.metaListHash)] -> INGORED (no changes evaluated)")
                        
                    } else {
                        
                        _playlistInDb!.name = playListInCloud.name
                        _playlistInDb!.trackCount = Int64(playListInCloud.trackCount)
                        _playlistInDb!.isCollaborative = playListInCloud.isCollaborative
                        _playlistInDb!.isPublic = playListInCloud.isPublic
                        _playlistInDb!.metaNumberOfUpdates += 1
                        _playlistInDb!.updatedAt = Date()
                        
                        print ("cache: playlist data hash [\(_playlistInDb!.metaListHash)] -> UPDATED")
                    }
                }
            },
            completion: { _ in }
        )
    }
    
    func loadPlaylists (_ provider: CoreStreamingProvider) {
        
        _playListProvider = provider
        
        let providerName = provider.name
        
        print ("_ load cached playlists for provider [\(providerName)]")
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [StreamPlayList]? in
                
                self._defaultStreamingProvider = provider
                
                return transaction.fetchAll(
                    From<StreamPlayList>(),
                    Where("provider", isEqualTo: provider) &&
                        Where("owner", isEqualTo: self.appDelegate.spfUsername)
                )
            },
            success: { (transactionPlaylists) in
                
                if transactionPlaylists?.isEmpty == false {
                    
                    print ("_ \(transactionPlaylists!.count) playlists for provider [\(providerName)] available ...")
                    
                    // store database fetch results in cache collection
                    self._playlistsInDb = transactionPlaylists!
                    
                } else {
                    
                    print ("_ no cached playlist data for provider [\(providerName)] found, we'll create cache on first listView load ...")
                    
                    // clean previously cached playlist collection
                    self._playlistsInDb = []
                }
                
                // always fetch new playlists from api for upcoming sync
                self._handlePlaylistGetFirstPage(
                    self.appDelegate.spfUsername,
                    self.appDelegate.spfCurrentSession!.accessToken!
                )
            },
            failure: { (error) in
                    self._handleErrorAsDialogMessage("Error Loading Provider", "Oops! An error occured while loading provider from database ...")
            }
        )
    }
    
    func loadProvider (_ tag: String) {
        
        print ("_ try to load provider [\(tag)]")
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> CoreStreamingProvider? in
                return transaction.fetchOne(From<CoreStreamingProvider>(), Where("tag", isEqualTo: tag))
            },
            
            success: { (transactionProvider) in
                
                if transactionProvider != nil {
                    
                    print ("_ provider [\(tag)] successfully loaded, now try to load cached playlists ...")
                    self.loadPlaylists ( transactionProvider! )
                    
                }   else {
                    
                    self._handleErrorAsDialogMessage("Error Loading Provider", "Oops! No provider were found in database ...")
                }
            },
            
            failure: { (error) in
                self._handleErrorAsDialogMessage("Error Loading Provider", "Oops! An error occured while loading provider from database ...")
            }
        )
    }
}
