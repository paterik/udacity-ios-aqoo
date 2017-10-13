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
    
    @objc func setupUILoadExtendedPlaylists() {
        
        
        
        if let _playListCache = CoreStore.fetchAll(
                From<StreamPlayList>().where(
                    (\StreamPlayList.owner == appDelegate.spfUsername) &&
                    (\StreamPlayList.provider == _defaultStreamingProvider)
                )
            )
        {
            
            print ("--------------------------------------------------")
            print ("\(_playListHashesInCloud.count) playlists in cloud")
            print ("\(_playListHashesInDb.count) playlists in db")
            print ("--------------------------------------------------")
            
           _playlistsInDb = _playListCache
            print ("cache: (re)evaluated, tableView will be refreshed now ...")
        }
        
        tableView.reloadData()
    }
    
    @objc func setupUILoadCloudPlaylists() {
        
        var _playListHash: String!; _playListHashesInCloud = [] ; _playListHashesInDb = []
        
        print ("\nAQOO just found \(_playlistsInCloud.count) playlist(s) for current user\n==\n")
        for (playlistIndex, playListInCloud) in _playlistsInCloud.enumerated() {
            
            _playListHash = self.getMetaListHashByParam (
                playListInCloud.playableUri.absoluteString,
                self.appDelegate.spfUsername
            )
            
            print ("list: #\(playlistIndex) containing \(playListInCloud.trackCount) playable songs")
            print ("name: \(playListInCloud.name!)")
            print ("uri: \(playListInCloud.playableUri!)")
            print ("hash: \(_playListHash!) (aqoo identifier)")
            print ("\n--\n")
            
            handlePlaylistDbCache (playListInCloud, playlistIndex, _defaultStreamingProviderTag)
        }
    }
    
    func setupUITableView() {
    
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setupUIMainMenuView() { }
    
    func handleNewUserPlaylistSession() {
        
        print ("_ try to synchronize playlists for provider [\(_defaultStreamingProviderTag)] ...")
        loadProvider ( _defaultStreamingProviderTag )
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
                    
                    self._playlistsInCloud.append(contentsOf: _playlists)

                    if _nextPage.hasNextPage == false {
                        // no further entries in pagination? send completion call now ...
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.appDelegate.spfSessionPlaylistLoadCompletedNotifierId),
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
        
        SPTPlaylistList.playlists(
            
            forUser: username,
            withAccessToken: accessToken,
            callback: {
                
               ( error, response ) in
                
                if  let _firstPage = response as? SPTPlaylistList,
                    let _playlists = _firstPage.items as? [SPTPartialPlaylist] {
                    
                    self._playlistsInCloud = _playlists

                    if _firstPage.hasNextPage == false {
                        // no further entries in pagination? send completed call!
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.appDelegate.spfSessionPlaylistLoadCompletedNotifierId),
                            object: self
                        )
                        
                    } else { self.handlePlaylistGetNextPage( _firstPage, accessToken ) }
                }
            }
        )
    }
    
    func getMetaListHashByParam(_ playListPlayableUri: String, _ playListOwner: String) -> String {
        
         return String( format: "%@:%@", playListPlayableUri, playListOwner).md5()
    }
    
    func handlePlaylistDbCacheOrphans () {
        
        if let _playListCache = CoreStore.defaultStack.fetchAll(
            From<StreamPlayList>().where(
                (\StreamPlayList.owner == appDelegate.spfUsername) &&
                (\StreamPlayList.provider == _defaultStreamingProvider)
            )
        ) {
            
            for (_, playlist) in _playListCache.enumerated() {
                
                // ignore all known / identical playlists
                if  self._playListHashesInCloud.contains(playlist.metaListHash) {
                    self._playListHashesInDb.append(playlist.metaListHash); continue
                }
            
                // kill all obsolete/orphan cache entries
                print ("cache: playlist data hash [\(playlist.metaListHash)] orphan flagged for removal")
                CoreStore.perform(
                    asynchronous: { (transaction) -> Void in
                        let orphanPlaylist = transaction.fetchOne(
                            From<StreamPlayList>().where((\StreamPlayList.metaListHash == playlist.metaListHash))
                        );  transaction.delete(orphanPlaylist)
                    },
                    
                    completion: { _ in
                        print ("cache: playlist data hash [\(playlist.metaListHash)] handled -> REMOVED")
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.appDelegate.spfCachePlaylistLoadCompletedNotifierId),
                            object: self
                        )
                    }
                )
            }
        }
    }
    
    func handlePlaylistDbCache (
       _ playListInCloud: SPTPartialPlaylist,
       _ playListIndex: Int,
       _ providerTag: String ) {
        
        var _playlistInDb: StreamPlayList?
        var _playListHash: String!

        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                // render hash for new playlist entry
                _playListHash = self.getMetaListHashByParam (
                    playListInCloud.playableUri.absoluteString,
                    self.appDelegate.spfUsername
                )
                
                // we've a corresponding (given) playlist entry in db? Check this entry again and prepare for update
                _playlistInDb = transaction.fetchOne(
                    From<StreamPlayList>().where((\StreamPlayList.metaListHash == _playListHash))
                )
                
                // playlist cache entry in local db not available or not fetchable? Create a new one ...
                if _playlistInDb == nil {
                    
                    _playlistInDb = transaction.create(Into<StreamPlayList>()) as StreamPlayList
                    
                    _playlistInDb!.name = playListInCloud.name
                    _playlistInDb!.trackCount = Int32(playListInCloud.trackCount)
                    _playlistInDb!.isCollaborative = playListInCloud.isCollaborative
                    _playlistInDb!.isPublic = playListInCloud.isPublic
                    _playlistInDb!.metaLastListenedAt = nil
                    _playlistInDb!.metaNumberOfUpdates = 0
                    _playlistInDb!.metaNumberOfShares = 0
                    _playlistInDb!.metaMarkedAsFavorite = false
                    _playlistInDb!.metaListHash = _playListHash
                    _playlistInDb!.createdAt = Date()
                    _playlistInDb!.owner = self.appDelegate.spfUsername
                    _playlistInDb!.provider = transaction.fetchOne(
                        From<StreamProvider>().where((\StreamProvider.tag == providerTag))
                    )
                    
                    print ("cache: playlist data hash [\(_playlistInDb!.metaListHash)] handled -> CREATED")
                
                // playlist cache entry found in local db? Check for changes and may update corresponding cache value ...
                } else {
                 
                    if _playlistInDb!.getMD5FingerPrint() == playListInCloud.getMD5FingerPrint() {
                        
                        print ("cache: playlist data hash [\(_playlistInDb!.name)] handled -> IGNORED")
                        
                    } else {
                        
                        _playlistInDb!.name = playListInCloud.name
                        _playlistInDb!.trackCount = Int32(playListInCloud.trackCount)
                        _playlistInDb!.isCollaborative = playListInCloud.isCollaborative
                        _playlistInDb!.isPublic = playListInCloud.isPublic
                        _playlistInDb!.metaNumberOfUpdates += 1
                        _playlistInDb!.updatedAt = Date()
                        
                        print ("cache: playlist data hash [\(_playlistInDb!.metaListHash)] handled -> UPDATED")
                    }
                }
            },
            
            completion: { _ in
                
                // save handled hashed in separate collection
                self._playListHashesInCloud.append(_playListHash)
                
                // evaluate list extension completion and execute event signal after final cache item was handled
                if playListIndex == self._playlistsInCloud.count - 1 {
                    self.handlePlaylistDbCacheOrphans()
                    print ("cache: playlist data analytics completed, send signal to reload tableView now ...")
                    NotificationCenter.default.post(
                        name: NSNotification.Name.init(rawValue: self.appDelegate.spfCachePlaylistLoadCompletedNotifierId),
                        object: self
                    )
                }
            }
        )
    }
    
    func loadPlaylists (_ provider: StreamProvider) {
        
        let providerName = provider.name

        // always fetch new playlists from api for upcoming sync
        print ("_ load and synchronize playlists for provider [\(providerName)]")
        self.handlePlaylistGetFirstPage(
            self.appDelegate.spfUsername,
            self.appDelegate.spfCurrentSession!.accessToken!
        )
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [StreamPlayList]? in
                
                self._defaultStreamingProvider = provider
                
                return transaction.fetchAll(
                    From<StreamPlayList>().where(
                        (\StreamPlayList.owner == self.appDelegate.spfUsername) &&
                        (\StreamPlayList.provider == provider)
                    )
                )
            },
            
            success: { (transactionPlaylists) in
                
                if transactionPlaylists?.isEmpty == false {
                    
                    // store database fetch results in cache collection
                    self._playlistsInDb = transactionPlaylists!
                    print ("_ \(transactionPlaylists!.count) playlists for provider [\(providerName)] available ...")
                    
                } else {
                    
                    // clean previously cached playlist collection
                    self._playlistsInDb = []
                    print ("_ no cached playlist data for provider [\(providerName)] found ...")
                }
            },
            
            failure: { (error) in
                self._handleErrorAsDialogMessage(
                    "Error Loading Playlists",
                    "Oops! An error occured while loading playlists of [\(providerName)] from database ..."
                )
            }
        )
    }
    
    func loadProvider (_ tag: String) {
        
        print ("_ try to load provider [\(tag)]")
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> StreamProvider? in
                
                return transaction.fetchOne(From<StreamProvider>().where(\StreamProvider.tag == tag))
            },
            
            success: { (transactionProvider) in
                
                if transactionProvider != nil {
                    
                    print ("_ provider [\(tag)] successfully loaded, now try to load cached playlists ...")
                    self._playListProvider = transactionProvider!
                    self.loadPlaylists ( self._playListProvider! )
                    
                }   else {
                    
                    self._handleErrorAsDialogMessage(
                        "Error Loading Provider",
                        "Oops! No provider were found in database ..."
                    )
                }
            },
            
            failure: { (error) in
                self._handleErrorAsDialogMessage(
                    "Error Loading Provider",
                    "Oops! An error occured while loading provider from database ..."
                )
            }
        )
    }
}
