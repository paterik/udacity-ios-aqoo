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
import Persei
import NotificationBannerSwift
import GradientLoadingBar

extension PlaylistViewController {
    
    func setupUIEventObserver() {
        
        _playlistChanged = false
        
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
    
    func setupUITableBasicMenuView() {

        var imageKey: Int = 0
        
        // majic: iterate through predefined playlistFilterMeta dictionary sorted by key (desc)
        for (index, _filterMeta) in playlistFilterMeta.sorted(by: { $0.0 < $1.0 }).enumerated() {
            if  let _metaValue = _filterMeta.value as? [String: AnyObject] {
                // fetch filter image key from config dictionary stack
                if  let _metaImageKey = _metaValue["image_key"] as? Int {
                    // ignore "unset" imageKeys (value: -1)
                    if  imageKey == -1 { continue }
                        imageKey = _metaImageKey
                    // generate menu item now
                    var basicFilterItem = MenuItem(
                        image : UIImage(named: "mnu_pl_fltr_icn_\(imageKey)")!,
                        highlightedImage : UIImage(named: "mnu_pl_fltr_icn_\(imageKey)_hl")!
                    )
                    
                    basicFilterItem.backgroundColor = _sysPlaylistFilterColorBackground
                    basicFilterItem.highlightedBackgroundColor = _sysPlaylistFilterColorHighlight
                    basicFilterItem.shadowColor = _sysPlaylistFilterColorShadow
                    
                    playListBasicFilterItems.append(basicFilterItem)
                }
            }
        }
        
        // generate menu instance
        playListMenuBasicFilters = MenuView()
        playListMenuBasicFilters.backgroundColor = UIColor(netHex: 0x222222)
        playListMenuBasicFilters.contentHeight = 75.0
        playListMenuBasicFilters.delegate = self as! MenuViewDelegate
    }
    
    //
    // the method will handle filter menu tap's and notification
    //
    func menu(_ menu: MenuView, didSelectItemAt index: Int) {
        
        var filterTitle: String = "Playlist Loaded"
        var filterDescription: String = "you can choose any filter from the top menu"
        
        // majic: iterate through predefined playlistFilterMeta dictionary sorted by key (desc)
        for (_index, _filterMeta) in playlistFilterMeta.sorted(by: { $0.0 < $1.0 }).enumerated() {
            
            if _index == index {
                if  let _metaValue = _filterMeta.value as? [String: AnyObject] {
                    // fetch filter title from config dictionary stack
                    if  let _metaTitle = _metaValue["title"] as? String {
                        filterTitle = _metaTitle
                    }
                    
                    // fetch filter description/subTitle from dictionary stack
                    if  let _metaDescription = _metaValue["description"] as? String {
                        filterDescription = _metaDescription
                    }
                }
                
                break
            }
        }
        
        showFilterNotification ( filterTitle, filterDescription )
    }
    
    func showFilterNotification(_ title: String, _ description: String ) {
        
        let bannerView = PlaylistFilterNotification.fromNib(nibName: "PlaylistFilterNotification")
            bannerView.lblTitle.text = title
            bannerView.lblSubTitle.text = description
        
        let banner = NotificationBanner(customView: bannerView)
            banner.duration = 0.9375
            banner.onTap = {
            banner.dismiss()
        };  banner.show(bannerPosition: .top)
    }

    func setupUITableView() {
        
        //
        // thats a bit "majic" here, we've to prepare our table/cell struture by
        // a minimum of countable cells (as preCache) this will be work until someone
        // had a playlist containing more than 9999 songs -> still looking for alt.
        // logic implementation here 🤔
        //
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
    
    func setupUIBase() {
        
        // cleanUp filter definition
        playListBasicFilterItems.removeAll()
        
        // define our loading bar
        _playlistGradientLoadingBar = GradientLoadingBar(
            height: 3,
            durations: Durations(fadeIn: 0.975, fadeOut: 1.375, progress: 2.725),
            gradientColorList: [
                UIColor(netHex: 0x1ED760), // 0x1ED760 | 0x4CD964
                UIColor(netHex: 0xff2D55)  // 0xff2D55 | 0xff2D55
            ],
            onView: self.view
        )
        
        // and show loading bar now ...
        _playlistGradientLoadingBar.show()
    }
    
    func setupUICacheProcessor() {
        
        ImageCache.default.maxDiskCacheSize = _sysImgCacheInMb * 1024 * 1024
        ImageCache.default.maxCachePeriodInSecond = TimeInterval(60 * 60 * 24 * _sysImgCacheRevalidateInDays)
        ImageDownloader.default.downloadTimeout = _sysImgCacheRevalidateTimeoutInSeconds
        
        _cacheTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(_sysCacheCheckInSeconds),
            target: self,
            selector: #selector(handleCacheTimerEvent),
            userInfo: nil,
            repeats: true
        )
    }
    
    //
    // will be used as primary filter logic (pre)processor and the last method called in this scene
    //
    func setupUILoadMenuFilterItems(_ menuItems: [MenuItem]) {
        
        playListMenuBasicFilters.items = menuItems
        
        tableView.addSubview(playListMenuBasicFilters)
        
       _playlistGradientLoadingBar.hide()
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

            let playlistFilterMetaKeyStart = self.playlistFilterMeta.count - 1
            
            for (_userName, _userProfileImageURL) in _userProfilesHandledWithImages {
                
                // persisting user images by using an separate cache stack
                ImageDownloader.default.downloadImage(
                    with: URL(string: _userProfileImageURL)!,
                    options: [],
                    progressBlock: nil
                ) {
                    
                    (image, error, url, data) in
                    
                    if let _rawImage = image {
                        
                        self._userProfilesCachedForFilter += 1
                        ImageCache.default.store( _rawImage, forKey: "\(_userProfileImageURL)", toDisk: true)
                       
                        var profileImageMin = _rawImage.kf.resize(to: self._sysPlaylistFilterOwnerImageSize)
                        var profileImageActive = profileImageMin
                        var profileImageNormal = profileImageMin.kf.overlaying(
                            with: UIColor(netHex: 0x222222),
                            fraction: 0.675
                        )
                        
                        var ownerFilterItem = MenuItem(
                            image : profileImageNormal,
                            highlightedImage : profileImageActive
                        )
                        
                        ownerFilterItem.backgroundColor = self._sysPlaylistFilterColorBackground
                        ownerFilterItem.highlightedBackgroundColor = self._sysPlaylistFilterColorHighlight
                        ownerFilterItem.shadowColor = self._sysPlaylistFilterColorShadow
                        
                        // extend previously set basic filter meta description block by profile filter description
                        self.playlistFilterMeta += [playlistFilterMetaKeyStart + self._userProfilesCachedForFilter : [
                            "title" : "All Playlists of \(_userName)",
                            "description" : "Fetch all \(_userName)'s playlists",
                            "image_key" : -1
                        ]]
                        
                        // extend previously set basic filter items by user profiles
                        self.playListBasicFilterItems.append(ownerFilterItem)
                        
                        // final user profile image handled? good init/load filterMenu now
                        if (self._userProfilesCachedForFilter == self._userProfilesHandledWithImages.count) {
                            self.setupUILoadMenuFilterItems( self.playListBasicFilterItems )
                        }
                    }
                }
                
                // fetch all known playlists for corresponding (profile available) user
                if let _playListCache = CoreStore.defaultStack.fetchAll(
                    From<StreamPlayList>().where(
                        (\StreamPlayList.provider == _defaultStreamingProvider) &&
                        (\StreamPlayList.owner    == _userName))
                    ) {
                    
                    // update cache entity for this user, add userProfileImageURL (using external function)
                    for (_, _playlistInDb) in _playListCache.enumerated() {
                        self.handlePlaylistDbCacheOwnerProfileData(
                            _playlistInDb,
                            _userName,
                            _userProfileImageURL
                        )
                    }
                }
            }
            
            // so finaly reload playlist tableView and leave this method peacefully
            NotificationCenter.default.post(
                name: NSNotification.Name.init(rawValue: notifier.notifyPlaylistCacheLoadCompleted),
                object: self
            )
        }
    }
    
