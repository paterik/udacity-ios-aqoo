//
//  PlaylistViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 20.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import Persei
import PKHUD
import CoreStore
import CryptoSwift
import Kingfisher
import NotificationBannerSwift
import GradientLoadingBar
import SwiftDate

extension PlaylistViewController {
    
    func togglePlayMode (
       _ active: Bool) {
        
        if  currentPlaylist.trackCheckTimer != nil {
            currentPlaylist.trackCheckTimer.invalidate()
        }
        
        if  active == true {
            
            // start playback meta timer
            currentPlaylist.trackCheckTimer = Timer.scheduledTimer(
                timeInterval : TimeInterval(1),
                target       : self,
                selector     : #selector(handlePlaylistTrackTimerEvent),
                userInfo     : nil,
                repeats      : true
            )
        }
    }
    
    @objc
    func handlePlaylistTrackTimerEvent() {
        
        if debugMode == false { return }
        
        let currentAlbumName = localPlayer.player!.metadata.currentTrack!.albumName
        let currentTrackName = localPlayer.player!.metadata.currentTrack!.name
        let currentArtistName = localPlayer.player!.metadata.currentTrack!.artistName
        
        if  localPlayer.player!.playbackState.isPlaying {
            print ("_track:  \(currentTrackName)")
            print ("_album:  \(currentAlbumName)")
            print ("_artist: \(currentArtistName)")
            print ("----------------------------------------------------------------------------")
            print ("_player_is_activeDevice: \(localPlayer.player!.playbackState.isActiveDevice)")
            print ("_player_is_repeating: \(localPlayer.player!.playbackState.isRepeating)")
            print ("_player_is_shuffle: \(localPlayer.player!.playbackState.isShuffling)")
            print ("_player_is_playling: \(localPlayer.player!.playbackState.isPlaying)")
        }   else {
            print ("__ not playing, ignore metablock print out")
        }
    }
    
