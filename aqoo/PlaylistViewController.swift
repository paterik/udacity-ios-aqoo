//
//  PlaylistViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import FoldingCell
import BGTableViewRowActionWithImage
import GradientLoadingBar
import LetterAvatarKit
import SwiftRandom
import Persei

class PlaylistViewController: BaseViewController,
                              UITableViewDataSource,
                              UITableViewDelegate,
                              PlaylistEditViewDetailDelegate, MenuViewDelegate {
    
    //
    // MARK: Class IBOutlet definitions
    //
    
    @IBOutlet weak var btnRefreshPlaylist: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    //
    // MARK: Constants (special)
    //
    
    let kCloseCellHeight: CGFloat = 100 // 90
    let kOpenCellHeight: CGFloat = 345 // 310
    let kRowsCount = 9999
    let _sysCellOpeningDurations: [TimeInterval] = [0.255, 0.215, 0.225]
    let _sysCellClosingDurations: [TimeInterval] = [0.075, 0.065, 0.015]
    let _sysCacheCheckInSeconds = 3600
    let _sysImgCacheInMb: UInt = 512
    let _sysImgCacheRevalidateInDays: UInt = 30
    let _sysImgCacheRevalidateTimeoutInSeconds: Double = 10.0
    
    //
    // MARK: Constants (normal)
    //
    
    let _sysPlaylistFilterOwnerImageSize = CGSize(width: 75, height: 75)
    let _sysPlaylistFilterColorShadow = UIColor(netHex: 0x191919)
    let _sysPlaylistFilterColorHighlight = UIColor(netHex: 0x191919)
    let _sysPlaylistFilterColorBackground = UIColor(netHex: 0x222222)
    
    //
    // MARK: Class Variables
    //
    
    var _cellHeights = [CGFloat]()
    var _defaultStreamingProvider: StreamProvider?
    var _cacheTimer: Timer!
    var _userProfilesHandled = [String]()
    var _userProfilesHandledWithImages = [String: String]()
    var _userProfilesInPlaylists = [String]()
    var _userProfilesInPlaylistsUnique = [String]()
    var _userProfilesCachedForFilter : Int = 0
    var _playlistInCloudSelected: SPTPartialPlaylist?
    var _playlistInCacheSelected: StreamPlayList?
    var _playlistInCellSelected: PlaylistTableFoldingCell?
    var _playlistInCellSelectedInPlayMode: PlaylistTableFoldingCell?
    var _playlistChanged: Bool?
    var _playlistChangedItem: StreamPlayList?
    var _playlistGradientLoadingBar = GradientLoadingBar()
    var playListMenuBasicFilters: MenuView!
    var playListBasicFilterItems = [MenuItem]()
    
    //
    // primary used filter context including title, description, imageKey
    // and corresponding FetchChainBuilder (query)
    //
    var playlistFilterMeta = [
        
        0 : [
            "title": "Top rated playlists",
            "description": "Your playlists ordered by rating",
            "image_key": filterItem.PlaylistBestRated.rawValue,
            "query_order_by": OrderBy<StreamPlayList>.SortKey.descending(\StreamPlayList.metaListInternalRating),
            "query_order_use_internals": true,
        ],
        
        1 : [
            "title": "Playlists in alphabetical order",
            "description": "Your playlists in alphabetical order",
            "image_key": filterItem.PlaylistTitleAlphabetical.rawValue,
            "query_order_by": OrderBy<StreamPlayList>.SortKey.ascending(\StreamPlayList.metaListInternalName),
            "query_order_use_internals": true,
        ],
        
        2 : [
            "title": "Playlists with the most tracks",
            "description": "Your playlists ordered by track count",
            "image_key": filterItem.PlaylistNumberOfTracks.rawValue,
            "query_order_by": OrderBy<StreamPlayList>.SortKey.descending(\StreamPlayList.trackCount),
            "query_order_use_internals": true,
        ],
        
        3 : [
            "title": "Playlists most frequently heard",
            "description": "Your playlists ordered by the number of times played",
            "image_key": filterItem.PlaylistMostListenend.rawValue,
            "query_order_by": OrderBy<StreamPlayList>.SortKey.descending(\StreamPlayList.metaNumberOfPlayed),
            "query_order_use_internals": true,
        ],
        
        4 : [
            "title": "Your hidden playlists",
            "description": "Your hidden playlist stack",
            "image_key": filterItem.PlaylistHidden.rawValue,
            "query_override": From<StreamPlayList>().where(\StreamPlayList.isPlaylistHidden == true),
            "query_order_use_internals": false,
        ]
    ]
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUICacheProcessor()
        setupUIEventObserver()
        setupUITableView()
        setupUITableBasicMenuView()
        
        // setupSYSConfig()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
   
        handlePlaylistCloudRefresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        if  _cacheTimer != nil {
            _cacheTimer.invalidate()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showPlaylistEditView" {
            
            let editViewController = segue.destination as! PlaylistEditViewController
                editViewController.playListInDb = _playlistInCacheSelected!
                editViewController.playListInCloud = _playlistInCloudSelected!
                editViewController.delegate = self
        }
    }
    
    //
    // MARK: Class Table Delegates
    //
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return spotifyClient.playlistsInCache.count
    }
    
    func tableView(
       _ tableView: UITableView,
         heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return _cellHeights[indexPath.row]
    }
    
    func tableView(
       _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let playlistCell = tableView.dequeueReusableCell(
            withIdentifier: "playListItem",
            for: indexPath) as? PlaylistTableFoldingCell else {
                
           _handleErrorAsDialogMessage("UI Error (Cell)", "unable to fetch cell from dequeue cache")
                
            return PlaylistTableFoldingCell()
        }
        
        let playlistCacheData = spotifyClient.playlistsInCache[indexPath.row]
        
        playlistCell.lblPlaylistName.text = playlistCacheData.metaListInternalName
        playlistCell.lblPlaylistNameInDetail.text = playlistCacheData.metaListInternalName
        playlistCell.lblPlaylistMetaTrackCount.text = String(playlistCacheData.trackCount)
        playlistCell.metaOwnerName = playlistCacheData.owner
        playlistCell.metaPlaylistInDb = playlistCacheData
        
        playlistCell.durationsForExpandedState = _sysCellOpeningDurations
        playlistCell.durationsForCollapsedState = _sysCellClosingDurations
        
        playlistCell.imageViewContentChangedManually.alpha = 0.475
        playlistCell.imageViewContentChangedManually.isHidden = true
        if  playlistCacheData.metaPreviouslyUpdatedManually == true {
            playlistCell.imageViewContentChangedManually.isHidden = false
        }
        
        // ignore "spotify label" for all internal playlist - otherwise activate spotify marker
        playlistCell.imageViewPlaylistIsSpotify.isHidden = false
        if  playlistCacheData.isSpotify == false ||
            playlistCacheData.isPlaylistVotedByStar == true ||
            playlistCacheData.isPlaylistRadioSelected == true ||
            playlistCacheData.isPlaylistYourWeekly == true {
            
            playlistCell.imageViewPlaylistIsSpotify.isHidden = true
        }

        playlistCell.imageViewPlaylistOwner.image = UIImage(named: _sysDefaultUserProfileImage)
        if  playlistCacheData.ownerImageURL != nil && playlistCacheData.ownerImageURL != "" {
            handleOwnerProfileImageCacheForCell(playlistCacheData.owner, playlistCacheData.ownerImageURL, playlistCell)
        }
        
        // set default cover image using makeLetterAvatar vendor library call (for normal and detail cell view)
        playlistCell.imageViewPlaylistCover.image = UIImage.makeLetterAvatar(withUsername: playlistCacheData.metaListInternalName)
        playlistCell.imageViewPlaylistCoverInDetail.image = playlistCell.imageViewPlaylistCover.image
        
        // set final cover image based on current playlist model and corresponding imageView
        var playlistCoverView: UIImageView! = playlistCell.imageViewPlaylistCover
        var coverImageBlock = getCoverImageViewByCacheModel( playlistCacheData, playlistCoverView)
        if  coverImageBlock.view != nil {
            
            // set image cover in foldingCell normal view and set cacheKey
            playlistCell.imageCacheKey = coverImageBlock.key
            playlistCoverView = coverImageBlock.view
            
            // set image cover in foldingCell detail view, using the same technics as used in normalView
            playlistCoverView = playlistCell.imageViewPlaylistCoverInDetail
            playlistCoverView = getCoverImageViewByCacheModel(playlistCacheData, playlistCoverView).view
        }
        
        return playlistCell
    }
    
    func tableView(
       _ tableView: UITableView,
         editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let playlistCell = tableView.cellForRow(at: indexPath) as! PlaylistTableFoldingCell
        
       _playlistInCacheSelected = playlistCell.metaPlaylistInDb
        if playlistCell.metaPlaylistInDb == nil {
            _handleErrorAsDialogMessage(
                "Error Loading Cache Playlist",
                "This local playlist [index: \(indexPath.row)] is not found in your cache api call!"
            );   return []
        }
        
       _playlistInCloudSelected = getCloudVersionOfDbCachedPlaylist(_playlistInCacheSelected!)
        playlistCell.metaPlayListInCloud = _playlistInCloudSelected
        if playlistCell.metaPlayListInCloud == nil {
            _handleErrorAsDialogMessage(
                "Error Loading Cloud Playlist",
                "The local playlist [index: \(indexPath.row)] is not found in spotify api call!"
            );   return []
        }
        
        // prevent cell row actions on open cell views (unfolded cells)
        if playlistCell.frame.height > kCloseCellHeight { return [] }
        
        let tblActionEdit = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: UIColor(netHex: 0x222222),
            image: UIImage(named: "icnSettings_v2"),
            forCellHeight: UInt(self.kCloseCellHeight)) { (action, index) in
                
                self.performSegue(withIdentifier: "showPlaylistEditView", sender: self)
        }
        
        let tblActionHide = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: UIColor(netHex: 0x222222),
            image: UIImage(named: "icnHide_v3"),
            forCellHeight: UInt(self.kCloseCellHeight)) { (action, index) in
                
            if  self.debugMode == true {
                print ("TBL_ACTION_DETECTED : Hide (not-imlemented-yet!)")
            }
        }
        
        let tblActionShowPlaylistContent = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: UIColor(netHex: 0x222222),
            image: UIImage(named: "icnShowPlaylist_v2"),
            forCellHeight: UInt(self.kCloseCellHeight)) { (action, index) in
                
            if  self.debugMode == true {
                print ("TBL_ACTION_DETECTED : ShowDetails (not-imlemented-yet!)")
            }
        }
        
        return [ tblActionShowPlaylistContent!, tblActionEdit!, tblActionHide! ]
    }
    
    func tableView(
       _ tableView: UITableView,
         didSelectRowAt indexPath: IndexPath) {
        
        guard case let cell as FoldingCell = tableView.cellForRow(at: indexPath as IndexPath) else { return }
        if cell.isAnimating() { return }
        
        let isCellOpening = _cellHeights[indexPath.row] == kCloseCellHeight
        let isCellClosing = !isCellOpening
        
        var duration = 0.0

        if  isCellOpening == true {
           _cellHeights[indexPath.row] = kOpenCellHeight; duration = 0.5125
            
            animateFoldingCell(duration)
            animateFoldingCellContentOpen(duration, pCell: cell)
            
            cell.selectedAnimation(true, animated: true, completion: nil)
        }
        
        if  isCellClosing == true {
           _cellHeights[indexPath.row] = kCloseCellHeight; duration = 0.1275
            
            animateFoldingCellClose(duration)
            cell.selectedAnimation(false, animated: true, completion: { () -> Void in
                self.animateFoldingCellContentClose(duration, pCell: cell)
            })
        }
    }
    
    func animateFoldingCellContentOpen(_ pDuration: TimeInterval, pCell: FoldingCell) {

        if  let playlistCell = pCell as? PlaylistTableFoldingCell {
           _playlistInCacheSelected = playlistCell.metaPlaylistInDb
           _playlistInCloudSelected = getCloudVersionOfDbCachedPlaylist(_playlistInCacheSelected!)
           _playlistInCellSelected = playlistCell
        }
    }
    
    func animateFoldingCellContentClose(_ pDuration: TimeInterval, pCell: FoldingCell) {
        
        if let playlistCell = pCell as? PlaylistTableFoldingCell { }
    }
    
    func animateFoldingCell(_ pDuration: TimeInterval) {
        
        UIView.animate(withDuration: pDuration, delay: 0.05, options: .curveEaseOut, animations:
        { () -> Void in
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            
        },  completion: { (Bool) -> Void in })
    }
    
    func animateFoldingCellClose(_ pDuration: TimeInterval) {
        
        UIView.animate(withDuration: pDuration, delay: 0.00, options: .curveEaseIn, animations:
        { () -> Void in
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            
        },  completion: { (Bool) -> Void in })
    }
    
    //
    // MARK: Class IBAction Methods
    //
    
    @IBAction func btnRefreshPlaylistAction(_ sender: Any) {
        
        if  self.debugMode == true {
            handlePlaylistCacheCleanUp()
        }   else {
            handlePlaylistCloudRefresh()
        }
    }
    
    @IBAction func btnPlayRepeatModeAction(_ button: UIButton) {
        
        handlePlaylistCellObjectsByTapAction( button )
        
       _playlistInCacheSelected!.inRepeatPlayMode = false
        if _playlistInCacheSelected!.currentPlayMode != playMode.PlayRepeatAll.rawValue {
           _playlistInCacheSelected!.inRepeatPlayMode = true
            setPlaylistPlayMode( _playlistInCacheSelected!, playMode.PlayRepeatAll.rawValue )
        }   else {
            setPlaylistPlayMode( _playlistInCacheSelected!, playMode.Default.rawValue )
        }
        
        togglePlayModeControls( _playlistInCacheSelected!.inRepeatPlayMode, button, "icnSetPlayRepeatAll" )
        togglePlayModeControls( false, _playlistInCellSelected!.btnPlayShuffleMode, "icnSetPlayShuffle" )
        togglePlayModeControls( false, _playlistInCellSelected!.btnPlayNormalMode, "icnSetPlayNormal" )
        
       _playlistInCellSelectedInPlayMode = _playlistInCellSelected!
    }
    
    @IBAction func btnPlayShuffleModeAction(_ button: UIButton) {
        
        handlePlaylistCellObjectsByTapAction( button )
        
       _playlistInCacheSelected!.inShufflePlayMode = false
        if _playlistInCacheSelected!.currentPlayMode != playMode.PlayShuffle.rawValue {
           _playlistInCacheSelected!.inShufflePlayMode = true
            setPlaylistPlayMode( _playlistInCacheSelected!, playMode.PlayShuffle.rawValue )
        }   else {
            setPlaylistPlayMode( _playlistInCacheSelected!, playMode.Default.rawValue )
        }
        
        togglePlayModeControls( _playlistInCacheSelected!.inShufflePlayMode, button, "icnSetPlayShuffle" )
        togglePlayModeControls( false, _playlistInCellSelected!.btnPlayRepeatMode,   "icnSetPlayRepeatAll" )
        togglePlayModeControls( false, _playlistInCellSelected!.btnPlayNormalMode,   "icnSetPlayNormal" )
        
       _playlistInCellSelectedInPlayMode = _playlistInCellSelected!
    }
    
    @IBAction func btnPlayNormalModeAction(_ button: UIButton) {

        // handle business objects behind this cell action click
        handlePlaylistCellObjectsByTapAction( button )

        // determine click state of "normal play mode" and persist state in cache (db)
       _playlistInCacheSelected!.inNormalPlayMode = false
        if _playlistInCacheSelected!.currentPlayMode != playMode.PlayNormal.rawValue {
           _playlistInCacheSelected!.inNormalPlayMode = true
            setPlaylistPlayMode( _playlistInCacheSelected!, playMode.PlayNormal.rawValue )
        }   else {
            setPlaylistPlayMode( _playlistInCacheSelected!, playMode.Default.rawValue )
        }
       
        // handle optical effects for this playmode (normal-play)
        togglePlayModeControls( _playlistInCacheSelected!.inNormalPlayMode, button, "icnSetPlayNormal" )
        togglePlayModeControls( false, _playlistInCellSelected!.btnPlayRepeatMode,  "icnSetPlayRepeatAll" )
        togglePlayModeControls( false, _playlistInCellSelected!.btnPlayShuffleMode, "icnSetPlayShuffle" )
        
        // dev/dbg issue ...
       _playlistInCellSelectedInPlayMode = _playlistInCellSelected!
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        _ = self.navigationController!.popViewController(animated: true)
    }
}
