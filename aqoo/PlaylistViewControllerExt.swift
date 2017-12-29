//
//  PlaylistViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 20.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import SnapKit
import CoreStore
import CryptoSwift
import Kingfisher

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
                print ("---------------------------------------------------------")
                print ("\(spotifyClient.playListHashesInCloud.count - 1) playlists in cloud")
                print ("\(spotifyClient.playListHashesInCache.count - 1) playlists in db/cache")
                print ("---------------------------------------------------------")
            }
            
           spotifyClient.playlistsInCache = _playListCache
        }
        
        tableView.reloadData()
    }
    
    @objc func setupUILoadCloudPlaylists() {
        
        var _playListFingerprint: String!;
        
        spotifyClient.playListHashesInCloud = []
        spotifyClient.playListHashesInCache = []
        
        for (playlistIndex, playListInCloud) in spotifyClient.playlistsInCloud.enumerated() {
            
            _playListFingerprint = spotifyClient.getMetaListHashByParam (
                playListInCloud.playableUri.absoluteString,
                spotifyClient.spfUsername
            )
            
            if debugMode == true {
                print ("\nlist: #\(playlistIndex) [ \(playListInCloud.name!) ] ➡ \(playListInCloud.trackCount) song(s)")
                print ("owner: \(playListInCloud.owner.canonicalUserName!) [ covers: \(playListInCloud.images.count) ]")
                print ("uri: \(playListInCloud.playableUri!)")
                print ("hash: \(_playListFingerprint!) [ aqoo fingerprint ]")
                print ("\n--")
            }
            
            handlePlaylistDbCacheCoreData (playListInCloud, playlistIndex, spotifyClient.spfStreamingProviderDbTag)
        }
    }
    
    func setupUITableView() {
        
        _cellHeights = Array(repeating: kCloseCellHeight, count: kRowsCount)
        
        tableView.estimatedRowHeight = kCloseCellHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    
        tableView.delegate = self
        tableView.dataSource = self
        
        let backgroundImgView : UIImageView! = UIImageView(frame: view.bounds)
        
        backgroundImgView.contentMode =  UIViewContentMode.scaleAspectFill
        backgroundImgView.clipsToBounds = true
        backgroundImgView.layoutIfNeeded()
        
        // backgroundImgView.image = UIImage(named: "img_aqoo_wp_07")
        backgroundImgView.backgroundColor = UIColor(netHex: 0x222222)
        backgroundImgView.center = view.center
        
        tableView.backgroundView = backgroundImgView
        
        spotifyClient.getDefaultPlaylistImageByUserPhoto(spotifyClient.spfCurrentSession!)
    }
    
    func setupUITableViewProgressBar() {

        let _superView = navigationController?.navigationBar

        progressBar.backgroundColor = UIColor(netHex: 0x222222)
        progressBar.trackTintColor = UIColor(netHex: 0x222222)
        progressBar.progressTintColor = UIColor(netHex: 0x1ED760)
        
        _superView!.addSubview(progressBar)
        
        
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        
    }

    
    func setupUICacheProcessor() {
        
        ImageCache.default.maxDiskCacheSize = _imgCacheInMb * 1024 * 1024 // activate 512mb image cache size
        ImageCache.default.maxCachePeriodInSecond = TimeInterval(60 * 60 * 24 * _imgCacheRevalidateInDays)
        ImageDownloader.default.downloadTimeout = _imgCacheRevalidateTimeoutInSeconds // activate a 10s download threshold
        
        _cacheTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(self._sysCacheCheckInSeconds),
            target: self,
            selector: #selector(handleCacheTimerEvent),
            userInfo: nil,
            repeats: true
        )
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
    
    /*
     * this method will be called every n-seconds to ensure your lists are up to date
     */
    func handleCacheTimerEvent() {
        
        ImageCache.default.calculateDiskCacheSize { size in
            print ("dbg [playlist] : cache ➡ used image cache in bytes: \(size)/\(self._imgCacheInMb * 1024)")
            
        }
        
        handlePlaylistCloudRefresh()
    }
    
    func handlePlaylistCloudRefresh() {
        
        if spotifyClient.isSpotifyTokenValid() {
            
            if  debugMode == true {
                
                print ("dbg [playlist] : kingfisher ➡ clear memory cache right away")
                ImageCache.default.clearMemoryCache()
                
                print ("dbg [playlist] : kingfisher ➡ clear disk cache. This is an async operation")
                ImageCache.default.clearDiskCache()
                
                print ("dbg [playlist] : sync [\(spotifyClient.spfStreamingProviderDbTag)] playlists ...")
                
            };  loadProvider ( spotifyClient.spfStreamingProviderDbTag )
            
        } else {
            
            if  debugMode == true {
                print ("dbg [playlist] : oops, your cloudProviderToken is not valid anymore")
            };  btnExitLandingPageAction( self )
        }
    }
    
    func handlePlaylistDbCacheCoreDataOrphans () {
        
        if let _playListCache = CoreStore.defaultStack.fetchAll(
            From<StreamPlayList>().where(
                (\StreamPlayList.provider == _defaultStreamingProvider)
            )
        ) {
            
            for (_, playlist) in _playListCache.enumerated() {
                
                // ignore all known / identical playlists
                if spotifyClient.playListHashesInCloud.contains(playlist.metaListHash) {
                   spotifyClient.playListHashesInCache.append(playlist.metaListHash)
                   
                   continue
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
    
    func handlePlaylistDbCacheMediaData(
       _ playlistInDb: StreamPlayList,
       _ playListInCloud: SPTPartialPlaylist) -> StreamPlayList {
        
        if let  _largestImage = playListInCloud.largestImage as? SPTImage {
            if  _largestImage.size != CGSize(width: 0, height: 0) {
                playlistInDb.largestImageURL = _largestImage.imageURL.absoluteString
            }
        }
        
        if let  _smallestImage = playListInCloud.smallestImage as? SPTImage {
            if  _smallestImage.size != CGSize(width: 0, height: 0) {
                playlistInDb.smallestImageURL = _smallestImage.imageURL.absoluteString
            }
        }
        
        return playlistInDb
    }
    
    func handlePlaylistDbCacheCoreData (
       _ playListInCloud: SPTPartialPlaylist,
       _ playListIndex: Int,
       _ providerTag: String ) {
        
        var _playlistInDb: StreamPlayList?
        var _playListFingerprint: String!

        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                // render hash for new playlist using corresponding cloud entry
                _playListFingerprint = self.spotifyClient.getMetaListHashByParam (
                    playListInCloud.playableUri.absoluteString,
                    playListInCloud.owner.canonicalUserName
                )
                
                // corresponding playlist entry exists in db? Check this entry again and prepare for update
                _playlistInDb = transaction.fetchOne(
                    From<StreamPlayList>().where((\StreamPlayList.metaListHash == _playListFingerprint))
                )
                
                // playlist cache entry in local db not available or not fetchable yet? Create a new one ...
                if _playlistInDb == nil {
                    
                    _playlistInDb = transaction.create(Into<StreamPlayList>()) as StreamPlayList
                    
                    _playlistInDb!.name = playListInCloud.name
                    _playlistInDb!.desc = playListInCloud.description
                    _playlistInDb!.playableURI = playListInCloud.playableUri.absoluteString
                    _playlistInDb!.trackCount = Int32(playListInCloud.trackCount)
                    _playlistInDb!.isCollaborative = playListInCloud.isCollaborative
                    _playlistInDb!.isPublic = playListInCloud.isPublic
                    _playlistInDb!.metaListNameOrigin = playListInCloud.name
                    _playlistInDb!.metaListDescriptionOrigin = playListInCloud.name
                    _playlistInDb!.metaLastListenedAt = nil
                    _playlistInDb!.metaNumberOfUpdates = 0
                    _playlistInDb!.metaNumberOfShares = 0
                    _playlistInDb!.metaMarkedAsFavorite = false
                    _playlistInDb!.metaListHash = _playListFingerprint
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
                        _playlistInDb!.desc = playListInCloud.description
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
                
                // last step - handle playlist media data, using vendor functionality (kingfisher cache)
                _playlistInDb = self.handlePlaylistDbCacheMediaData(_playlistInDb!, playListInCloud)
            },
            
            completion: { _ in
                
                // save handled hashed in separate collection
                self.spotifyClient.playListHashesInCloud.append(_playListFingerprint)
                
                // evaluate list extension completion and execute event signal after final cache item was handled
                if playListIndex == (self.spotifyClient.playlistsInCloud.count - 1) {
                    
                    self.handlePlaylistDbCacheCoreDataOrphans()
                    
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
        
        if self.debugMode == true {
            print ("dbg [playlist] : try to load provider [\(tag)]")
            print ("dbg [playlist] : cache ➡ \(self.spotifyClient.playListHashesInCloud.count - 1) playlists in cloud")
            print ("dbg [playlist] : cache ➡ \(self.spotifyClient.playListHashesInCache.count - 1) playlists in cache\n")
        }
        
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
                        print ("dbg [playlist] : provider [\(tag)] successfully loaded, fetching playlists now")
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
        
        if provider.tag != _sysDefaultProviderTag {
            
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
                        print ("dbg [playlist] : \(transactionPlaylists!.count - 1) playlists for this provider available ...")
                    };  self.spotifyClient.playlistsInCache = transactionPlaylists!
                    
                } else {
                    
                    // clean previously cached playlist collection
                    if self.debugMode == true {
                        print ("dbg [playlist] : no cached playlist data for this provider found ...")
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