    //
    // weazL :: note_1001 : main listView logic, place for filter handling
    //
    @objc func setupUILoadExtendedPlaylists() {
        
        //
        // primary fetch request for all local cached/enriched playlist data which will
        // be finally shown in our tableView
        //
        if let _playListCache = CoreStore.fetchAll(
                From<StreamPlayList>()
                    .orderBy(.descending(\StreamPlayList.metaListInternalRating))
                    .where(\StreamPlayList.provider == _defaultStreamingProvider)
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

            // tableView.refreshTable()
            tableView.reloadData()
            
        } else {
            
            /*
             * no plylistdata found ... show welcome screen or tutorial instead (feature)
             *
             */
        }
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
                print ("\nlist: #\(playlistIndex) [ \(playListInCloud.name) ]")
                print ("contains: \(playListInCloud.trackCount) playlable songs")
                print ("owner: \(playListInCloud.owner.canonicalUserName!)")
                print ("playlist covers: \(playListInCloud.images.count) (alternativ covers)")
                print ("uri: \(playListInCloud.playableUri!)")
                print ("hash: \(_playListFingerprint!) [ aqoo fingerprint ]")
                print ("progress: \(_progress!)")
                print ("\n--")
            }
            
            handlePlaylistDbCacheCoreData (playListInCloud, playlistIndex, spotifyClient.spfStreamingProviderDbTag)
        }
        
        if debugMode == true {
            print ("\napi handling for playlists endpoint finalized\n\n==\n")
        }
    }

    /*
     * this method will be called every n-seconds to ensure your lists are up to date
     */
    func handleCacheTimerEvent() {
        
        ImageCache.default.calculateDiskCacheSize { size in
            print ("dbg [playlist] : cache ➡ used image cache in bytes: \(size)/\(self._sysImgCacheInMb * 1024)")
        };  handlePlaylistCloudRefresh()
    }
    
    func handlePlaylistCacheCleanUp() {
        
        let localCacheCleanUpRequest = UIAlertController(
            title: "Remove Local Cache?",
            message: "you are in devMode of this app, do you want to delete the complete local cache now?",
            preferredStyle: UIAlertControllerStyle.alert
        )
        
        let dlgBtnYesAction = UIAlertAction(title: "Yes", style: .default) { (action: UIAlertAction!) in
            
            print ("dbg [playlist] : cache ➡ cleanUp local image cache")
            ImageCache.default.clearMemoryCache()
            ImageCache.default.clearDiskCache()
            
            CoreStore.perform(
                
                asynchronous: { (transaction) -> [StreamPlayList]? in
                    
                    return transaction.fetchAll(From<StreamPlayList>()) },
                
                success: { (transactionPlaylists) in
                    
                    if transactionPlaylists?.isEmpty == false {
                        print ("dbg [playlist] : cache ➡ cleanUp local db cache, \(transactionPlaylists!.count - 1) rows will be removed")
                    }
                },
                
                failure: { (error) in
                    
                    self._handleErrorAsDialogMessage(
                        "Error Loading Playlist Cache",
                        "Oops! An error occured while loading playlists from database ..."
                    )
                }
            )
            
            CoreStore.perform(
                asynchronous: { (transaction) -> Void in transaction.deleteAll(From<StreamPlayList>()) },
                completion:   { _ in print ("dbg [playlist] : cache ➡ local db cache removed") }
            )
            
            self.handlePlaylistCloudRefresh()
        }
        
        let dlgBtnCancelAction = UIAlertAction(title: "No", style: .default) { (action: UIAlertAction!) in
            
            self.handlePlaylistCloudRefresh()
            
            return
        }
        
        localCacheCleanUpRequest.addAction(dlgBtnYesAction)
        localCacheCleanUpRequest.addAction(dlgBtnCancelAction)

        present(localCacheCleanUpRequest, animated: true, completion: nil)
    }
    
    func handlePlaylistCloudRefresh() {
        
        if  spotifyClient.isSpotifyTokenValid() {
            loadProvider ( spotifyClient.spfStreamingProviderDbTag )
            
        } else {
            
            if  debugMode == true {
                print ("dbg [playlist] : Oops, your cloudProviderToken is not valid anymore")
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
        
        for (_, _profileUserName) in _userProfilesInPlaylistsUnique.enumerated() {
            
            print ("dbg [playlist] : send userProfile request (event) for [ \(_profileUserName) ]")
            spotifyClient.getUserProfileImageURLByUserName(
                _profileUserName, spotifyClient.spfCurrentSession!.accessToken!
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
                    print ("dbg [playlist] : [\(playlist.metaListInternalName)] orphan flagged for removal")
                }
                
                CoreStore.perform(
                    
                    asynchronous: { (transaction) -> Void in
                        
                        let orphanPlaylist = transaction.fetchOne(
                            From<StreamPlayList>().where((\StreamPlayList.metaListHash == playlist.metaListHash))
                        );  transaction.delete(orphanPlaylist)
                    },
                    
                    completion: { _ in
                        
                        if self.debugMode == true {
                            print ("dbg [playlist] : [\(playlist.metaListInternalName)] handled -> REMOVED")
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
        
        //
        // no smallest or largest image found, iterated through alternative image stack
        // and take the first exisiting / plausible image as smallest cover image instead.
        // in future verseion I'll pick up some random band image from flickr if nothing
        // where found (feature)
        //
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
       _ userProfileUserName: String,
       _ userProfileImageURL: String) {

        // don't override owners image url if allready set previously
        if playListInDb.ownerImageURL == userProfileImageURL { return }
        
        do {
            
            CoreStore.perform(
                
                asynchronous: { (transaction) -> Void in
                    playListInDb.ownerImageURL = userProfileImageURL
                },
                completion: { _ in
                    
                    self.handlePlaylistDbCacheOwnerProfileInitialTableViewData(
                        userProfileUserName,
                        userProfileImageURL
                    )
                }
            )
            
        } catch {
            
            if debugMode == true {
                // weazL :: bug_1001 : sometimes my app will crash here unexpected
                /*  expression produced error: error: /var/folders/ht/_s8btd0x1nz1t35lsf6ymmqc0000gn/T/expr2-f4ea92..swift:1:112: error: use of undeclared type 'CoreStore' - Swift._DebuggerSupport.stringForPrintObject(Swift.UnsafePointer<Swift.Optional<(hasChanges: Swift.Bool, error: CoreStore.CoreStoreError?)>>(bitPattern: 0x120c70850)!.pointee) */
                
                print ("dbg [playlist] : [\(playListInDb.ownerImageURL)] not handled -> EXCEPTION")
            }
            
            return
        }
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

                    _playListInDb!.playableURI = playListInCloud.playableUri.absoluteString
                    _playListInDb!.trackCount = Int32(playListInCloud.trackCount)
                    _playListInDb!.isCollaborative = playListInCloud.isCollaborative
                    _playListInDb!.isPublic = playListInCloud.isPublic
                    _playListInDb!.metaListNameOrigin = playListInCloud.name
                    _playListInDb!.metaLastListenedAt = nil
                    _playListInDb!.metaNumberOfUpdates = 0
                    _playListInDb!.metaNumberOfShares = 0
                    
                    _playListInDb!.metaNumberOfPlayedPartly = 0
                    _playListInDb!.metaNumberOfPlayedCompletely = 0
                    _playListInDb!.isPlaylistVotedByStar = false
                    _playListInDb!.isPlaylistRadioSelected = false
                    _playListInDb!.isHot = false
                    
                    _playListInDb!.metaListHash = _playListFingerprint
                    _playListInDb!.metaPreviouslyUpdated = false
                    _playListInDb!.metaPreviouslyUpdatedManually = false
                    _playListInDb!.metaPreviouslyCreated = true
                    _playListInDb!.isMine = _playlistIsMine
                    _playListInDb!.owner = playListInCloud.owner.canonicalUserName
                    _playListInDb!.ownerImageURL = _ownerProfileImageStringURL!
                    
                    _playListInDb!.createdAt = Date()
                    
                    _playListInDb!.metaListInternalName = playListInCloud.name
                    _playListInDb!.metaListInternalDescription = self.getPlaylistInternalDescription(
                         playListInCloud,
                        _playListInDb!
                    )
                    
                    _playListInDb!.provider = transaction.fetchOne(
                        From<StreamProvider>().where((\StreamProvider.tag == providerTag))
                    )
                    
                    if self.debugMode == true {
                        print ("dbg [playlist] : [\(_playListInDb!.metaListInternalName)] handled -> CREATED")
                    }
                
                // playlist cache entry found in local db? Check for changes and may update corresponding cache value ...
                } else {
                 
                    if _playListInDb!.getMD5FingerPrint() == playListInCloud.getMD5FingerPrint() {
                        
                        if self.debugMode == true {
                            print ("dbg [playlist] : [\(_playListInDb!.metaListInternalName)] handled -> NO_CHANGES")
                        }
                        
                    } else {
                        
                        // name (origin) , number of tracks or flags for public/collaborative changed? update list
                        _playListInDb!.metaListNameOrigin = playListInCloud.name ?? playListInCloud.uri.absoluteString
                        _playListInDb!.trackCount = Int32(playListInCloud.trackCount)
                        _playListInDb!.isCollaborative = playListInCloud.isCollaborative
                        _playListInDb!.isPublic = playListInCloud.isPublic
                        _playListInDb!.metaNumberOfUpdates += 1
                        _playListInDb!.updatedAt = Date()
                        _playListInDb!.metaPreviouslyUpdatedManually = false
                        _playListInDb!.metaPreviouslyUpdated = true
                        _playListInDb!.metaPreviouslyCreated = false
                        
                        if self.debugMode == true {
                            print ("dbg [playlist] : [\(_playListInDb!.metaListInternalName)] handled -> UPDATED")
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
    
    func getPlaylistInternalDescription(
       _ playlistInCloud: SPTPartialPlaylist,
       _ playlistInDb: StreamPlayList) -> String {
        
        var _updatedMetaString: String = ""
        var _updatedDateString: NSString = ""
        var _createdDateString: NSString = ""

        if playlistInDb.updatedAt != nil {
            _updatedDateString = getDateAsString(playlistInDb.updatedAt!)
            _updatedMetaString = ", updated on \(_updatedDateString)"
        }
        
        _createdDateString = getDateAsString(playlistInDb.createdAt!)
        
        return "This playlist \"\(playlistInCloud.name!)\" is owned by \(playlistInCloud.owner.canonicalUserName!), was firstly seen on \(_createdDateString) \(_updatedMetaString) and can be found in spotify at \(playlistInCloud.playableUri.absoluteString)"
    }
    
    func getCloudVersionOfDbCachedPlaylist(_ playlistInDb: StreamPlayList) -> SPTPartialPlaylist? {
        
        for (_, _playlistInCloud) in spotifyClient.playlistsInCloud.enumerated() {
            
            if  playlistInDb.getMD5FingerPrint() == _playlistInCloud.getMD5FingerPrint() {
                
                return _playlistInCloud
            }
        }
        
        return nil
    }
    
    func loadProvider (_ tag: String) {
        
        if  debugMode == true {
            print ("dbg [playlist] : try to load provider [ \(tag) ]")
            print ("dbg [playlist] : cache ➡ \(spotifyClient.playListHashesInCloud.count - 1) playlists in cloud")
            print ("dbg [playlist] : cache ➡ \(spotifyClient.playListHashesInCache.count - 1) playlists in cache\n")
        }
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> StreamProvider? in
                
                return transaction.fetchOne(
                    From<StreamProvider>()
                        .where((\StreamProvider.tag == tag) && (\StreamProvider.isActive == true))
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
            
            _handleErrorAsDialogMessage(
                "Error Loading Provider",
                "Oops! The provider '\(provider.name)' isn't supported yet ..."
            )
            
            return
        }
        
        // first of all fetch new playlists from api for comparision
        spotifyClient.handlePlaylistGetFirstPage(
            spotifyClient.spfUsername,
            spotifyClient.spfCurrentSession!.accessToken!
        )
        
        // now (pre)fetch corresponding local playlists for sync process
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [StreamPlayList]? in
                
                self._defaultStreamingProvider = provider
                
                return transaction.fetchAll(From<StreamPlayList>().where(\StreamPlayList.provider == provider))
            },
            
            success: { (transactionPlaylists) in
                
                if transactionPlaylists?.isEmpty == false {
                    
                    // store database fetch results in cache collection
                    if  self.debugMode == true {
                        print ("dbg [playlist] : \(transactionPlaylists!.count - 1) playlists available ...")
                    };  self.spotifyClient.playlistsInCache = transactionPlaylists!
                    
                } else {
                    
                    // clean previously cached playlist collection
                    if  self.debugMode == true {
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
    
    func promoteChangedPlaylistObject(_ playlistItem: StreamPlayList ) {
        
        print ("dbg [delegate] : value transmitted -> PlaylistViewControllerExt :: playlistItem == [\(playlistItem.metaListInternalName)]")
    }
    
    func promoteToChanged(_ value: Bool) {
        
        print ("dbg [delegate] : value changed -> PlaylistViewControllerExt :: playlistChanged == \(value)")
        _playlistChanged = value
    }
}
