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
                    \StreamPlayList.provider == _defaultStreamingProvider
                )
            )
        {
            
            if debugMode == true {
                
                print ("\ncache: (re)evaluated, tableView will be refreshed now ...")
                print ("---------------------------------------------------------")
                print ("\(spotifyClient.playListHashesInCloud.count - 1) playlists in cloud")
                print ("\(spotifyClient.playListHashesInCache.count - 1) playlists in db/cache")
                print ("---------------------------------------------------------")
            }
            
           spotifyClient.playlistsInCache = _playListCache
        }
        
        tableView.reloadData()
        tableView.refreshTable()
    }
    
    @objc func setupUILoadCloudPlaylists() {
        
        var _playListFingerprint: String!
        var _progress: Float! = 0.0
        
        // clear internal cache for playlists and user profiles
        spotifyClient.playListHashesInCloud = []
        spotifyClient.playListHashesInCache = []
        
        _userProfilesHandledWithImages = [:]
        _userProfilesHandled = []
        _userProfilesInPlaylistsUnique = []
        _userProfilesInPlaylists = []

        for (playlistIndex, playListInCloud) in spotifyClient.playlistsInCloud.enumerated() {
            
            _playListFingerprint = spotifyClient.getMetaListHashByParam (
                playListInCloud.playableUri.absoluteString,
                spotifyClient.spfUsername
            )
            
            _userProfilesInPlaylists.append(playListInCloud.owner.canonicalUserName!)
            
            _progress = (Float(playlistIndex + 1) / Float(spotifyClient.playlistsInCloud.count)) * 100.0

            if debugMode == true {
                print ("\nlist: #\(playlistIndex) [ \(playListInCloud.name!) ] ➡ \(playListInCloud.trackCount) song(s)")
                print ("owner: \(playListInCloud.owner.canonicalUserName!) [ playlist covers: \(playListInCloud.images.count) ]")
                print ("uri: \(playListInCloud.playableUri!)")
                print ("hash: \(_playListFingerprint!) [ aqoo fingerprint ]")
                print ("progress: \(_progress!)")
                
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
    }
    
    func setupUICacheProcessor() {
        
        ImageCache.default.maxDiskCacheSize = _sysImgCacheInMb * 1024 * 1024 // activate 512mb image cache size
        ImageCache.default.maxCachePeriodInSecond = TimeInterval(60 * 60 * 24 * _sysImgCacheRevalidateInDays)
        ImageDownloader.default.downloadTimeout = _sysImgCacheRevalidateTimeoutInSeconds // activate a 10s download threshold
        
        _cacheTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(self._sysCacheCheckInSeconds),
            target: self,
            selector: #selector(handleCacheTimerEvent),
            userInfo: nil,
            repeats: true
        )
    }
    
    func setupUILoadUserProfileImages(notification: Notification) {
        
        guard let userInfo = notification.userInfo,
              let profileUser = userInfo["profileUser"] as? SPTUser,
              let profileImageURL = userInfo["profileImageURL"] as? URL,
              let profileImageURLAvailable = userInfo["profileImageURLAvailable"] as? Bool,
              let date = userInfo["date"] as? Date else { return }
        
        _userProfilesHandled.append(profileUser.canonicalUserName)
        if profileImageURLAvailable {
            _userProfilesHandledWithImages[profileUser.canonicalUserName] = profileImageURL.absoluteString
        }
        
        // all userProfiles handled? start refresh/enrichment cache process
        if _userProfilesHandled.count == _userProfilesInPlaylistsUnique.count {
            
            for (_userName, _userProfileImageURL) in _userProfilesHandledWithImages {
               
                if debugMode == true {
                    print ("dbg [playlist] : update cached playlist for userProfile [ \(_userName) ]")
                }
                
                // fetch all known playlists for corresponding (profile available) user
                if let _playListCache = CoreStore.defaultStack.fetchAll(
                    From<StreamPlayList>().where(
                        (\StreamPlayList.provider == _defaultStreamingProvider) &&
                        (\StreamPlayList.owner == _userName))
                    ) {
                    
                    // update cache entity for this user, add userProfileImageURL (using external function)
                    for (_, playlistInDb) in _playListCache.enumerated() {
                        
                        if self.debugMode == true {
                            print ("dbg [playlist] : refresh cache for [ \(_userName) ] / [ \(playlistInDb.name) ]")
                        };  self.handlePlaylistDbCacheOwnerProfileData(playlistInDb, _userName, _userProfileImageURL)
                    }
                }
            }
            
            // so finaly reload playlist tableView and leave this method peacefully
            NotificationCenter.default.post(
                name: NSNotification.Name.init(rawValue: self.notifier.notifyPlaylistCacheLoadCompleted),
                object: self
            )
        }
    }
    
    func setupUIEventObserver() {
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.setupUILoadUserProfileImages),
            name: NSNotification.Name(rawValue: self.notifier.notifyUserProfileLoadCompleted),
            object: nil
        )
        
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
            print ("dbg [playlist] : cache ➡ used image cache in bytes: \(size)/\(self._sysImgCacheInMb * 1024)")
        };  handlePlaylistCloudRefresh()
    }
    
    func handlePlaylistCloudRefresh() {
        
        if spotifyClient.isSpotifyTokenValid() {
            
            if  debugMode == true {
                // ImageCache.default.clearMemoryCache()
                // ImageCache.default.clearDiskCache()
            }
            
            loadProvider ( spotifyClient.spfStreamingProviderDbTag )
            
        } else {
            
            if  debugMode == true {
                print ("dbg [playlist] : oops, your cloudProviderToken is not valid anymore")
            };  btnExitLandingPageAction( self )
        }
    }
    
    func handlePlaylistProfileEnrichtment() {
        
        // unify current userProfile array, remove double entries
        _userProfilesInPlaylistsUnique = Array(Set(_userProfilesInPlaylists))
        
        if debugMode == true {
            print ("dbg [playlist] : enrich playlists by adding \(_userProfilesInPlaylistsUnique.count) user profiles")
            print ("dbg [playlist] : playlist profiles ➡ \(_userProfilesInPlaylistsUnique.joined(separator: ", "))")
        }
        
        for (_, _userName) in _userProfilesInPlaylistsUnique.enumerated() {
            
            print ("dbg [playlist] : send userProfile request (event) for [ \(_userName) ]")
            spotifyClient.getUserProfileImageURLByUserName(
                _userName, spotifyClient.spfCurrentSession!.accessToken!
            )
        }
    }
    
    func handlePlaylistDbCacheCoreDataOrphans () {
        
        if let _playListCache = CoreStore.defaultStack.fetchAll(
            From<StreamPlayList>().where((\StreamPlayList.provider == _defaultStreamingProvider))
        ) {
            
            for (_, playlist) in _playListCache.enumerated() {
                
                // ignore all known / identical playlists
                if spotifyClient.playListHashesInCloud.contains(playlist.metaListHash) {
                   spotifyClient.playListHashesInCache.append(playlist.metaListHash)
                   
                   continue
                }
            
                // kill all obsolete / orphan cache entries
                if debugMode == true {
                    print ("dbg [playlist] : playlist data hash [\(playlist.metaListHash)] orphan flagged for removal")
                }
                
                CoreStore.perform(
                    
                    asynchronous: { (transaction) -> Void in
                        let orphanPlaylist = transaction.fetchOne(
                            From<StreamPlayList>().where((\StreamPlayList.metaListHash == playlist.metaListHash))
                        );  transaction.delete(orphanPlaylist)
                    },
                    
                    completion: { _ in
                        
                        if self.debugMode == true {
                            print ("dbg [playlist] : playlist data hash [\(playlist.metaListHash)] handled -> REMOVED")
                        }
                    }
                )
            }
        }
    }
    
    func handlePlaylistDbCacheMediaData(
       _ playlistInDb: StreamPlayList,
       _ playListInCloud: SPTPartialPlaylist) -> StreamPlayList {
        
        if let _largestImage = playListInCloud.largestImage as? SPTImage {
            if _largestImage.size != CGSize(width: 0, height: 0) {
                playlistInDb.largestImageURL = _largestImage.imageURL.absoluteString
            }
        }
        
        if let _smallestImage = playListInCloud.smallestImage as? SPTImage {
            if _smallestImage.size != CGSize(width: 0, height: 0) {
                playlistInDb.smallestImageURL = _smallestImage.imageURL.absoluteString
            }
        }
        
        // no smallest or largest image found, iterated through alternative image stack
        // and take the first exisiting / plausible image as smallest cover image instead.
        // in future verseion I'll pick up some random band image from flickr if nothing
        // where found ...
        if playlistInDb.largestImageURL == nil && playlistInDb.smallestImageURL == nil {
            
            for (index, coverImageAlt) in playListInCloud.images.enumerated() {
                if let _coverImageAlt = coverImageAlt as? SPTImage {
                    if _coverImageAlt.size != CGSize(width: 0, height: 0) {
                        playlistInDb.smallestImageURL = _coverImageAlt.imageURL.absoluteString
                        
                        return playlistInDb
                    }
                }
            }
        }
        
        return playlistInDb
    }
    
    func handleOwnerProfileImageCacheForCell(
       _ userName: String,
       _ userProfileImageURL: String,
       _ playlistCell: PlaylistTableFoldingCell) {
        
        if  userName == _sysDefaultSpotifyUsername {
            playlistCell.imageViewPlaylistOwner.image = UIImage(named: _sysDefaultSpotifyUserImage)
        }   else {
            let _profileImageProcessor = ResizingImageProcessor(
                 referenceSize: _sysUserProfileImageSize)
                .append(another: RoundCornerImageProcessor(cornerRadius: _sysUserProfileImageCRadiusInDeg))
                .append(another: BlackWhiteProcessor())
            
            playlistCell.imageViewPlaylistOwner.isHidden = false
            playlistCell.imageViewPlaylistOwner.kf.setImage(
                with: URL(string: userProfileImageURL),
                placeholder: UIImage(named: _sysDefaultUserProfileImage),
                options: [
                    .transition(.fade(0.2)),
                    .processor(_profileImageProcessor)
                ]
            )
        }
    }
    
    func handlePlaylistDbCacheOwnerProfileInitialTableViewData (
       _ userName: String,
       _ userProfileImageURL: String) {
        
        tableView.visibleCells.forEach { cell in
            
            if let  playlistCell = cell as? PlaylistTableFoldingCell {
                if  playlistCell.metaOwnerName! != userName {
                    playlistCell.imageViewPlaylistOwner.image = UIImage(named: _sysDefaultUserProfileImage)
                    if  playlistCell.metaOwnerName! == _sysDefaultSpotifyUsername {
                        playlistCell.imageViewPlaylistOwner.image = UIImage(named: _sysDefaultSpotifyUserImage)
                    }
                    
                }   else {
                    handleOwnerProfileImageCacheForCell(userName, userProfileImageURL, playlistCell)
                }
            }
        }
    }
    
    func handlePlaylistDbCacheOwnerProfileData (
       _ playListInDb: StreamPlayList,
       _ userName: String,
       _ userProfileImageURL: String) {
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                playListInDb.ownerImageURL = userProfileImageURL
            },
            
            completion: { _ in
                
                self.handlePlaylistDbCacheOwnerProfileInitialTableViewData(
                    userName,
                    userProfileImageURL
                )
            }
        )
    }
    
    func handlePlaylistDbCacheCoreData (
       _ playListInCloud: SPTPartialPlaylist,
       _ playListIndex: Int,
       _ providerTag: String ) {
        
        var _playListInDb: StreamPlayList?
        var _playListFingerprint: String!
        var _playlistIsMine: Bool!
        var _ownerProfileImageURL: URL?
        var _ownerProfileImageStringURL: String! = ""
        var _currentUserName = spotifyClient.spfCurrentSession?.canonicalUsername

        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                // render hash for new playlist using corresponding cloud entry
                _playListFingerprint = self.spotifyClient.getMetaListHashByParam (
                    playListInCloud.playableUri.absoluteString,
                    playListInCloud.owner.canonicalUserName
                )
                
                // corresponding playlist entry exists in db? Check this entry again and prepare for update
                _playListInDb = transaction.fetchOne(
                    From<StreamPlayList>().where((\StreamPlayList.metaListHash == _playListFingerprint))
                )
                
                // playlist cache entry in local db not available or not fetchable yet? Create a new one ...
                if _playListInDb == nil {
                    
                    _playlistIsMine = false
                    if playListInCloud.owner.canonicalUserName == _currentUserName {
                        _playlistIsMine = true
                    }

                    if  _ownerProfileImageURL != nil {
                        _ownerProfileImageStringURL = _ownerProfileImageURL!.absoluteString
                    }
                    
                    _playListInDb = transaction.create(Into<StreamPlayList>()) as StreamPlayList
                    
                    _playListInDb!.name = playListInCloud.name
                    _playListInDb!.desc = playListInCloud.description
                    _playListInDb!.playableURI = playListInCloud.playableUri.absoluteString
                    _playListInDb!.trackCount = Int32(playListInCloud.trackCount)
                    _playListInDb!.isCollaborative = playListInCloud.isCollaborative
                    _playListInDb!.isPublic = playListInCloud.isPublic
                    _playListInDb!.metaListNameOrigin = playListInCloud.name
                    _playListInDb!.metaListDescriptionOrigin = playListInCloud.name
                    _playListInDb!.metaLastListenedAt = nil
                    _playListInDb!.metaNumberOfUpdates = 0
                    _playListInDb!.metaNumberOfShares = 0
                    
                    _playListInDb!.metaNumberOfPlayedPartly = 0
                    _playListInDb!.metaNumberOfPlayedCompletely = 0
                    _playListInDb!.isPlaylistVotedByStar = false
                    _playListInDb!.isPlaylistRadioSelected = false
                    _playListInDb!.isHot = false
                    
                    _playListInDb!.metaListHash = _playListFingerprint
                    _playListInDb!.createdAt = Date()
                    _playListInDb!.metaPreviouslyUpdated = false
                    _playListInDb!.metaPreviouslyCreated = true
                    _playListInDb!.isMine = _playlistIsMine
                    _playListInDb!.owner = playListInCloud.owner.canonicalUserName
                    _playListInDb!.ownerImageURL = _ownerProfileImageStringURL!
                    
                    _playListInDb!.provider = transaction.fetchOne(
                        From<StreamProvider>().where((\StreamProvider.tag == providerTag))
                    )
                    
                    if self.debugMode == true {
                        print ("dbg [playlist] : playlist data hash [\(_playListInDb!.metaListHash)] handled -> CREATED")
                    }
                
                // playlist cache entry found in local db? Check for changes and may update corresponding cache value ...
                } else {
                 
                    if _playListInDb!.getMD5FingerPrint() == playListInCloud.getMD5FingerPrint() {
                        
                        if self.debugMode == true {
                            print ("dbg [playlist] : playlist data hash [\(_playListInDb!.name)] handled -> NO_CHANGES")
                        }
                        
                    } else {
                        
                        // name, number of tracks or flags for public/collaborative changed? update list
                        _playListInDb!.name = playListInCloud.name
                        _playListInDb!.desc = playListInCloud.description
                        _playListInDb!.trackCount = Int32(playListInCloud.trackCount)
                        _playListInDb!.isCollaborative = playListInCloud.isCollaborative
                        _playListInDb!.isPublic = playListInCloud.isPublic
                        _playListInDb!.metaNumberOfUpdates += 1
                        _playListInDb!.updatedAt = Date()
                        _playListInDb!.metaPreviouslyUpdated = true
                        _playListInDb!.metaPreviouslyCreated = false
                        
                        if self.debugMode == true {
                            print ("dbg [playlist] : playlist data hash [\(_playListInDb!.metaListHash)] handled -> UPDATED")
                        }
                    }
                }
                
                // last step - handle playlist media data, using vendor functionality (kingfisher cache)
                _playListInDb = self.handlePlaylistDbCacheMediaData(_playListInDb!, playListInCloud)
            },
            
            completion: { _ in
                
                // save handled hashed in separate collection
                self.spotifyClient.playListHashesInCloud.append(_playListFingerprint)
                
                // evaluate list extension completion and execute event signal after final cache item was handled
                if playListIndex == (self.spotifyClient.playlistsInCloud.count - 1) {
                    
                    self.handlePlaylistDbCacheCoreDataOrphans()
                    self.handlePlaylistProfileEnrichtment()
                }
            }
        )
    }
    
    func getCloudVersionOfDbCachedPlaylist(_ playlistInDb: StreamPlayList) -> SPTPartialPlaylist? {
        
        for (_, _playlistInCloud) in spotifyClient.playlistsInCloud.enumerated() {
            
            if playlistInDb.getMD5FingerPrint() == _playlistInCloud.getMD5FingerPrint() {
                print ("MATCHED_DATA ::: [ \(playlistInDb.name) ], [\(_playlistInCloud.getMD5FingerPrint())]")
                
                return _playlistInCloud
            }
            
        }
        
        return nil
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
                        // info_1001: this will filter the current list to logged in user content only ...
                        // (\StreamPlayList.owner == self.spotifyClient.spfUsername) &&
                        (\StreamPlayList.provider == provider)
                    )
                )
            },
            
            success: { (transactionPlaylists) in
                
                if transactionPlaylists?.isEmpty == false {
                    
                    // store database fetch results in cache collection
                    if self.debugMode == true {
                        print ("dbg [playlist] : \(transactionPlaylists!.count - 1) playlists available ...")
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
