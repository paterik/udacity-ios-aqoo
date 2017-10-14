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
                    (\StreamPlayList.owner == spotifyClient.spfUsername) &&
                    (\StreamPlayList.provider == _defaultStreamingProvider)
                )
            )
        {
            
            if debugMode == true {
                
                print ("cache: (re)evaluated, tableView will be refreshed now ...")
                print ("--------------------------------------------------")
                print ("\(spotifyClient.playListHashesInCloud.count) playlists in cloud")
                print ("\(spotifyClient.playListHashesInCache.count) playlists in db/cache")
                print ("--------------------------------------------------")
            }
            
           spotifyClient.playlistsInCache = _playListCache
        }
        
        tableView.reloadData()
    }
    
    @objc func setupUILoadCloudPlaylists() {
        
        var _playListHash: String!;
        
        spotifyClient.playListHashesInCloud = []
        spotifyClient.playListHashesInCache = []
        
        for (playlistIndex, playListInCloud) in spotifyClient.playlistsInCloud.enumerated() {
            
            _playListHash = spotifyClient.getMetaListHashByParam (
                playListInCloud.playableUri.absoluteString,
                spotifyClient.spfUsername
            )
            
            if debugMode == true {
                
                print ("\nlist: #\(playlistIndex) containing \(playListInCloud.trackCount) playable songs")
                print ("name: \(playListInCloud.name!)")
                print ("owner: \(playListInCloud.owner.canonicalUserName!)")
                
                print ("imagesCount: \(playListInCloud.images.count)")
                
                if playListInCloud.images.count > 0 {
                    
                    for (index, image) in playListInCloud.images.enumerated() {
                        
                        if  let _rawImage = image as? SPTImage {
                            if  _rawImage.size != CGSize(width:0, height:0) {
                                let _imageUrl = _rawImage.imageURL.absoluteString
                                print ("image #\(index): \(_rawImage) -> \(_imageUrl)")
                            }
                        }
                    }
                }
                
                print ("uri: \(playListInCloud.playableUri!)")
                print ("hash: \(_playListHash!) (aqoo identifier)")
                print ("\n--")
            }
            
            handlePlaylistDbCache (playListInCloud, playlistIndex, spotifyClient.spfStreamingProviderDbTag)
        }
    }
    
    func setupUITableView() {
    
        tableView.delegate = self
        tableView.dataSource = self
        
        spotifyClient.getDefaultPlaylistImageByUserPhoto(spotifyClient.spfCurrentSession!)
    }
    
    func setupUIEventObserver() {
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.setupUILoadCloudPlaylists),
            name: NSNotification.Name(rawValue: self.notifier.notifyPlaylistLoadCompleted),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.setupUILoadExtendedPlaylists),
            name: NSNotification.Name(rawValue: self.notifier.notifyPlaylistCacheLoadCompleted),
            object: nil
        )
    }
    
    func handlePlaylistCloudRefresh() {
        
        if spotifyClient.isSpotifyTokenValid() {
            
            if  debugMode == true {
                print ("dbg [playlists] : try to synchronize playlists for provider [\(spotifyClient.spfStreamingProviderDbTag)] ...")
            };  loadProvider ( spotifyClient.spfStreamingProviderDbTag )
            
        } else {
            
            if  debugMode == true {
                print ("dbg [playlists] : oops, your cloudProviderToken is not valid anymore")
            };  btnExitLandingPageAction( self )
        }
    }
    
    func handlePlaylistDbCacheOrphans () {
        
        if let _playListCache = CoreStore.defaultStack.fetchAll(
            From<StreamPlayList>().where(
                (\StreamPlayList.owner == spotifyClient.spfUsername) &&
                (\StreamPlayList.provider == _defaultStreamingProvider)
            )
        ) {
            
            for (_, playlist) in _playListCache.enumerated() {
                
                // ignore all known / identical playlists
                if spotifyClient.playListHashesInCloud.contains(playlist.metaListHash) {
                   spotifyClient.playListHashesInCache.append(playlist.metaListHash); continue
                }
            
                // kill all obsolete / orphan cache entries
                if debugMode == true {
                    print ("cache: playlist data hash [\(playlist.metaListHash)] orphan flagged for removal")
                }
                
                CoreStore.perform(
                    
                    asynchronous: { (transaction) -> Void in
                        let orphanPlaylist = transaction.fetchOne(
                            From<StreamPlayList>().where((\StreamPlayList.metaListHash == playlist.metaListHash))
                        );  transaction.delete(orphanPlaylist)
                    },
                    
                    completion: { _ in
                        
                        if self.debugMode == true {
                            print ("cache: playlist data hash [\(playlist.metaListHash)] handled -> REMOVED")
                        }
                        
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.notifier.notifyPlaylistCacheLoadCompleted),
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
                _playListHash = self.spotifyClient.getMetaListHashByParam (
                    playListInCloud.playableUri.absoluteString,
                    self.spotifyClient.spfUsername
                )
                
                // we've a corresponding (given) playlist entry in db? Check this entry again and prepare for update
                _playlistInDb = transaction.fetchOne(
                    From<StreamPlayList>().where((\StreamPlayList.metaListHash == _playListHash))
                )
                
                // playlist cache entry in local db not available or not fetchable? Create a new one ...
                if _playlistInDb == nil {
                    
                    _playlistInDb = transaction.create(Into<StreamPlayList>()) as StreamPlayList
                    
                    _playlistInDb!.name = playListInCloud.name
                    _playlistInDb!.playableURI = playListInCloud.playableUri.absoluteString
                    _playlistInDb!.trackCount = Int32(playListInCloud.trackCount)
                    _playlistInDb!.isCollaborative = playListInCloud.isCollaborative
                    _playlistInDb!.isPublic = playListInCloud.isPublic
                    _playlistInDb!.metaLastListenedAt = nil
                    _playlistInDb!.metaNumberOfUpdates = 0
                    _playlistInDb!.metaNumberOfShares = 0
                    _playlistInDb!.metaMarkedAsFavorite = false
                    _playlistInDb!.metaListHash = _playListHash
                    _playlistInDb!.createdAt = Date()
                    _playlistInDb!.owner = playListInCloud.owner.canonicalUserName
                    _playlistInDb!.provider = transaction.fetchOne(
                        From<StreamProvider>().where((\StreamProvider.tag == providerTag))
                    )
                    
                    if self.debugMode == true {
                        print ("cache: playlist data hash [\(_playlistInDb!.metaListHash)] handled -> CREATED")
                    }
                
                // playlist cache entry found in local db? Check for changes and may update corresponding cache value ...
                } else {
                 
                    if _playlistInDb!.getMD5FingerPrint() == playListInCloud.getMD5FingerPrint() {
                        
                        if self.debugMode == true {
                            print ("cache: playlist data hash [\(_playlistInDb!.name)] handled -> NO_CHANGES")
                        }
                        
                    } else {
                        
                        _playlistInDb!.name = playListInCloud.name
                        _playlistInDb!.trackCount = Int32(playListInCloud.trackCount)
                        _playlistInDb!.isCollaborative = playListInCloud.isCollaborative
                        _playlistInDb!.isPublic = playListInCloud.isPublic
                        _playlistInDb!.metaNumberOfUpdates += 1
                        _playlistInDb!.updatedAt = Date()
                        
                        if self.debugMode == true {
                            print ("cache: playlist data hash [\(_playlistInDb!.metaListHash)] handled -> UPDATED")
                        }
                    }
                }
            },
            
            completion: { _ in
                
                // save handled hashed in separate collection
                self.spotifyClient.playListHashesInCloud.append(_playListHash)
                
                // evaluate list extension completion and execute event signal after final cache item was handled
                if playListIndex == self.spotifyClient.playlistsInCloud.count - 1 {
                    
                    self.handlePlaylistDbCacheOrphans()
                    
                    if self.debugMode == true {
                        print ("cache: playlist data persistence completed, send signal to reload tableView now ...")
                    }
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name.init(rawValue: self.notifier.notifyPlaylistCacheLoadCompleted),
                        object: self
                    )
                }
            }
        )
    }
    
    func loadProvider (_ tag: String) {
        
        if self.debugMode == true { print ("dbg [playlists] : try to load provider [\(tag)]") }
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> StreamProvider? in
                
                return transaction.fetchOne(
                    From<StreamProvider>().where(
                        (\StreamProvider.tag == tag) && (\StreamProvider.isActive == true)
                    )
                )
            },
            
            success: { (transactionProvider) in
                
                if transactionProvider != nil {
                    if self.debugMode == true {
                        print ("dbg [playlists] : provider [\(tag)] successfully loaded, fetching playlists now")
                    }
                    
                    self.spotifyClient.spfStreamingProvider = transactionProvider!
                    self.loadProviderPlaylists ( self.spotifyClient.spfStreamingProvider! )
                    
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
    
    func loadProviderPlaylists (_ provider: StreamProvider) {
        
        if provider.tag != _supportedProviderTag {
            
            self._handleErrorAsDialogMessage(
                "Error Loading Provider",
                "Oops! The provider '\(provider.name)' isn't supported yet ..."
            )
            
            return
        }
        
        // first of all fetch new playlists from api for comparision
        spotifyClient.handlePlaylistGetFirstPage(
            spotifyClient.spfUsername,
            spotifyClient.spfCurrentSession!.accessToken!
        );
        
        // now fetch corresponding local playlists for sync process
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [StreamPlayList]? in
                
                self._defaultStreamingProvider = provider
                
                return transaction.fetchAll(
                    From<StreamPlayList>().where(
                        (\StreamPlayList.owner == self.spotifyClient.spfUsername) &&
                        (\StreamPlayList.provider == provider)
                    )
                )
            },
            
            success: { (transactionPlaylists) in
                
                if transactionPlaylists?.isEmpty == false {
                    
                    // store database fetch results in cache collection
                    if self.debugMode == true {
                        print ("dbg [playlists] : \(transactionPlaylists!.count) playlists for this provider available ...")
                    };  self.spotifyClient.playlistsInCache = transactionPlaylists!
                    
                } else {
                    
                    // clean previously cached playlist collection
                    if self.debugMode == true {
                        print ("dbg [playlists] : no cached playlist data for this provider found ...")
                    };  self.spotifyClient.playlistsInCache = []
                }
            },
            
            failure: { (error) in
                self._handleErrorAsDialogMessage(
                    "Error Loading Playlists",
                    "Oops! An error occured while loading playlists from database ..."
                )
            }
        )
    }
}
