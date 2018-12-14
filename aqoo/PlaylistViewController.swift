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
    
    @IBOutlet weak var btnLogoutFromApp: UIBarButtonItem!
    @IBOutlet weak var btnRefreshPlaylist: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    //
    // MARK: Constants (system)
    //
    
    let sysImgCacheInMb: UInt = 512
    let sysImgCacheRevalidateInDays: UInt = 30
    let sysImgCacheRevalidateTimeoutInSeconds: Double = 9.0
    let sysCloseCellHeight: CGFloat = 100
    let sysOpenCellHeight: CGFloat = 345
    let sysOpenCellDuration: Double = 0.5125
    let sysCloseCellDuration: Double = 0.1275
    let sysPreRenderRowsCount: Int = 9999
    let sysCellOpeningDurations: [TimeInterval] = [0.255, 0.215, 0.225]
    let sysCellClosingDurations: [TimeInterval] = [0.075, 0.065, 0.015]
    let sysCacheCheckInSeconds: UInt = 3600 // 3600 = 1h
    let sysPlaylistMetaFieldEmptyAlpha: CGFloat = 0.475
    let sysPlaylistFilterOwnerImageSize = CGSize(width: 75, height: 75)
    let sysPlaylistFilterShadowColor = UIColor(netHex: 0x191919)
    let sysPlaylistFilterHighlightColor = UIColor(netHex: 0x191919)
    let sysPlaylistFilterBackgroundColor = UIColor(netHex: 0x222222)
    let sysPlaylistSwipeBackgroundColor = UIColor(netHex: 0x222222)
    let sysPlaylistDefaultFilterIndex: Int = 0
    
    //
    // MARK: Class Variables
    //
    
    var cellHeights = [CGFloat]()
    var defaultStreamingProvider: StreamProvider?
    var cacheTimer: Timer!
    var userProfilesHandled = [String]()
    var userProfilesHandledWithImages = [String: String]()
    var userProfilesInPlaylists = [String]()
    var userProfilesInPlaylistsUnique = [String]()
    var userProfilesCachedForFilter : Int = 0
    
    var playlistInCloudSelected: SPTPartialPlaylist?
    var playlistInCacheSelected: StreamPlayList?
    var playlistInCellSelected: PlaylistTableFoldingCell?
    var playlistInCellSelectedInPlayMode: PlaylistTableFoldingCell?
    
    var playlistCellsInPlayMode = [PlaylistTableFoldingCell]()
    
    var playlistChanged: Bool?
    var playlistChangedItem: StreamPlayList?
    var playlistGradientLoadingBar = GradientLoadingBar()
    var playListMenuBasicFilters: MenuView!
    var playListBasicFilterItems = [MenuItem]()
    
    var playlistInCloudLastLocalUpdate: Date?
    
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
        
        setupDBSessionAuth()
        
        setupUIBase()
        setupUICacheProcessor()
        setupUIEventObserver()
        setupUITableView()
        setupUITableBasicMenuView()
        setupPlayerAuth()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
   
        handlePlaylistCloudRefresh()
        
        appDelegate.restrictRotation = .all
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        if  cacheTimer != nil {
            cacheTimer.invalidate()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if  segue.identifier == "showPlaylistContentViewController" {
            
            if  let nvc = segue.destination as? UINavigationController {
                nvc.viewControllers.forEach {
                    if  let vc = $0 as? PlaylistContentViewController {
                        vc.playListInDb = self.playlistInCacheSelected!
                        vc.playListInCloud = self.playlistInCloudSelected!
                    }
                }
            }
        }
        
        if  segue.identifier == "showPlaylistEditViewTabController" {
            
            if  let editViewTabBarController = segue.destination as? PlaylistEditViewTabBarController {
                editViewTabBarController.viewControllers?.forEach {
                    if  let nvc = $0 as? UINavigationController {
                        nvc.viewControllers.forEach {
                            if  let vc = $0 as? BasePlaylistEditViewController {
                                vc.playListInDb = self.playlistInCacheSelected!
                                vc.playListInCloud = self.playlistInCloudSelected!
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
    // MARK: Class Delegate Method Overloads
    //
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return spotifyClient.playlistsInCache.count
    }
    
    func tableView(
       _ tableView: UITableView,
         heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return cellHeights[indexPath.row]
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
        handlePlaylistTimeAndDateMeta ( playlistCell, playlistCacheData )
        handlePlaylistRatingBlockMeta ( playlistCell, playlistCacheData )
        handlePlaylistOwnerImageMeta  ( playlistCell, playlistCacheData )
        handlePlaylistIncompletData   ( playlistCell, playlistCacheData )
        
        playlistCell.durationsForExpandedState = sysCellOpeningDurations
        playlistCell.durationsForCollapsedState = sysCellClosingDurations
        
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
       
        // prevent edit actions on inclomplete playlists
        if  playlistCell.metaPlaylistInDb?.isIncomplete == true {
            return []
        }
        
        if  playlistCell.metaPlaylistInDb == nil {
            handleErrorAsDialogMessage(
                "Error Loading Cache Playlist",
                "This local playlist [index: \(indexPath.row)] is not found in your cache api call!"
            );   return []
        }
        
        playlistInCacheSelected = playlistCell.metaPlaylistInDb
        playlistInCloudSelected = getCloudVersionOfDbCachedPlaylist(playlistInCacheSelected!)
        
        playlistCell.metaPlayListInCloud = playlistInCloudSelected
        if  playlistCell.metaPlayListInCloud == nil {
            handleErrorAsDialogMessage(
                "Error Loading Cloud Playlist",
                "The local playlist [index: \(indexPath.row)] is not found in spotify api call!"
            );   return []
        }
        
        // prevent cell row actions on open cell views (unfolded cells)
        if playlistCell.frame.height > sysCloseCellHeight { return [] }
        
        let tblActionEdit = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: sysPlaylistSwipeBackgroundColor,
            image: UIImage(named: "icnSettings_v2"),
            forCellHeight: UInt(self.sysCloseCellHeight)) { (action, index) in
                
                self.performSegue(withIdentifier: "showPlaylistEditViewTabController", sender: self)
        }
        
        let tblActionHide = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: sysPlaylistSwipeBackgroundColor,
            image: UIImage(named: "icnHide_v3"),
            forCellHeight: UInt(self.sysCloseCellHeight)) { (action, index) in
                
            self.handlePlaylistHiddenFlag(self.playlistInCacheSelected!)
        }
        
        let tblActionShowPlaylistContent = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: sysPlaylistSwipeBackgroundColor,
            image: UIImage(named: "icnShowPlaylist_v2"),
            forCellHeight: UInt(self.sysCloseCellHeight)) { (action, index) in
                
                self.performSegue(withIdentifier: "showPlaylistContentViewController", sender: self)
        }
        
        return [ tblActionShowPlaylistContent!, tblActionEdit!, tblActionHide! ]
    }
    
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    
        guard case let cell as PlaylistTableFoldingCell = cell else { return }
        
        cell.backgroundColor = .clear
        
        if  cellHeights[indexPath.row] == sysCloseCellHeight {
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
        
        // is cell currently opening?
        if  cellHeights[indexPath.row] == sysCloseCellHeight {
            cellHeights[indexPath.row] = sysOpenCellHeight
            
            cell.metaIndexPathRow = indexPath.row
            cell.unfold(true, animated: true, completion: nil); duration = sysOpenCellDuration
            
            playlistInCellSelected  = cell
            playlistInCacheSelected = playlistInCellSelected!.metaPlaylistInDb
            playlistInCloudSelected = getCloudVersionOfDbCachedPlaylist(playlistInCacheSelected!)
            
        }   else {
            
            cellHeights[indexPath.row] = sysCloseCellHeight
            
            cell.unfold(false, animated: true, completion: nil); duration = sysCloseCellDuration
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            tableView.beginUpdates()
            tableView.endUpdates()
        },  completion: nil)
    }
    
    //
    // MARK: Class IBAction Methods
    //
    
    @IBAction func btnRefreshPlaylistAction(_ sender: Any) {
        
        handlePlaylistCacheCleanUp()
    }
    
    @IBAction func btnPlayNormalModeAction(_ playModeControlBtn: UIButton) {
        
        handlePlaylistCellObjectsByTapAction( playModeControlBtn )
    }
    
    @IBAction func btnShowPlaylistHidingOptionAction(_ sender: Any) {
        
        handlePlaylistHiddenFlag( playlistInCacheSelected! )
        handlePlaylistReloadData()
    }
    
    @IBAction func btnShowPlaylistEditViewAction(_ sender: Any) {
        
        performSegue(withIdentifier: "showPlaylistEditViewTabController", sender: self)
    }
    
    @IBAction func btnShowPlaylistSharingAction(_ sender: Any) {
        
        let playlistShareTitle = "I'm just listening to \"\(playlistInCacheSelected!.metaListInternalName)\" 🎧 - you can find this playlist here: \"\(playlistInCacheSelected!.playableURI)\" (copy the URI into spotifys search)"
        
        for cell in tableView.visibleCells as! Array<PlaylistTableFoldingCell> {
            // find current opened (shareable) cell
            if  cell.isUnfolded &&
                cell.metaPlaylistInDb?.getMD5Identifier() == playlistInCacheSelected?.getMD5Identifier() {
                // get first low quality image from cell cache as fallback
                var playlistShareImage = cell.imageViewPlaylistCoverRaw.image
                let vc = UIActivityViewController(
                    activityItems: [playlistShareTitle, playlistShareImage],
                    applicationActivities: []
                );  vc.completionWithItemsHandler = handleShareContentCompletion
                
                present(vc, animated: true)
                
                return
            }
        }
    }
    
    @IBAction func btnShowPlaylistContentAction(_ sender: Any) {
        
        performSegue(withIdentifier: "showPlaylistContentViewController", sender: self)
    }
    
    @IBAction func btnLogoutFromAppAction(_ sender: Any) {
        
        let logoutFromAppRequest = UIAlertController(
            title: "Logout?",
            message: "do you want to logout from current spotify session?",
            preferredStyle: UIAlertControllerStyle.alert
        )
        
        let dlgBtnYesAction = UIAlertAction(title: "Yes", style: .default) { (action: UIAlertAction!) in
            
            self.localPlayer.player?.logout()
            self.spotifyClient.closeSpotifySession()
            self.performSegue(withIdentifier: "unwindToLoginView", sender: self)
        }
        
        let dlgBtnCancelAction = UIAlertAction(title: "No", style: .default) { (action: UIAlertAction!) in
            
            return
        }
        
        logoutFromAppRequest.addAction(dlgBtnYesAction)
        logoutFromAppRequest.addAction(dlgBtnCancelAction)
        
        present(logoutFromAppRequest, animated: true, completion: nil)
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        navigationController!.popViewController(animated: true)
    }
}