    func setupUIEventObserver() {
        
        playlistChanged = false
        playlistChangedItem = nil
        
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
            self, selector: #selector(self.setupUILoadMetaExtendedPlaylists),
            name: NSNotification.Name(rawValue: self.notifier.notifyPlaylistMetaExtendLoadCompleted),
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
                    // ignore "unset" image keys (value: -1)
                    if  imageKey == -1 { continue }
                        imageKey = _metaImageKey
                    // generate menu items for basic filter calls
                    var basicFilterItem = MenuItem(
                        image : UIImage(named: "mnu_pl_fltr_icn_\(imageKey)")!,
                        highlightedImage : UIImage(named: "mnu_pl_fltr_icn_\(imageKey)_hl")!
                    )
                    
                    basicFilterItem.backgroundColor = sysPlaylistFilterBackgroundColor
                    basicFilterItem.highlightedBackgroundColor = sysPlaylistFilterHighlightColor
                    basicFilterItem.shadowColor = sysPlaylistFilterShadowColor
                    
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
    
    func getFilterBlockByIndex(
       _ index : Int) -> (String,String,OrderBy<StreamPlayList>.SortKey?,FetchChainBuilder<StreamPlayList>?,Bool,Int?) {
            
        var filterTitle: String = "Playlist Loaded"
        var filterDescription: String = "you can choose any filter from the top menu"
        var filterQueryOrderByClause: OrderBy<StreamPlayList>.SortKey?
        var filterQueryFetchChainBuilder: FetchChainBuilder<StreamPlayList>?
        var filterQueryUseDefaults: Bool = false
        var filterImageKey: Int?
        var filterTargetIndex: Int = index
        var filterMaxIndex: Int = playlistFilterMeta.count
        
        // prevent filter collision on dynamic parts of current filter set
        if  index > filterMaxIndex {
            filterTargetIndex = 0
        }
        
        // majic: iterate through predefined playlistFilterMeta dictionary sorted by key (desc)
        for (_index, _filterMeta) in playlistFilterMeta.sorted(by: { $0.0 < $1.0 }).enumerated() {
            
            if _index == filterTargetIndex {
                
                if  let _metaValue = _filterMeta.value as? [String: AnyObject] {
                    
                    // fetch filter image key from config dictionary stack
                    if  let _metaImageKey = _metaValue["image_key"] as? Int {
                        if  _metaImageKey != -1 {
                            filterImageKey = _metaImageKey
                        }
                    }
                    
                    // fetch filter title from config dictionary stack
                    if  let _metaTitle = _metaValue["title"] as? String {
                        filterTitle = _metaTitle
                    }
                    
                    // fetch filter description/subTitle from dictionary stack
                    if  let _metaDescription = _metaValue["description"] as? String {
                        filterDescription = _metaDescription
                    }
                    
                    // fetch 'order-by' query enforce-default-order flag from dictionary stack
                    if  let _metaQueryUseDefaults = _metaValue["query_order_use_internals"] as? Bool {
                        filterQueryUseDefaults = _metaQueryUseDefaults
                    }
                    
                    // fetch base 'order-by' query sortKeys from dictionary stack
                    if  let _metaQueryOrderBy = _metaValue["query_order_by"] as? OrderBy<StreamPlayList>.SortKey {
                        filterQueryOrderByClause = _metaQueryOrderBy
                    }
                    
                    // fetch base 'where' query override statement from dictionary stack
                    if  let _metaQueryWhere = _metaValue["query_override"] as? FetchChainBuilder<StreamPlayList> {
                        filterQueryFetchChainBuilder = _metaQueryWhere
                    }
                }
                
                break
            }
        }
            
        return (
            filterTitle,
            filterDescription,
            filterQueryOrderByClause,
            filterQueryFetchChainBuilder,
            filterQueryUseDefaults,
            filterImageKey
        )
    }
    
    //
    // this method will handle main filter menu tap events and notification
    //
    func menu(
       _ menu: MenuView,
         didSelectItemAt index: Int) {
        
        // fetch logical filterBlock by key selection index
        let filterBlock = getFilterBlockByIndex( index )
        // persist current filter to provider based playlist
        setConfigTableFilterKeyByProviderTag ( Int16 (index), _sysDefaultProviderTag )
        // show notification for user about current filter set
        showFilterNotification ( filterBlock.0, filterBlock.1, filterBlock.5 )
        // call specific filter action corresponding to current filter-item menu selection
        handleTableFilterByFetchChainQuery(
            filterBlock.2,
            filterBlock.3,
            filterBlock.4
        )
    }
    
    func getConfigTableFilterKeyByProviderTag(
       _ filterProviderTag: String = "_spotify") -> Int {
        
        // prefetch stream provider entity to select corresponding config by lines below ...
        var _configProvider = CoreStore.defaultStack.fetchOne(
            From<StreamProvider>().where(\StreamProvider.tag == filterProviderTag)
        )
        
        // try to fetch config value object by given provider entity ...
        if  let _configKeyRow = CoreStore.defaultStack.fetchOne(
            From<StreamProviderConfig>().where(\StreamProviderConfig.provider == _configProvider)
            ) as? StreamProviderConfig {
            
            return Int ( _configKeyRow.defaultPlaylistTableFilterKey )
        }
        
        // no filter set? activate default filter!
        setConfigTableFilterKeyByProviderTag ( Int16(sysPlaylistDefaultFilterIndex), _sysDefaultProviderTag )
        
        return sysPlaylistDefaultFilterIndex
    }
    
    func setConfigTableFilterKeyByProviderTag(
       _ filterKey: Int16 = 0,
       _ filterProviderTag: String = "_spotify") {
        
        if  spotifyClient.spfCurrentSession == nil {
            handleErrorAsDialogMessage("Session Error", "unable to save current filter to your playlist - session lost!")
            return
        }
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                let providerUserId = self.spotifyClient.spfCurrentSession!.canonicalUsername
                
                // prefetch stream provider entity again to select corresponding config by lines below ...
                var _configProvider = transaction.fetchOne(
                    From<StreamProvider>().where(\StreamProvider.tag == filterProviderTag)
                )
                
                // try to fetch config value object by given provider entity ...
                var _configKeyRow = transaction.fetchOne(
                    From<StreamProviderConfig>().where(\StreamProviderConfig.provider == _configProvider)
                )
                
                // stream provider config entry in local db not available or not fetchable yet? Create a new one ...
                if _configKeyRow == nil {
                   _configKeyRow = transaction.create(Into<StreamProviderConfig>()) as StreamProviderConfig
                   _configKeyRow!.defaultPlaylistTableFilterKey = filterKey
                   _configKeyRow!.isGlobal = false // this config will be provider dependent
                   _configKeyRow!.provider = _configProvider!
                   _configKeyRow!.providerUserId = providerUserId
                   _configKeyRow!.createdAt = Date()
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist] : config_key ➡ [FILTER_INDEX = (\(filterKey))] created")
                    }
                
                // stream provider config available? ... update corresponding property (so filterKey in this case)
                }   else {
                    
                   _configKeyRow!.defaultPlaylistTableFilterKey = filterKey
                   _configKeyRow!.provider = _configProvider!
                   _configKeyRow!.updatedAt = Date()
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist] : config_key ➡ [FILTER_INDEX = (\(filterKey))] update")
                    }
                }
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }
                case .success(let userInfo): break
                    if  self.debugMode == true {
                        print ("dbg [playlist] : config_key ➡ finaly persisted")
                    }
                }
            }
        )
    }
    
    func handleTableFilterByFetchChainQuery(
       _ filterQueryOrderByClause: OrderBy<StreamPlayList>.SortKey? = nil,
       _ filterQueryFetchChainBuilder: FetchChainBuilder<StreamPlayList>? = nil,
       _ filterQueryUseDefaults: Bool = false ) {
        
        var filterQueryOrderBy = OrderBy<StreamPlayList>()
        var filterQueryResults = [StreamPlayList]()
        
        if  filterQueryOrderByClause == nil &&
            filterQueryFetchChainBuilder == nil {
            if  self.debugMode == true {
                print ("dbg [playlist] : filter ➡ no orderBy or where parameter set - filter process aborted!")
                
                return
            }
        }
        
        if  filterQueryOrderByClause != nil {
            filterQueryOrderBy = OrderBy<StreamPlayList>( filterQueryOrderByClause! )
            if  filterQueryUseDefaults == true {
                filterQueryOrderBy += OrderBy( .ascending(\StreamPlayList.metaWeight) )
            }
        }
        
        if  filterQueryFetchChainBuilder != nil {
            if  let _playListFilterResults = CoreStore.defaultStack.fetchAll( filterQueryFetchChainBuilder! ) {
                filterQueryResults = _playListFilterResults
            }
            
        }   else {
            if  let _playListFilterResults = CoreStore.defaultStack.fetchAll(
                From<StreamPlayList>(),
                Where<StreamPlayList>("isPlaylistHidden = %d", false),
                filterQueryOrderBy
            ) { filterQueryResults = _playListFilterResults }
        }
        
        if  filterQueryResults.count > 0 {
            // reset table cache and reload table view only on existing (countable) results
            spotifyClient.playlistsInCache = filterQueryResults
            
        }   else {
            HUD.flash(.label("no playlists for this filter"), delay: 2.275)
            spotifyClient.playlistsInCache = []
            // @todo :: feature_1001 : user will be informed using a simple dialog
            // - do you want to load your playlist using one of your favorite filters instead?
            // - filter1, filter2 or filter3 ...
        }
        
        handlePlaylistReloadData()
    }
    
    func showFilterNotification(
       _ title: String,
       _ description: String,
       _ imageKey: Int? ) {
        
        let bannerView = PlaylistFilterNotification.fromNib(nibName: "PlaylistFilterNotification")
            bannerView.lblTitle.text = title
            bannerView.lblSubTitle.text = description
        if  imageKey != nil {
            bannerView.imgViewNotificationDefault.image = UIImage(named: "mnu_pl_fltr_icn_\(imageKey!)_nfo")
        }
        
        let banner = NotificationBanner(customView: bannerView)
            banner.duration = 0.9375
            banner.onTap = {
            banner.dismiss()
        };  banner.show(bannerPosition: .top)
    }

    func setupUITableView() {
        
        // @todo :: feature_1002 : thats a bit "majic" here, we've to prepare our
        // table/cell struture by a minimum of countable cells (as preCache) this
        // will be work until someone had a playlist containing more than 9999
        // playlists -> still looking for an alternative logic implementation here 🤔
        
        cellHeights = Array(repeating: sysCloseCellHeight, count: sysPreRenderRowsCount)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = sysCloseCellHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let backgroundImgView : UIImageView! = UIImageView(frame: view.bounds)
        
        backgroundImgView.contentMode =  UIViewContentMode.scaleAspectFill
        backgroundImgView.clipsToBounds = true
        backgroundImgView.layoutIfNeeded()
        
        // backgroundImgView.image = UIImage(named: "img_aqoo_wp_05")
        backgroundImgView.backgroundColor = UIColor(netHex: 0x222222)
        backgroundImgView.center = view.center
        
        tableView.backgroundView = backgroundImgView
    }
    
    func setupUIBase() {
        
        // prepare main HUD settings
        HUD.dimsBackground = true
        HUD.allowsInteraction = false
        
        // cleanUp filter definition
        playListBasicFilterItems.removeAll()
        
        // define (and show) our playlist loading bar
        playlistGradientLoadingBar = GradientLoadingBar(
            height: 5,
            durations: Durations(fadeIn: 0.975, fadeOut: 1.375, progress: 2.725),
            gradientColorList: [
                UIColor(netHex: 0x1ED760), // 0x1ED760 | 0x4CD964
                UIColor(netHex: 0xff2D55)  // 0xff2D55 | 0xff2D55
            ],
            onView: self.view
        );  playlistGradientLoadingBar.show()
    }
    
    func setupDBSessionAuth() {
        
        if  spotifyClient.isSpotifyTokenValid() {
            
            // get current provider session based userId as primary identifier
            // and cleanUP foreign/old user based data from app
            
            let providerUserId = spotifyClient.spfCurrentSession!.canonicalUsername
            
            CoreStore.defaultStack.perform(
                asynchronous: { (transaction) -> Int? in transaction.deleteAll(
                    From<StreamPlayList>().where((\StreamPlayList.aqooUserId != providerUserId)))
                },
                completion: { (result) -> Void in
                    
                    switch result {
                    case .failure(let error): if self.debugMode == true { print (error) }
                    case .success(let userInfo):
                        // enforce playlistView table reload
                        self.handlePlaylistReloadData()
                        
                        if  self.debugMode == true {
                            print ("dbg [playlist] : old user playlists cache removed")
                        }
                    }
                }
            )
        }
    }
    
    func setupUICacheProcessor() {
        
        ImageCache.default.maxDiskCacheSize = sysImgCacheInMb * 1024 * 1024
        ImageCache.default.maxCachePeriodInSecond = TimeInterval(60 * 60 * 24 * sysImgCacheRevalidateInDays)
        ImageDownloader.default.downloadTimeout = sysImgCacheRevalidateTimeoutInSeconds
        if  debugMode == true {
            ImageCache.default.calculateDiskCacheSize { size in
                print("\n=== used kingfisher cache disk size in bytes: \(size)\n")
            }
        }
        
        cacheTimer = Timer.scheduledTimer(
            timeInterval : TimeInterval(sysCacheCheckInSeconds),
            target       : self,
            selector     : #selector(handleCacheTimerEvent),
            userInfo     : nil,
            repeats      : true
        )
    }
    
    //
    // will be used as primary filter logic (pre)processor and the last method called in this scene
    //
    func setupUILoadMenuFilterItems(
       _ menuItems: [MenuItem]) {
        
        // finale item allocation for our filterMenu
        playListMenuBasicFilters.items = menuItems
        tableView.addSubview(playListMenuBasicFilters)
        
        // updated selected index based on given persisted filterKey
        playListMenuBasicFilters.selectedIndex = getConfigTableFilterKeyByProviderTag()
        
        // finalize the preload process, hide loading bar now ...
        playlistGradientLoadingBar.hide()
    }
    
    @objc
    func setupUILoadUserProfileImages(
       _ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
              let profileUser = userInfo["profileUser"] as? SPTUser,
              let profileImageURL = userInfo["profileImageURL"] as? URL,
              let profileImageURLAvailable = userInfo["profileImageURLAvailable"] as? Bool,
              let date = userInfo["date"] as? Date else { return }
        
        userProfilesHandled.append(profileUser.canonicalUserName)
        
        var profileImageURLFinal: String = "\(_sysDefaultAvatarFallbackURL)/\(profileUser.canonicalUserName)"
        if  profileImageURLAvailable {
            profileImageURLFinal = profileImageURL.absoluteString
        };  userProfilesHandledWithImages[profileUser.canonicalUserName] = profileImageURLFinal
        
        // all userProfiles handled? start refresh/enrichment cache process
        if  userProfilesHandled.count == userProfilesInPlaylistsUnique.count {

            let playlistFilterMetaKeyStart = self.playlistFilterMeta.count - 1
            
            for (_userName, _userProfileImageURL) in userProfilesHandledWithImages {
                
                // persisting user images by using an separate cache stack
                ImageDownloader.default.downloadImage(
                    with: URL(string: _userProfileImageURL)!,
                    options: [],
                    progressBlock: nil
                ) {
                    
                    (image, error, url, data) in
                    
                    if let _rawImage = image {
                        
                        self.userProfilesCachedForFilter += 1
                        
                        ImageCache.default.store( _rawImage, forKey: "\(_userProfileImageURL)", toDisk: true)
                       
                        var profileImageMin = _rawImage.kf.resize(to: self.sysPlaylistFilterOwnerImageSize)
                        var profileImageActive = profileImageMin
                        var profileImageNormal = profileImageMin.kf.overlaying(
                            with: UIColor(netHex: 0x222222),
                            fraction: 0.67
                        )
                        
                        var ownerFilterItem = MenuItem(
                            image : profileImageNormal,
                            highlightedImage : profileImageActive
                        )
                        
                        ownerFilterItem.backgroundColor = self.sysPlaylistFilterBackgroundColor
                        ownerFilterItem.highlightedBackgroundColor = self.sysPlaylistFilterHighlightColor
                        ownerFilterItem.shadowColor = self.sysPlaylistFilterShadowColor
                        
                        // extend previously set basic filter meta description block by profile filter description
                        self.playlistFilterMeta += [playlistFilterMetaKeyStart + self.userProfilesCachedForFilter : [
                            "title": "All Playlists of \(_userName)",
                            "description": "Fetch all \(_userName)'s playlists",
                            "image_key": -1,
                            "query_override": From<StreamPlayList>().where(\StreamPlayList.owner == _userName),
                            "query_order_use_internals": false
                        ]]
                        
                        // extend previously set basic filter items by user profiles
                        self.playListBasicFilterItems.append(ownerFilterItem)
                        
                        // final user profile image handled? good init/load filterMenu now
                        if  self.userProfilesCachedForFilter == self.userProfilesHandledWithImages.count {
                            self.setupUILoadMenuFilterItems( self.playListBasicFilterItems )
                        }
                    }
                }
                
                // fetch all known playlists for corresponding (profile available) user
                if  let _playListCache = CoreStore.defaultStack.fetchAll(
                    From<StreamPlayList>().where(
                        (\StreamPlayList.provider == defaultStreamingProvider) &&
                        (\StreamPlayList.owner    == _userName))
                    ) {

                    //
                    // update cache entity for this user, add userProfileImageURL and dispatch queue
                    // using side-thread to prevent known async write-through issues inside coreStore
                    // sync-db-calls.
                    //
                    
                    for playlistInDb in _playListCache {
                        
                        // ignore self owned image profiles (already fetched)
                        if playlistInDb.ownerImageURL == _userProfileImageURL { continue }
                        self.handlePlaylistDbCacheOwnerProfileData([
                            "playlist": playlistInDb,
                            "userProfileName": _userName,
                            "userProfileImageURL": _userProfileImageURL,
                            "userProfileData": profileUser
                            ]
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
    
    func setupUICollapseAllVisibleOpenCells() {
        
        var duration = 0.0
        
        let cells = tableView.visibleCells as! Array<PlaylistTableFoldingCell>
        for (index, cell) in cells.enumerated() {
            if  cell.isUnfolded {
                cell.unfold(false, animated: false, completion: nil)
                duration = sysCloseCellDuration
                cellHeights[index] = sysCloseCellHeight
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                },  completion: nil)
            }
        }
    }
    
    @objc
    func setupUILoadExtendedPlaylists() {
        
        // fetch logical filterBlock by key selection index
        let filterKey = getConfigTableFilterKeyByProviderTag()
        let filterBlock = getFilterBlockByIndex( filterKey )
        // call specific filter action corresponding to current filter-item menu selection
        handleTableFilterByFetchChainQuery(
            filterBlock.2,
            filterBlock.3,
            filterBlock.4
        )
    }
    
    @objc
    func setupUILoadMetaExtendedPlaylists() {
        
        // in this version of aqoo only a base set of meta data will be extending our playlist rows
        handlePlaylistExtendedMetaEnrichment()
        // further enrichments are in alpha and will be available soon
        // ...
    }
    
    @objc
    func setupUILoadCloudPlaylists() {
        
        var _playListFingerprint: String!
        var _progress: Float! = 0.0
        
        // clear internal cache for playlists
        spotifyClient.playListHashesInCloud = []
        spotifyClient.playListHashesInCache = []
        
        // clear internal cache for user profiles
        userProfilesHandledWithImages = [:]
        userProfilesHandled = []
        userProfilesInPlaylistsUnique = []
        userProfilesInPlaylists = []
        
        for (playlistIndex, playListInCloud) in spotifyClient.playlistsInCloud.enumerated() {
            
            _playListFingerprint = playListInCloud.getMD5Identifier()
            userProfilesInPlaylists.append(playListInCloud.owner.canonicalUserName)
            
            _progress = (Float(playlistIndex + 1) / Float(spotifyClient.playlistsInCloud.count)) * 100.0

            if  debugMode == true {
                print ("\nlist: #\(playlistIndex) [ \(playListInCloud.name) ]")
                print ("contains: \(playListInCloud.trackCount) playlable songs")
                print ("owner: \(playListInCloud.owner.canonicalUserName)")
                print ("playlist covers: \(playListInCloud.images?.count) (alternativ covers)")
                print ("uri: \(playListInCloud.playableUri)")
                print ("hash: \(_playListFingerprint!) [ aqoo fingerprint ]")
                print ("progress: \(_progress!)")
                print ("\n--")
            }
            
            handlePlaylistDbCacheCoreData (playListInCloud, playlistIndex, spotifyClient.spfStreamingProviderDbTag)
        }
    }
    
    func handlePlaylistIncompletData(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
     
        playlistCell.lblPlaylistName.alpha = 1
        playlistCell.imageViewPlaylistCover.alpha = 1
        playlistCell.imageViewPlaylistOwner.alpha = 1
        playlistCell.lblPlaylistMetaTrackCount.backgroundColor = UIColor(netHex: 0x222222)
        if  playlistCell.metaPlaylistInDb!.isIncomplete == true {
            playlistCell.imageViewPlaylistCover.alpha = 0.475
            playlistCell.imageViewPlaylistOwner.alpha = 0.475
            playlistCell.lblPlaylistName.alpha = 0.475
            playlistCell.lblPlaylistMetaTrackCount.backgroundColor = UIColor(netHex: 0xFC1155)
        }
    }
    
    func handlePlaylistOwnerImageMeta(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
    
         playlistCell.metaOwnerName = playlistItem.owner
        
        // ignore "spotify label" for all internal playlist - otherwise activate spotify marker
        playlistCell.imageViewPlaylistIsSpotify.isHidden = false
        if  playlistItem.isSpotify == false ||
            playlistItem.isPlaylistVotedByStar == true ||
            playlistItem.isPlaylistRadioSelected == true ||
            playlistItem.isPlaylistYourWeekly == true {
            
            playlistCell.imageViewPlaylistIsSpotify.isHidden = true
        }
        
        playlistCell.imageViewPlaylistOwner.image = UIImage(named: _sysDefaultUserProfileImage)
        if  playlistItem.ownerImageURL != nil && playlistItem.ownerImageURL != "" {
            handleOwnerProfileImageCacheForCell(playlistItem.owner, playlistItem.ownerImageURL, playlistCell)
        }
    }
    
    func handlePlaylistCellCoverImages(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        // set default cover image using makeLetterAvatar vendor library call (for normal and detail cell view)
        playlistCell.imageViewPlaylistCover.image = UIImage(named: _sysDefaultCoverImage)
        playlistCell.imageViewPlaylistCoverInDetail.image = UIImage.makeLetterAvatar(withUsername: playlistItem.metaListInternalName)
        
        // set final cover image based on current playlist model and corresponding imageView
        var playlistCoverView: UIImageView! = playlistCell.imageViewPlaylistCover
        var playlistCoverRawView: UIImageView! = playlistCell.imageViewPlaylistCoverRaw
        var playlistCoverDetailView: UIImageView! = playlistCell.imageViewPlaylistCoverInDetail
        
        if  playlistItem.coverImagePathOverride != nil {
            if  let _image = getImageByFileName(playlistItem.coverImagePathOverride!) {
                playlistCoverView.image = _image
                playlistCoverDetailView.image = _image
            }   else {
                handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted cover image for your playlist")
            }
            
        }   else {
            var coverImageBlock = getCoverImageViewByCacheModel(
                playlistItem,
                playlistCoverRawView,
                playlistCoverView,
                playlistCoverDetailView
            )
            
            // set image cover in foldingCell normalView and set corresponding cacheKey
            if  coverImageBlock.normalView != nil {
                playlistCell.imageCacheKeyNormalView = coverImageBlock.normalViewCacheKey
                playlistCoverView = coverImageBlock.normalView
            }
            
            // set image cover in foldingCell detailView and set cacheKey
            if  coverImageBlock.detailView != nil {
                playlistCell.imageCacheKeyDetailView = coverImageBlock.detailViewCacheKey
                playlistCoverDetailView = coverImageBlock.detailView
            }
        }
    }
    
    func handlePlaylistCellMetaFields(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        playlistCell.metaPlaylistInDb = playlistItem
        
        // add some meta data in normalView of our playlistItemCell
        playlistCell.lblPlaylistName.text = playlistItem.metaListInternalName
        playlistCell.lblPlaylistNameInDetail.text = playlistItem.metaListInternalName
        playlistCell.lblPlaylistMetaTrackCount.text = String(playlistItem.trackCount)
        
        // add some meta data in detailView of our playlistItemCell
        playlistCell.lblPlaylistMetaTrackCountInDetail.text = playlistItem.trackCount.hrFormatted
        playlistCell.lblPlaylistMetaPlayCount.text = playlistItem.metaNumberOfPlayed.hrFormatted
        playlistCell.lblPlaylistMetaUpdateCount.text = playlistItem.metaNumberOfUpdates.hrFormatted
        playlistCell.lblPlaylistMetaShareCount.text = playlistItem.metaNumberOfShares.hrFormatted
        playlistCell.lblPlaylistMetaFollowerCount.text = playlistItem.metaNumberOfFollowers.hrFormatted
        
        playlistCell.lblPlaylistMetaFollowerCount.alpha = 1.0
        if  playlistItem.metaNumberOfFollowers == 0 {
            playlistCell.lblPlaylistMetaFollowerCount.alpha = sysPlaylistMetaFieldEmptyAlpha
        }
        
        playlistCell.lblPlaylistMetaShareCount.alpha = 1.0
        if  playlistItem.metaNumberOfShares == 0 {
            playlistCell.lblPlaylistMetaShareCount.alpha = sysPlaylistMetaFieldEmptyAlpha
        }
        
        playlistCell.lblPlaylistMetaUpdateCount.alpha = 1.0
        if  playlistItem.metaNumberOfUpdates == 0 {
            playlistCell.lblPlaylistMetaUpdateCount.alpha = sysPlaylistMetaFieldEmptyAlpha
        }
        
        playlistCell.lblPlaylistMetaPlayCount.alpha = 1.0
        if  playlistItem.metaNumberOfPlayed == 0 {
            playlistCell.lblPlaylistMetaPlayCount.alpha = sysPlaylistMetaFieldEmptyAlpha
        }
    }
    
    func handlePlaylistTimeAndDateMeta(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        playlistCell.lblPlaylistUpdatedAt.alpha = sysPlaylistMetaFieldEmptyAlpha
        playlistCell.lblPlaylistUpdatedAt.text = "not yet"
        if  let playlistUpdatedAt = playlistItem.updatedAt as? Date {
            playlistCell.lblPlaylistUpdatedAt.alpha = 1.0
            playlistCell.lblPlaylistUpdatedAt.text = getHumanReadableDate(playlistUpdatedAt)
        }
        
        playlistCell.lblPlaylistCreatedAt.alpha = sysPlaylistMetaFieldEmptyAlpha
        playlistCell.lblPlaylistCreatedAt.text = "not yet"
        if  let playlistCreatedAt = playlistItem.createdAt as? Date {
            playlistCell.lblPlaylistCreatedAt.alpha = 1.0
            playlistCell.lblPlaylistCreatedAt.text = getHumanReadableDate(playlistCreatedAt)
        }
        
        // metaListOverallPlaytimeInSeconds
        playlistCell.lblPlaylistPlaytimeInDetail.alpha = sysPlaylistMetaFieldEmptyAlpha
        playlistCell.lblPlaylistPlaytimeInDetail.text = "unknown"
        if  let playlistOverallPlaytime = playlistItem.metaListOverallPlaytimeInSeconds as? Int32 {
            playlistCell.lblPlaylistPlaytimeInDetail.alpha = 1.0
            playlistCell.lblPlaylistPlaytimeInDetail.text = getSecondsAsHoursMinutesSecondsString(Int(playlistOverallPlaytime))
        }
    }
    
    func handlePlaylistRatingBlockMeta(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        let maxRatingBarWidth = Float(playlistCell.cViewPlaylistRatingIntensity.frame.width)
        let maxRatingBarHeight = Float(playlistCell.cViewPlaylistRatingIntensity.frame.height)
        let calcRatingBarWidthForArousal = (playlistItem.metaListRatingArousal * maxRatingBarWidth) / 100
        let calcRatingBarWidthForValence = (playlistItem.metaListRatingValence * maxRatingBarWidth) / 100
        let calcRatingBarWidthForDepth = (playlistItem.metaListRatingDepth * maxRatingBarWidth) / 100
        
        let cViewIcnRatingIntensity = UIImageView(image: UIImage(named: "icnRateIntensity_v1")!)
        let cViewIcnRatingEmotional = UIImageView(image: UIImage(named: "icnRateEmotional_v1")!)
        let cViewIcnRatingDepth = UIImageView(image: UIImage(named: "icnRateDepth_v1")!)
        
        cViewIcnRatingIntensity.frame = CGRect(x: 2, y: 3, width: 11, height: 11)
        cViewIcnRatingEmotional.frame = CGRect(x: 2, y: 3, width: 11, height: 11)
        cViewIcnRatingDepth.frame = CGRect(x: 2, y: 3, width: 11, height: 11)
        
        // add intensity (arousal) rating
        for subview in playlistCell.cViewPlaylistRatingIntensity.subviews {
            subview.removeFromSuperview()
        };  playlistCell.cViewPlaylistRatingIntensity.addSubview(
                getRatingLabel(0, 0, CGFloat(calcRatingBarWidthForArousal), CGFloat(maxRatingBarHeight))
            );  playlistCell.cViewPlaylistRatingIntensity.addSubview(cViewIcnRatingIntensity)
        
        // add emotional (valence) rating
        for subview in playlistCell.cViewPlaylistRatingEmotional.subviews {
            subview.removeFromSuperview()
        };  playlistCell.cViewPlaylistRatingEmotional.addSubview(
                getRatingLabel(0, 0, CGFloat(calcRatingBarWidthForValence), CGFloat(maxRatingBarHeight))
            );  playlistCell.cViewPlaylistRatingEmotional.addSubview(cViewIcnRatingEmotional)
        
        // add depth (intellectual) rating
        for subview in playlistCell.cViewPlaylistRatingDepth.subviews {
            subview.removeFromSuperview()
        };  playlistCell.cViewPlaylistRatingDepth.addSubview(
                getRatingLabel(0, 0, CGFloat(calcRatingBarWidthForDepth), CGFloat(maxRatingBarHeight))
            );  playlistCell.cViewPlaylistRatingDepth.addSubview(cViewIcnRatingDepth)
    }

    /*
     * this method will be called every n-seconds to ensure your lists are up to date
     */
    @objc
    func handleCacheTimerEvent() {
        
        if  self.debugMode == true {
            ImageCache.default.calculateDiskCacheSize { size in
                print ("dbg [playlist] : cache ➡ used image cache in bytes: \(size)/\(self.sysImgCacheInMb * 1024)")
            }
            
        };  handlePlaylistCloudRefresh()
    }
    
    func handlePlaylistCacheCleanUp() {
        
        let localCacheCleanUpRequest = UIAlertController(
            title: "Remove Local Cache?",
            message: "you are in devMode of this app, do you want to delete the complete local cache now?",
            preferredStyle: UIAlertControllerStyle.alert
        )
        
        let dlgBtnYesAction = UIAlertAction(title: "Yes", style: .default) { (action: UIAlertAction!) in
            
            if  self.debugMode == true {
                print ("dbg [playlist] : cache ➡ cleanUp local image cache")
            }
            
            ImageCache.default.clearMemoryCache()
            ImageCache.default.clearDiskCache()
            
            CoreStore.defaultStack.perform(
                
                asynchronous: { (transaction) -> [StreamPlayList]? in
                    
                    return transaction.fetchAll(From<StreamPlayList>()) },
                
                success: { (transactionPlaylists) in
                    
                    if  transactionPlaylists?.isEmpty == false && self.debugMode == true {
                        print ("dbg [playlist] : cache ➡ cleanUp local db cache, \(transactionPlaylists!.count - 1) rows will be removed")
                    }
                },
                
                failure: { (error) in
                    
                    self.handleErrorAsDialogMessage(
                        "Error Loading Playlist Cache",
                        "Oops! An error occured while loading playlists from database ..."
                    )
                }
            )
            
            CoreStore.defaultStack.perform(
                asynchronous: { (transaction) -> Void in transaction.deleteAll(From<StreamPlayList>()) },
                completion: { (result) -> Void in
                    
                    switch result {
                    case .failure(let error): if self.debugMode == true { print (error) }
                    case .success(let userInfo):
                        if  self.debugMode == true {
                            self.spotifyClient.playlistRefreshEnforced = true
                            self.handlePlaylistCloudRefresh()
                            print ("dbg [playlist] : cache ➡ local db cache removed")
                        }
                    }
                }
            )
        }
        
        let dlgBtnCancelAction = UIAlertAction(title: "No", style: .default) { (action: UIAlertAction!) in
            
            self.spotifyClient.playlistRefreshEnforced = true
            self.handlePlaylistCloudRefresh()
            
            return
        }
        
        localCacheCleanUpRequest.addAction(dlgBtnYesAction)
        localCacheCleanUpRequest.addAction(dlgBtnCancelAction)

        present(localCacheCleanUpRequest, animated: true, completion: nil)
    }
    
    func handlePlaylistCloudRefresh() {
        
        if  spotifyClient.isSpotifyTokenValid() {
            
            if  playlistInCloudLastLocalUpdate == nil ||
                Date() >= (playlistInCloudLastLocalUpdate! + _sysPlaylistCacheRefreshEnforce) ||
                spotifyClient.playlistsInCloud.count == 0 ||
                spotifyClient.playlistRefreshEnforced == true {
                
                loadProvider ( spotifyClient.spfStreamingProviderDbTag )
                
                playlistInCloudLastLocalUpdate = Date()
                spotifyClient.playlistRefreshEnforced = false
                
            }   else {
                
                if  debugMode == true {
                    print ("dbg [playlist] : using playlist cache, no update required now")
                    handlePlaylistReloadData()
                };  return
 
            }
            
        } else {
            
            if  debugMode == true {
                print ("dbg [playlist] : Oops, your cloudProviderToken is not valid anymore")
            };  btnExitLandingPageAction( self )
        }
    }
    
    func handleShareContentCompletion(
         activityType: UIActivityType?,
         shared: Bool,
         items: [Any]?,
         error: Error?) {
        
        var _playListInDb: StreamPlayList?
        var _playListMetaListHash: String?
        
        if  shared == false {
            if debugMode == true {
                print ("dbg [playlist/share/aborted] : user canceled content share - return ...")
            }
            
            return
        }
        
        CoreStore.defaultStack.perform(
            
            asynchronous: { (transaction) -> Void in
                
                // render hash for new playlist using corresponding cloud entry
                _playListMetaListHash = self.playlistInCacheSelected!.getMD5Identifier()
                
                // corresponding playlist entry exists in db? Check this entry again and prepare for update
                _playListInDb = transaction.fetchOne(
                    From<StreamPlayList>().where((\StreamPlayList.metaListHash == _playListMetaListHash!))
                )
                
                // update share meta information block
                if  _playListInDb != nil {
                    _playListInDb!.metaNumberOfShares += 1
                }
            },
            completion: { (result) -> Void in
                
                switch result {
                    case .failure(let error): if self.debugMode == true { print (error) }; break
                    case .success(let userInfo):
                    if self.debugMode == true {
                        print ("dbg [playlist/share/success] number of shares updated")
                    };  break
                }
            }
        )
    }
    
    func getPlaylistTracksFromProxyCache(
       _ playlistIdentifier: String)
         -> ([ProxyStreamPlayListTrack], Int) {
        
        var availablePlaylistTracks = [ProxyStreamPlayListTrack]()
        var sumPlaytimeInSeconds = 0
        
        for track in spotifyClient.playlistTracksInCloud {
            
            if  track.playlistIdentifier == playlistIdentifier {
                sumPlaytimeInSeconds = sumPlaytimeInSeconds + Int(track.trackDuration) % 1000
                availablePlaylistTracks.append(track)
            }
        }
        
        return (availablePlaylistTracks, sumPlaytimeInSeconds)
    }
    
    func handlePlaylistExtendedMetaEnrichment() {

        if  let _playListCache = CoreStore.defaultStack.fetchAll(
            From<StreamPlayList>().where((\StreamPlayList.provider == defaultStreamingProvider))
            ) {
            
            for playlist in _playListCache {
                
                var playlistIdentifier : String = playlist.getMD5Identifier()
                var trackIdentifier : String
                var trackInDbCache : StreamPlayListTracks?
                var trackCount : Int64 = 0
                
                CoreStore.defaultStack.perform(
                    
                    asynchronous: { (transaction) -> Void in
                        
                        guard let playlistToUpdate = transaction.fetchOne(
                            From<StreamPlayList>().where(\.metaListHash == playlistIdentifier))
                            as? StreamPlayList else { return }
                        
                        guard let playlistInCloudExt = self.handlePlaylistExtendedMetaData( playlist )
                            as? ProxyStreamPlayListExtended else { return }
                        
                        guard let playlistTracksInCloud = self.getPlaylistTracksFromProxyCache( playlistIdentifier )
                            as? ([ProxyStreamPlayListTrack], Int) else { return }
                        
                        playlistToUpdate.metaNumberOfFollowers = playlistInCloudExt.playlistFollowerCount
                        playlistToUpdate.metaListSnapshotId = playlistInCloudExt.playlistSnapshotId
                        playlistToUpdate.metaListSnapshotDate = Date()
                        playlistToUpdate.metaListOverallPlaytimeInSeconds = Int32(playlistTracksInCloud.1)
                        
                        // handle & persist all tracks in each given playlist
                        for (index, track) in (playlistTracksInCloud.0).enumerated() {
                            
                            trackCount += 1
                            
                            trackInDbCache = transaction.fetchOne(
                                From<StreamPlayListTracks>()
                                    .where((\StreamPlayListTracks.playlist == playlistToUpdate) &&
                                           (\StreamPlayListTracks.trackURIInternal == track.trackURIInternal.absoluteString))
                                
                            )
                            
                            if  trackInDbCache == nil {
                                
                                trackInDbCache = transaction.create(Into<StreamPlayListTracks>()) as StreamPlayListTracks
                                trackInDbCache!.createdAt = Date()
                                trackInDbCache!.albumName = track.albumName
                                trackInDbCache!.discNumber = Int16(track.discNumber)
                                trackInDbCache!.playlist = playlistToUpdate
                                trackInDbCache!.trackAddedAt = track.trackAddedAt as Date
                                trackInDbCache!.trackDuration = Int32(track.trackDuration)
                                trackInDbCache!.trackNumber = Int16(track.trackNumber)
                                trackInDbCache!.trackExplicit = track.trackExplicit
                                trackInDbCache!.trackURIInternal = track.trackURIInternal.absoluteString
                                trackInDbCache!.trackIdentifier = track.trackIdentifier
                                trackInDbCache!.trackName = track.trackName
                                trackInDbCache!.trackPopularity = track.trackPopularity
                                trackInDbCache!.albumCoverLargestImageURL = track.albumCoverLargestImageURL
                                trackInDbCache!.albumCoverSmallestImageURL = track.albumCoverSmallestImageURL
                                trackInDbCache!.metaTrackArtists = ""
                                trackInDbCache!.metaTrackIsPlaying = false
                                trackInDbCache!.metaTrackLastTrackPosition = 0
                                trackInDbCache!.metaTrackOrderNumber = Int64(index)
                                
                                let playlist = transaction.edit(playlistToUpdate)!
                                
                                if  self.debugMode == true {
                                    print ("dbg [playlist] : track #\(index) = [\(track.trackName)] NOT found -> CREATED")
                                }
                                
                            }   else {
                                
                                var _trackIndex = trackInDbCache!.metaTrackOrderNumber
                                
                                if  trackInDbCache!.getMD5Fingerprint() == track.getMD5Fingerprint() {
                                    if  self.debugMode == true {
                                        print ("dbg [playlist] : track #\(_trackIndex) = [\(track.trackName)] ignored -> NO_CHANGES")
                                    }
                                    
                                }   else {
                                    
                                    trackInDbCache!.albumName = track.albumName
                                    trackInDbCache!.discNumber = Int16(track.discNumber)
                                    trackInDbCache!.trackAddedAt = track.trackAddedAt as Date
                                    trackInDbCache!.trackDuration = Int32(track.trackDuration)
                                    trackInDbCache!.trackNumber = Int16(track.trackNumber)
                                    trackInDbCache!.trackExplicit = track.trackExplicit
                                    trackInDbCache!.trackURIInternal = track.trackURIInternal.absoluteString
                                    trackInDbCache!.trackIdentifier = track.trackIdentifier
                                    trackInDbCache!.trackName = track.trackName
                                    trackInDbCache!.trackPopularity = track.trackPopularity
                                    trackInDbCache!.albumCoverLargestImageURL = track.albumCoverLargestImageURL
                                    trackInDbCache!.albumCoverSmallestImageURL = track.albumCoverSmallestImageURL
                                    trackInDbCache!.metaNumberOfUpdates += 1
                                    trackInDbCache!.metaTrackArtists = ""
                                    trackInDbCache!.metaTrackIsPlaying = false
                                    trackInDbCache!.metaTrackLastTrackPosition = 0
                                    trackInDbCache!.updatedAt = Date()
                                    
                                    if  self.debugMode == true {
                                        print ("dbg [playlist] : track #\(_trackIndex) = [\(track.trackName)] found -> UPDATED")
                                    }
                                }
                            }
                        }
                    },
                    
                    completion: { (result) -> Void in
                        
                        switch result {
                        case .failure(let error): if self.debugMode == true { print (error) }
                        case .success(let userInfo):
                            if  self.debugMode == true {
                                print ("dbg [playlist] = [\(playlist.metaListInternalName)], \(trackCount) tracks handled -> EXTENDED")
                                print ("---")
                            }
                        }
                    }
                )
            }
        }
    }
    
    func handlePlaylistProfileEnrichment() {
        
        // unify current userProfile array, remove double entries
        userProfilesInPlaylistsUnique = Array(Set(userProfilesInPlaylists))
        
        if  debugMode == true {
            print ("dbg [playlist] : enrich playlists by adding \(userProfilesInPlaylistsUnique.count) user profiles")
            print ("dbg [playlist] : playlist profiles ➡ \(userProfilesInPlaylistsUnique.joined(separator: ", "))")
        }
        
        for _profileUserName in userProfilesInPlaylistsUnique {
            
            if  debugMode == true {
                print ("dbg [playlist] : send userProfile request (event) for [ \(_profileUserName) ]")
            }
            
            spotifyClient.getUserProfileImageURLByUserName(
                _profileUserName, spotifyClient.spfCurrentSession!.accessToken
            )
        }
    }
    
    func handlePlaylistDbCacheCoreDataOrphans () {
        
        if let _playListCache = CoreStore.defaultStack.fetchAll(
            From<StreamPlayList>().where((\StreamPlayList.provider == defaultStreamingProvider))
        ) {
            
            for playlist in _playListCache {
                
                if spotifyClient.playListHashesInCloud.contains(playlist.metaListHash) {
                   spotifyClient.playListHashesInCache.append(playlist.metaListHash)
                   
                   continue
                }

                if  debugMode == true {
                    print ("dbg [playlist] : [\(playlist.metaListInternalName)] orphan flagged for removal")
                }
                
                CoreStore.defaultStack.perform(
                    
                    asynchronous: { (transaction) -> Void in
                        
                        let orphanPlaylist = transaction.fetchOne(
                            From<StreamPlayList>().where((\StreamPlayList.metaListHash == playlist.metaListHash))
                        );  transaction.delete(orphanPlaylist)
                    },
                    
                    completion: { (result) -> Void in
                    
                        switch result {
                        case .failure(let error): if self.debugMode == true { print (error) }
                        case .success(let userInfo):
                            if  self.debugMode == true {
                                print ("dbg [playlist] : [\(playlist.metaListInternalName)] handled -> REMOVED")
                            }
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
            
            for coverImageAlt in playListInCloud.images! {
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
            playlistCell.imageViewPlaylistOwnerInDetail.image = playlistCell.imageViewPlaylistOwner.image
        }   else {
            
            let _profileImageProcessor = ResizingImageProcessor(
                 referenceSize: _sysUserProfileImageSize)
                .append(another: RoundCornerImageProcessor(cornerRadius: _sysUserProfileImageCRadiusInDeg))
                .append(another: BlackWhiteProcessor())
            
            
            playlistCell.imageViewPlaylistOwner.kf.setImage(
                with: URL(string: userProfileImageURL),
                placeholder: UIImage(named: _sysDefaultUserProfileImage),
                options: [.transition(.fade(0.2)), .processor(_profileImageProcessor)],
                completionHandler: {
                    (image, error, cacheType, imageUrl) in
                    
                    if  image != nil {
                        playlistCell.imageViewPlaylistOwnerInDetail.image = image
                    }
                }
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
       _ payload: [String: Any]) {

        guard let userProfile = payload["userProfileData"] as? SPTUser,
              let userProfileImageURL = payload["userProfileImageURL"] as? String,
              let userProfileUserName = payload["userProfileName"] as? String,
              let playListInDb = payload["playlist"] as? StreamPlayList else { return }

        CoreStore.defaultStack.perform(
            
            // stability issue :: sometimes this async process will terminate the app
            asynchronous: { (transaction) -> Void in
                
                do {
                    
                    playListInDb.ownerImageURL = userProfileImageURL
                    playListInDb.ownerFollowerCount = userProfile.followerCount
                    if  userProfile.sharingURL != nil {
                        playListInDb.ownerSharingURL = userProfile.sharingURL.absoluteString
                    }
                    
                } catch {
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist] : [\(playListInDb.ownerImageURL)] not handled -> EXCEPTION")
                    }
                    
                    return
                }
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }
                case .success(let userInfo):
                    self.handlePlaylistDbCacheOwnerProfileInitialTableViewData(
                        userProfileUserName,
                        userProfileImageURL
                    )
                }
            }
        )
    }
    
    func handlePlaylistExtendedMetaData (
       _ playListInDb: StreamPlayList) -> ProxyStreamPlayListExtended? {
        
        for cloudExt in spotifyClient.playlistsInCloudExtended {
            
            if cloudExt.playlistIdentifier == playListInDb.getMD5Identifier() {
                
               return cloudExt
            }
        }
        
        return nil
    }
    
    func handlePlaylistDbCacheCoreData (
       _ playListInCloud: SPTPartialPlaylist,
       _ playListIndex: Int,
       _ providerTag: String ) {
        
        var _playListInDb: StreamPlayList?
        var _playListMetaListHash: String?
        var _playlistIsMine: Bool = false
        var _playlistIsSpotify: Bool = false
        var _ownerProfileImageURL: URL?
        var _ownerProfileImageStringURL: String = ""
        var _currentUserName = spotifyClient.spfCurrentSession?.canonicalUsername

        //
        // prepare some devMode relavant meta-data for single playlists here to simulate
        // played, playedParty, playedCompletly and number of shares during development
        //
        
        let _rate_intensity = Int.random(0, 100)
        let _rate_emotional = Int.random(0, 100)
        let _rate_depth = Int.random(0, 100)
        
        var _playlistTitleRaw: String = ""
        
        CoreStore.defaultStack.perform(
            
            asynchronous: { (transaction) -> Void in
                
                // render hash for new playlist using corresponding cloud entry
                _playListMetaListHash = playListInCloud.getMD5Identifier()
                
                // corresponding playlist entry exists in db? Check this entry again and prepare for update
                _playListInDb = transaction.fetchOne(
                    From<StreamPlayList>().where((\StreamPlayList.metaListHash == _playListMetaListHash!))
                )
                
                _playlistIsMine = false
                _playlistIsSpotify = false
                
                // playlist cache entry in local db not available or not fetchable yet? Create a new one ...
                if  _playListInDb == nil {
                    
                    if  playListInCloud.owner.canonicalUserName == _currentUserName {
                       _playlistIsMine = true
                    }
                    
                    if  playListInCloud.owner.canonicalUserName == self._sysDefaultSpotifyUsername {
                       _playlistIsSpotify = true
                    }

                    if _ownerProfileImageURL != nil {
                       _ownerProfileImageStringURL = _ownerProfileImageURL!.absoluteString
                    }
                    
                    // (raw)fetch all kind of titles including empty/whitespaced ones
                    _playlistTitleRaw = playListInCloud.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if  self.debugLoadFixtures == true && self.debugMode == true {
                        print ("fixture_load --> x[\(_rate_intensity)] rate/intensity")
                        print ("fixture_load --> x[\(_rate_emotional)] rate/emotional")
                        print ("fixture_load --> x[\(_rate_depth)] rate/depth")
                    }
                    
                    _playListInDb = transaction.create(Into<StreamPlayList>()) as StreamPlayList
                    
                    _playListInDb!.createdAt = Date()
                    _playListInDb!.playableURI = playListInCloud.playableUri.absoluteString
                    _playListInDb!.trackCountOld = 0
                    _playListInDb!.trackCount = Int32(playListInCloud.trackCount)
                    _playListInDb!.isCollaborative = playListInCloud.isCollaborative
                    _playListInDb!.isPublic = playListInCloud.isPublic
                    _playListInDb!.isIncomplete = false
                    
                    _playListInDb!.metaLastListenedAt = nil
                    _playListInDb!.metaNumberOfUpdates = 0
                    _playListInDb!.metaNumberOfShares = 0
                    _playListInDb!.metaNumberOfFollowers = 0
                    _playListInDb!.metaNumberOfPlayed = 0
                    _playListInDb!.metaNumberOfPlayedPartly = 0
                    _playListInDb!.metaNumberOfPlayedCompletely = 0
                    _playListInDb!.metaListNameOrigin = _playlistTitleRaw
                    
                    // some playlists will be handled icomplete and will (re)fetched during the next viewLoad process, ..
                    // a single spaced playlistName identify those playlist meta results - I'll tag those also in advance
                    if (_playlistTitleRaw == "") {
                        _playListInDb!.metaListNameOrigin = "playlist #\(playListIndex)"
                        if  playListInCloud.owner.displayName != nil {
                           _playListInDb!.metaListNameOrigin = "\(playListInCloud.owner.displayName!)'s playlist #\(playListIndex)"
                           _playListInDb!.isIncomplete = true
                        }
                    }
                    
                    //
                    // activate simulated meta values for single playlist entries during loadUp
                    // on devMode (debugLoadFixtures) - will be removed on release
                    //
                    if self.debugLoadFixtures == true {
                        _playListInDb!.metaListRatingArousal = Float(_rate_intensity)
                        _playListInDb!.metaListRatingValence = Float(_rate_emotional)
                        _playListInDb!.metaListRatingDepth = Float(_rate_depth)
                    }
                    
                    _playListInDb!.metaNumberOfShares = 0
                    _playListInDb!.isPlaylistVotedByStar = false
                    _playListInDb!.isPlaylistRadioSelected = false
                    _playListInDb!.isPlaylistHidden = false
                    
                    _playListInDb!.metaListHash = _playListMetaListHash!
                    _playListInDb!.metaPreviouslyUpdated = false
                    _playListInDb!.metaPreviouslyUpdatedManually = false
                    _playListInDb!.metaPreviouslyCreated = true
                    _playListInDb!.isMine = _playlistIsMine
                    _playListInDb!.isSpotify = _playlistIsSpotify
                    _playListInDb!.owner = playListInCloud.owner.canonicalUserName
                    _playListInDb!.ownerImageURL = _ownerProfileImageStringURL
                    _playListInDb!.aqooUserId = _currentUserName!
                    _playListInDb!.metaWeight = filterInternalWeight.Default.rawValue
                    _playListInDb!.currentPlayMode = playMode.Stopped.rawValue // (0: no-action)
                    
                    _playListInDb!.metaListInternalName = _playListInDb!.metaListNameOrigin
                    _playListInDb!.metaListInternalDescription = self.getPlaylistInternalDescription(
                         playListInCloud,
                        _playListInDb!
                    )
                    
                    _playListInDb!.provider = transaction.fetchOne(
                        From<StreamProvider>().where((\StreamProvider.tag == providerTag))
                    )
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist] : [\(_playListInDb!.metaListInternalName)] handled -> CREATED")
                    }
                
                //
                // playlist cache entry found in local db? Check for changes by comparing both fingerprints
                // and update corresponding cache value (local db entry) on any kind of fingerprint mismatch
                //
                    
                }   else {
                 
                    if _playListInDb!.getMD5Fingerprint() == playListInCloud.getMD5Fingerprint() {
                        
                        if  self.debugMode == true {
                            print ("dbg [playlist] : [\(_playListInDb!.metaListInternalName)] handled -> NO_CHANGES")
                        }
                        
                    }   else {
                        
                        // name (origin) , number of tracks or flags for public/collaborative changed? update list
                        _playListInDb!.metaListNameOrigin = playListInCloud.name ?? playListInCloud.uri.absoluteString
                        _playListInDb!.trackCountOld = _playListInDb!.trackCount
                        _playListInDb!.trackCount = Int32(playListInCloud.trackCount)
                        _playListInDb!.isCollaborative = playListInCloud.isCollaborative
                        _playListInDb!.isPublic = playListInCloud.isPublic
                        _playListInDb!.isIncomplete = false
                        _playListInDb!.metaNumberOfUpdates += 1
                        _playListInDb!.metaPreviouslyUpdatedManually = false
                        _playListInDb!.metaPreviouslyUpdated = true
                        _playListInDb!.metaPreviouslyCreated = false
                        _playListInDb!.updatedAt = Date()
                        
                        if  self.debugMode == true {
                            print ("dbg [playlist] : [\(_playListInDb!.metaListInternalName)] handled -> UPDATED")
                        }
                    }
                }
                
                // last step - handle playlist media data, using vendor functionality (kingfisher cache)
                _playListInDb = self.handlePlaylistDbCacheMediaData(_playListInDb!, playListInCloud)
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }; break
                case .success(let userInfo):
                    // save handled hashed in separate collection
                    self.spotifyClient.playListHashesInCloud.append(_playListMetaListHash!)
                    
                    // evaluate list extension completion and execute event signal after final cache item was handled
                    if  playListIndex == (self.spotifyClient.playlistsInCloud.count - 1) {
                        self.handlePlaylistDbCacheCoreDataOrphans()
                        self.handlePlaylistProfileEnrichment()
                    };  break
                }
            }
        )
    }
    
    func getPlaylistInternalDescription(
       _ playlistInCloud: SPTPartialPlaylist,
       _ playlistInDb: StreamPlayList) -> String {
        
        let _createdDateString: NSString = getDateAsString(playlistInDb.createdAt!)
        
        return "\"\(playlistInCloud.name)\" is a playlist belonging to [\(playlistInCloud.owner.canonicalUserName)]. It was created on \(_createdDateString). Copy the following link to directly access this playlist in Spotify: \(playlistInCloud.playableUri.absoluteString)"
    }
    
    func getCloudVersionOfDbCachedPlaylist(_ playlistInDb: StreamPlayList) -> SPTPartialPlaylist? {
        
        for _playlistInCloud in spotifyClient.playlistsInCloud {
            if  playlistInDb.getMD5Fingerprint() == _playlistInCloud.getMD5Fingerprint() {
                return _playlistInCloud
            }
        }
        
        return nil
    }
    
    //
    // primary list load meta method, this function will be used to load all our playlist data including tracks,
    // owner, extended meta information and media content (only spotify will be supported in this version of aqoo)
    //
    // -> loadProviderPlaylists()
    //
    func loadProvider (
       _ tag: String) {
        
        CoreStore.defaultStack.perform(
            
            asynchronous: { (transaction) -> StreamProvider? in
                
                return transaction.fetchOne(
                    From<StreamProvider>()
                        .where((\StreamProvider.tag == tag) && (\StreamProvider.isActive == true))
                )
            },
            
            success: { (transactionProvider) in
                
                if transactionProvider != nil {
                    
                    self.spotifyClient.spfStreamingProvider = transactionProvider!
                    if  self.debugMode == true {
                        print ("dbg [playlist] : provider [\(tag)] successfully loaded, fetching playlists now")
                    };  self.loadProviderPlaylists ( self.spotifyClient.spfStreamingProvider! )
                    
                }   else {
                    
                    self.handleErrorAsDialogMessage(
                        "Error Loading Provider",
                        "Oops! [\(tag)] wasn't found in supported provider stack"
                    )
                }
            },
            
            failure: { (error) in
                self.handleErrorAsDialogMessage(
                    "Error Loading Provider",
                    "Oops! An error occured while loading provider from database ..."
                )
            }
        )
    }
    
    func loadProviderPlaylists (
       _ provider: StreamProvider) {
        
        // first of all fetch new playlists from api for comparision
        spotifyClient.handlePlaylistGetFirstPage(
            spotifyClient.spfUsername,
            spotifyClient.spfCurrentSession!.accessToken
        )
        
        // now (pre)fetch corresponding local playlists for sync process
        CoreStore.defaultStack.perform(
            
            asynchronous: { (transaction) -> [StreamPlayList]? in
                
                self.defaultStreamingProvider = provider
                
                return transaction.fetchAll(From<StreamPlayList>().where(
                        (\StreamPlayList.provider == provider) &&
                        (\StreamPlayList.isIncomplete  == false)
                    )
                )
            },
            
            success: { (transactionPlaylists) in
                
                HUD.flash(.label("loading playlists"), delay: 2.0)
                
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
                        self.playlistGradientLoadingBar.hide()
                }
            },
            
            failure: { (error) in
                
                self.handleErrorAsDialogMessage(
                    "Error Loading Playlists",
                    "Oops! An error occured while loading playlists from database ..."
                )
            }
        )
    }

    func handlePlaylistHiddenFlag(
       _ playlistInDb: StreamPlayList) {
        
        var newHiddenState: Bool = !playlistInDb.isPlaylistHidden
        var hiddenStateVerb: String = "Disable"
        var hiddenStateInformation: String = "You can find this playlist using the 'show-hidden' filter"
        var _playListInDb: StreamPlayList?
        
        if  newHiddenState == false {
            hiddenStateVerb = "Enable"
            hiddenStateInformation = "This playlist is now visible in all filters again"
        }
        
        CoreStore.defaultStack.perform(
            
            asynchronous: { (transaction) -> Void in
                _playListInDb = transaction.fetchOne(
                    From<StreamPlayList>().where(\StreamPlayList.metaListHash == playlistInDb.getMD5Identifier())
                )
                
                if  _playListInDb != nil {
                    _playListInDb!.isPlaylistHidden = newHiddenState
                    _playListInDb!.updatedAt = Date()
                }
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }
                case .success(let userInfo):
                    
                    self.showUserNotification("\(hiddenStateVerb) \(playlistInDb.metaListInternalName)", hiddenStateInformation, nil, 0.9275)
                    self.setupUILoadExtendedPlaylists()
                    
                    if  self.debugMode == true {
                        print ("dbg [playlist] : [\(playlistInDb.metaListInternalName)] handled -> HIDDEN=\(newHiddenState)")
                    }
                }
            }
        )
    }
    
    func showUserNotification(
       _ title: String,
       _ description: String,
       _ iconImageName: String?,
       _ duration: TimeInterval) {
        
        let bannerView = AppBaseNotification.fromNib(nibName: "AppBaseNotification")
        bannerView.lblTitle.text = title
        bannerView.lblSubTitle.text = description
        
        if  iconImageName != nil {
            bannerView.imgViewNotificationDefault.image = UIImage(named: "\(iconImageName)")
        }
        
        let banner = NotificationBanner(customView: bannerView)
        banner.duration = duration // 0.9275
        banner.onTap = {
            banner.dismiss()
        };  banner.show(bannerPosition: .bottom)
    }
    
    //
    // try to find corresponding PlaylistTableFoldingCell object to update _playlistInCellSelected [..] more precisely
    //
    func handlePlaylistCellObjectsByTapAction(
       _ button: UIButton) {
        
        // majic: iterate through all cell views downside (start at tapped button) and try to find the real PlaylistTableFoldingCell
        guard case let _cell as PlaylistTableFoldingCell = button.ancestors.first(
            where: { $0 is PlaylistTableFoldingCell }
            ) else
            {
                handleErrorAsDialogMessage(
                    "Error Handling Playback Controls",
                    "The local playlist '\(playlistInCacheSelected!.metaListInternalName)' couldn't handled by playback events!"
                );  return
        }
        
        // update current selected cell/cache/cloud variable stack
        playlistInCellSelected  = _cell
        playlistInCacheSelected = _cell.metaPlaylistInDb!
        playlistInCloudSelected = getCloudVersionOfDbCachedPlaylist( playlistInCacheSelected! )
        
        // majic : now decide (based on tapped-button) what action should provide into business logic
        handlePlaylistControlActionByButton( button, _cell )
    }
    
    func handlePlaylistControlActionByButton(
       _ button: UIButton,
       _ playlistCell: PlaylistTableFoldingCell) {
        
        // reset (all) playMode controls of this cell
        playlistCell.mode = .clear
        
        // get playmode from button tag directly
        let designatedPlaymode: Int16 = Int16 ( button.tag )
        
        // (re)fetch playlist from database to handle property changes on playMode definition
        guard let playlistInCache = CoreStore.fetchOne(
            From<StreamPlayList>().where(\StreamPlayList.metaListHash == playlistCell.metaPlaylistInDb!.getMD5Identifier())
            ) as? StreamPlayList else {
                self.handleErrorAsDialogMessage(
                    "Cache Error", "unable to handle playlist from local cache"
                );   return
        }
        
        switch designatedPlaymode {
            
            case playMode.PlayNormal.rawValue:
                
                if  playlistInCache.currentPlayMode != playMode.PlayNormal.rawValue {
                    setPlaylistInPlayMode( playlistCell, playMode.PlayNormal.rawValue )
                    togglePlayModeIcons( playlistCell, true )
                    playlistCell.mode = .playNormal
                    
                }   else {
                    setPlaylistInPlayMode( playlistCell, playMode.Stopped.rawValue )
                    togglePlayModeIcons( playlistCell, false )
                    playlistCell.mode = .clear
                    
                };  break
            
            default:
                
                togglePlayModeIcons( playlistCell, false )
                break
        }
    }
    
    func setupPlayerAuth() {
        
        if  spotifyClient.isSpotifyTokenValid() {
            
            if  localPlayer.player?.loggedIn == true {
                if  self.debugMode == true {
                    print ("dbg [playlist] : player was previously initialized, start refreshing session")
                };  localPlayer.player?.logout()
            };      localPlayer.initPlayer(authSession: spotifyClient.spfCurrentSession!)
            
        }   else {
            
            // @todo: exit view, return to login page!
            self.handleErrorAsDialogMessage(
                "Spotify Session Closed",
                "Oops! your spotify session is not valid anymore, please (re)login again ..."
            )
        }
    }
    
    func setPlaylistInPlayMode(
       _ playlistCell: PlaylistTableFoldingCell,
       _ newPlayMode: Int16) {
     
        var playListInDb: StreamPlayList = playlistCell.metaPlaylistInDb!
        
        if  newPlayMode == playMode.Stopped.rawValue {
            // API_CALL : stop playback - ignore incoming error, just reset cell playState
            try! localPlayer.player?.setIsPlaying(false, callback: { (error) in
                if  self.debugMode == true {
                    print ("dbg [playlist] : stop playlist playback in player directly")
                }
            })
            
            // reset playMode for all (spotify) playlists in cache
            localPlaylistControls.resetPlayModeOnAllPlaylists()
            togglePlayMode( false )
        }
        
        // handle cache queue for playlistCells with "active" playModes ( newPlayMode > 0 )
        playlistInCellSelectedInPlayMode = nil
        if  newPlayMode != playMode.Stopped.rawValue {
            playlistInCellSelectedInPlayMode = playlistCell
            handlePlaylistCellsInPlayMode( playlistCell )
            
            // now play playlist using spotify direct api calls
            localPlayer.player?.playSpotifyURI(
                playListInDb.playableURI,
                startingWith: 0,
                startingWithPosition: 0,
                callback: { (error) in
                    
                    if  error == nil {
                        self.togglePlayMode( true )
                        // send out user notification on any relevant playMode changes
                        self.showUserNotification(
                            "Now playing \(playListInDb.metaListInternalName)",
                            "using \(self.getPlayModeAsString(newPlayMode)) playmode", nil, 0.9275
                        )
                        
                    }   else {
                        
                        self.handleErrorAsDialogMessage("Player Controls Error PCE.01", "\(error?.localizedDescription)")
                        
                        return
                    }
                }
            )
        }
        
        // set new playMode to corrsponding playlist now
        localPlaylistControls.setPlayModeOnPlaylist( playListInDb, newPlayMode )
    }
    
    func resetPlayModeControls(
       _ currentCellPlayingHash: String) {
        
        // iterate through all cells-in-playmode and reset corresponding controls
        for playlistCell in playlistCellsInPlayMode {
            
            if (playlistCell.metaPlaylistInDb!.getMD5Identifier() == currentCellPlayingHash) { continue }
            
            togglePlayModeIcons( playlistCell, false )
            playlistCell.mode = .clear
        }
    }
    
    /*
     *  this method will be called if a given cell switched to ative playMode (mode > 0)
     */
    func handlePlaylistCellsInPlayMode(
       _ playlistCell: PlaylistTableFoldingCell) {
        
        var _inputHash = playlistCell.metaPlaylistInDb!.getMD5Identifier()
        
        if  playlistInCellSelectedInPlayMode != nil {
            resetPlayModeControls ( playlistInCellSelectedInPlayMode!.metaPlaylistInDb!.getMD5Identifier() )
        }
        
        // remove cell from cells-in-playmode queue if the given playlistCell already enlisted in
        for (index, _playlistCell) in playlistCellsInPlayMode.enumerated() {
            if _playlistCell.metaPlaylistInDb!.getMD5Identifier() == _inputHash {
                playlistCellsInPlayMode.index(of: _playlistCell).map { playlistCellsInPlayMode.remove(at: $0) }
                // break loop after handling to add given cell in lines below
                break
            }
        }
        
        // add parem-given playlistCell to cells-in-playmode cache
        playlistCellsInPlayMode.append( playlistCell )
    }
    
    func handlePlaylistReloadData() {
        
        setupUICollapseAllVisibleOpenCells()
        playlistGradientLoadingBar.hide()
        tableView.reloadData()
    }
    
    func togglePlayModeIcons(
       _ playlistCell: PlaylistTableFoldingCell,
       _ active: Bool) {
        
        playlistCell.imageViewPlaylistIsPlaying.isHidden = !active
        playlistCell.state = .stopped
        if  active == true {
            playlistCell.state = .playing
        }
    }
    
    func getRatingLabel(
       _ x: CGFloat,
       _ y: CGFloat,
       _ width: CGFloat,
       _ height: CGFloat) -> UILabel {
        
        let playlistRatingLabel = UILabel()
        
        playlistRatingLabel.frame = CGRect(x, y, width, height)
        playlistRatingLabel.lineBreakMode = .byWordWrapping
        playlistRatingLabel.textColor = UIColor.white
        playlistRatingLabel.backgroundColor = UIColor(netHex: 0x12AD5E)
        playlistRatingLabel.textAlignment = .right
        playlistRatingLabel.numberOfLines = 1
        playlistRatingLabel.font = UIFont(name: "Helvetica-Neue", size: 9)
        
        return playlistRatingLabel
    }
    
    func animateFoldingCell(
       _ pDuration: TimeInterval) {
        
        UIView.animate(withDuration: pDuration, delay: 0.05, options: .curveEaseOut, animations:
            { () -> Void in
                
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
                
        },  completion: { (Bool) -> Void in })
    }
    
    func animateFoldingCellClose(
       _ pDuration: TimeInterval) {
        
        UIView.animate(withDuration: pDuration, delay: 0.00, options: .curveEaseIn, animations:
            { () -> Void in
                
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
                
        },  completion: { (Bool) -> Void in })
    }
    
    func onPlaylistChanged(
       _ playlistItem: StreamPlayList ) {
        
        if  self.debugMode == true {
            print ("dbg [delegate] : PlaylistViewControllerExt::playlistItem = [\(playlistItem.metaListInternalName)]")
        }
        
        setupUICollapseAllVisibleOpenCells()
        setupUILoadExtendedPlaylists()
        playlistChangedItem = playlistItem
    }
}
