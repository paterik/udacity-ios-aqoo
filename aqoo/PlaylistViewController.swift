//
//  PlaylistViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Persei
import Spotify
import CoreStore
import Kingfisher
import FoldingCell
import SwiftRandom
import LetterAvatarKit
import GradientLoadingBar
import BGTableViewRowActionWithImage

class PlaylistViewController: BaseViewController,
                              UITableViewDataSource,
                              UITableViewDelegate,
                              PlaylistViewUpdateDelegate,
                              MenuViewDelegate {
    
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
    let kOpenCellDuration: Double = 0.5125
    let kCloseCellDuration: Double = 0.1275
    let kRowsCount = 9999
    let _sysCellOpeningDurations: [TimeInterval] = [0.255, 0.215, 0.225]
    let _sysCellClosingDurations: [TimeInterval] = [0.075, 0.065, 0.015]
    let _sysCacheCheckInSeconds = 3600 // 1h
    let _sysImgCacheInMb: UInt = 512
    let _sysImgCacheRevalidateInDays: UInt = 30
    let _sysImgCacheRevalidateTimeoutInSeconds: Double = 10.0
    let _sysPlaylistMetaFieldEmptyAlpha: CGFloat = 0.475
    
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
    
    var _playlistCellsInPlayMode = [PlaylistTableFoldingCell]()
    
    var _playlistChanged: Bool?
    var _playlistChangedItem: StreamPlayList?
    var _playlistGradientLoadingBar = GradientLoadingBar()
    var playListMenuBasicFilters: MenuView!
    var playListBasicFilterItems = [MenuItem]()
    
    //
    // primary used filter context including title, description, imageKey
    // and corresponding FetchChainBuilder-Call for CoreStore (lazy query)
    //
    var playlistFilterMeta = [
        
        0 : [
            "title": "Top rated playlists",
            "description": "Your playlists ordered by rating",
            "image_key": filterItem.PlaylistBestRated.rawValue,
            "query_order_by": OrderBy<StreamPlayList>.SortKey.descending(\StreamPlayList.metaListRatingOverall),
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
        
        if  segue.identifier == "showPlaylistContentViewController" {
            
            if  let playlistContentViewController = segue.destination as? PlaylistContentViewController {
                playlistContentViewController.playListInCloud = self._playlistInCloudSelected!
                playlistContentViewController.playListInDb = self._playlistInCacheSelected!
            }
        }
        
        if  segue.identifier == "showPlaylistEditViewTabController" {
            if  let editViewTabBarController = segue.destination as? PlaylistEditViewTabBarController {
                editViewTabBarController.viewControllers?.forEach {
                    if  let nvc = $0 as? UINavigationController {
                        nvc.viewControllers.forEach {
                            if  let vc = $0 as? BasePlaylistEditViewController {
                                vc.playListInDb = self._playlistInCacheSelected!
                                vc.playListInCloud = self._playlistInCloudSelected!
                                vc.playListChanged = false
                                vc.delegate = self
                            }
                        }
                    }
                }
            }
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

        let playlistCell = tableView.dequeueReusableCell(
            withIdentifier: "playListItem",
            for: indexPath) as! PlaylistTableFoldingCell
        
        let playlistCacheData = spotifyClient.playlistsInCache[indexPath.row]
       
        handlePlaylistCellMetaFields  ( playlistCell, playlistCacheData )
        handlePlaylistCellCoverImages ( playlistCell, playlistCacheData )
        handlePlaylistOwnerImageMeta  ( playlistCell, playlistCacheData )
        handlePlaylistTimeAndDateMeta ( playlistCell, playlistCacheData )
        handlePlaylistRatingBlockMeta ( playlistCell, playlistCacheData )
        
        playlistCell.durationsForExpandedState = _sysCellOpeningDurations
        playlistCell.durationsForCollapsedState = _sysCellClosingDurations
        
        // set marker for manually updated playlistItem
        playlistCell.imageViewContentChangedManually.alpha = 0.475
        playlistCell.imageViewContentChangedManually.isHidden = true
        if  playlistCacheData.metaPreviouslyUpdatedManually == true {
            playlistCell.imageViewContentChangedManually.isHidden = false
        }
        
        playlistCell.hViewPlaylistPlayModeIndicator.hidesWhenStopped = true
        playlistCell.hViewPlaylistPlayModeIndicator.tintColor = UIColor(netHex: 0x1ED760)
        playlistCell.hViewPlaylistPlayModeIndicator.state = .stopped
        
        playlistCell.hViewPlaylistPlayModeIndicatorInDetail.hidesWhenStopped = true
        playlistCell.hViewPlaylistPlayModeIndicatorInDetail.tintColor = UIColor(netHex: 0x1ED760)
        playlistCell.hViewPlaylistPlayModeIndicatorInDetail.state = .stopped
        
        togglePlayModeIcons( playlistCell, false )
        if playlistCell.metaPlaylistInDb!.currentPlayMode != 0 {
           togglePlayModeIcons( playlistCell, true )
        }
        
        return playlistCell
    }
    
    func tableView(
       _ tableView: UITableView,
         editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let playlistCell = tableView.cellForRow(at: indexPath) as! PlaylistTableFoldingCell
       
        if  playlistCell.metaPlaylistInDb == nil {
            handleErrorAsDialogMessage(
                "Error Loading Cache Playlist",
                "This local playlist [index: \(indexPath.row)] is not found in your cache api call!"
            );   return []
        }
        
        _playlistInCacheSelected = playlistCell.metaPlaylistInDb
        _playlistInCloudSelected = getCloudVersionOfDbCachedPlaylist(_playlistInCacheSelected!)
        
        playlistCell.metaPlayListInCloud = _playlistInCloudSelected
        if  playlistCell.metaPlayListInCloud == nil {
            handleErrorAsDialogMessage(
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
                
                self.performSegue(withIdentifier: "showPlaylistEditViewTabController", sender: self)
        }
        
        let tblActionHide = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: UIColor(netHex: 0x222222),
            image: UIImage(named: "icnHide_v3"),
            forCellHeight: UInt(self.kCloseCellHeight)) { (action, index) in
                
            self.handlePlaylistHiddenFlag(self._playlistInCacheSelected!)
        }
        
        let tblActionShowPlaylistContent = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: UIColor(netHex: 0x222222),
            image: UIImage(named: "icnShowPlaylist_v2"),
            forCellHeight: UInt(self.kCloseCellHeight)) { (action, index) in
                
                self.performSegue(withIdentifier: "showPlaylistContentViewController", sender: self)
        }
        
        return [ tblActionShowPlaylistContent!, tblActionEdit!, tblActionHide! ]
    }
    
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    
        guard case let cell as PlaylistTableFoldingCell = cell else { return }
        
        cell.backgroundColor = .clear
        
        if _cellHeights[indexPath.row] == kCloseCellHeight {
            cell.unfold(false, animated: false, completion: nil)
        }   else {
            cell.unfold(true, animated: false, completion: nil)
        }
    }
    
    func tableView(
       _ tableView: UITableView,
         didSelectRowAt indexPath: IndexPath) {
        
        guard case let cell as PlaylistTableFoldingCell = tableView.cellForRow(at: indexPath as IndexPath) else { return }
       
        if cell.isAnimating() { return }
        
        var duration = 0.0
        
        // is cell currently opening
        if _cellHeights[indexPath.row] == kCloseCellHeight {
           _cellHeights[indexPath.row] = kOpenCellHeight
            
            cell.metaIndexPathRow = indexPath.row
            cell.unfold(true, animated: true, completion: nil); duration = kOpenCellDuration // 0.5
            
           _playlistInCellSelected  = cell
           _playlistInCacheSelected = _playlistInCellSelected!.metaPlaylistInDb
           _playlistInCloudSelected = getCloudVersionOfDbCachedPlaylist(_playlistInCacheSelected!)
            
        }   else {
            
           _cellHeights[indexPath.row] = kCloseCellHeight
            
            cell.unfold(false, animated: true, completion: nil); duration = kCloseCellDuration // 0.8
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            tableView.beginUpdates()
            tableView.endUpdates()
        },  completion: nil)
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
    
    @IBAction func btnPlayRepeatModeAction(_ playModeControlBtn: UIButton) {

        handlePlaylistCellObjectsByTapAction( playModeControlBtn )
    }
    
    @IBAction func btnPlayShuffleModeAction(_ playModeControlBtn: UIButton) {
        
        handlePlaylistCellObjectsByTapAction( playModeControlBtn )
    }
    
    @IBAction func btnPlayNormalModeAction(_ playModeControlBtn: UIButton) {
        
        handlePlaylistCellObjectsByTapAction( playModeControlBtn )
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        _ = self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func btnShowPlaylistHidingOptionAction(_ sender: Any) {
        
        handlePlaylistHiddenFlag( _playlistInCacheSelected! )
        setupUICollapseAllVisibleOpenCells()
        tableView.reloadData()
    }
    
    @IBAction func btnShowPlaylistEditViewAction(_ sender: Any) {
        
        performSegue(withIdentifier: "showPlaylistEditViewTabController", sender: self)
    }
    
    @IBAction func btnShowPlaylistSharingAction(_ sender: Any) {
        
        let playlistShareTitle = "I'm just listening to \"\(_playlistInCacheSelected!.metaListInternalName)\" 🎧 - you can find this playlist here: \"\(_playlistInCacheSelected!.playableURI)\" (copy the URI into spotifys search)"
        
        for cell in tableView.visibleCells as! Array<PlaylistTableFoldingCell> {
            // find current opened/valid cell
            if  cell.isUnfolded &&
                cell.metaPlaylistInDb?.getMD5Identifier() == _playlistInCacheSelected?.getMD5Identifier() {
                // get first low quality image from cell cache as fallback
                var playlistShareImage = cell.imageViewPlaylistCoverRaw.image
                // retrieve primary image url (should conatin hq version of cover image)
                
                let vc = UIActivityViewController(
                    activityItems: [playlistShareTitle, playlistShareImage],
                    applicationActivities: []
                );  present(vc, animated: true)
 
                return
            }
        }
    }
    
    @IBAction func btnShowPlaylistContentAction(_ sender: Any) {
        
        performSegue(withIdentifier: "showPlaylistContentViewController", sender: self)
    }
}
