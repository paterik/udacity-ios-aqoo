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
    
    //
    // MARK: Constants (normal)
    //
    
    let _sysCacheCheckInSeconds = 99
    let _sysDefaultProviderTag = "_spotify"
    let _sysDefaultSpotifyUsername = "spotify"
    let _sysDefaultUserProfileImage = "imgUITblProfileDefault_v1"
    let _sysDefaultSpotifyUserImage = "imgUITblProfileSpotify_v1"
    let _sysDefaultCoverImage = "imgUITblPlaylistDefault_v1"
    let _sysDefaultRadioLikedCoverImage = "imgUITblPlaylistIsRadio_v1"
    let _sysDefaultStarVotedCoverImage = "imgUITblPlaylistIsStarRated_v1"
    let _sysUserProfileImageCRadiusInDeg: CGFloat = 45
    let _sysUserProfileImageSize = CGSize(width: 128, height: 128)
    let _sysPlaylistCoverImageSize = CGSize(width: 128, height: 128)
    let _sysPlaylistFilterOwnerImageSize = CGSize(width: 75, height: 75)
    let _sysPlaylistFilterColorShadow = UIColor(netHex: 0x191919)
    let _sysPlaylistFilterColorHighlight = UIColor(netHex: 0x191919)
    let _sysPlaylistFilterColorBackground = UIColor(netHex: 0x222222)
    
    let _sysImgCacheInMb: UInt = 512
    let _sysImgCacheRevalidateInDays: UInt = 30
    let _sysImgCacheRevalidateTimeoutInSeconds: Double = 10.0
    
    let _sysCellOpeningDurations: [TimeInterval] = [0.255, 0.215, 0.225]
    let _sysCellClosingDurations: [TimeInterval] = [0.075, 0.065, 0.015]
    
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
    var _playlistChanged: Bool?
    var _playlistGradientLoadingBar = GradientLoadingBar()
    var playListMenuBasicFilters: MenuView!
    var playListBasicFilterItems = [MenuItem]()
    
    // predefine filter index as 'readably' value-index and blacklist some of my filters
    // including some additional meta information about title and description (so far)
    enum filterItem: Int {
        
        case PlaylistLastUpdated = 1
        case PlaylistTitleAlphabetical = 2
        case PlaylistNumberOfTracks = 3
        case PlaylistMostListenend = 4
        case PlaylistBestRated = 5
        case PlaylistHidden = 6
        case PlaylistMostShared = 7
        case PlaylistMostFollower = 8
    }
    
    var playlistFilterMeta = [
        
        0 : [
            "title" : "Best Rated Playlists",
            "description" : "Thats your best rated playlists",
            "image_key" : filterItem.PlaylistBestRated.rawValue
        ],
        
        1 : [
            "title" : "Alphabetical Ordered Playlist",
            "description" : "Thats your playlists ordered alphabeticaly",
            "image_key" : filterItem.PlaylistTitleAlphabetical.rawValue
        ],
        
        2 : [
            "title" : "Playlists Delivering The Most Tracks",
            "description" : "Thats your playlists ordered by the most tracks",
            "image_key" : filterItem.PlaylistNumberOfTracks.rawValue
        ],
        
        3 : [
            "title" : "Playlists Mostly Listened",
            "description" : "Thats your playlists you have listened the most",
            "image_key" : filterItem.PlaylistMostListenend.rawValue
        ],
        
        4 : [
            "title" : "Your Hidden Playlists",
            "description" : "Thats your hidden playlists stack",
            "image_key" : filterItem.PlaylistHidden.rawValue
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
        
        print (playlistFilterMeta)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
   
        handlePlaylistCloudRefresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        _cacheTimer.invalidate()

        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
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

        let playlistCell = tableView.dequeueReusableCell(
            withIdentifier: "playListItem",
            for: indexPath) as! PlaylistTableFoldingCell
        
        let playlistCacheData = spotifyClient.playlistsInCache[indexPath.row]
        
        var _usedCoverImageURL: URL?
        var _noCoverImageAvailable: Bool = true
        var _noCoverOverrideImageAvailable: Bool = true
        var _noCoverSetForInternal: Bool = false
        
        playlistCell.lblPlaylistName.text = playlistCacheData.metaListInternalName
        playlistCell.metaOwnerName = playlistCacheData.owner
        playlistCell.metaPlaylistInDb = playlistCacheData
        
        if playlistCacheData.coverImagePathOverride != nil {
            _noCoverOverrideImageAvailable = false
        }
        
        if  playlistCacheData.metaPreviouslyUpdatedManually == true {
            playlistCell.imageViewContentChangedManually.isHidden = false
        }   else {
            playlistCell.imageViewContentChangedManually.isHidden = true
        }
        
        if  playlistCacheData.isMine == false {
            playlistCell.imageViewPlaylistIsMine.isHidden = true
        }   else {
            playlistCell.imageViewPlaylistIsMine.isHidden = false
        }

        if  playlistCacheData.ownerImageURL == nil || playlistCacheData.ownerImageURL == "" {
            playlistCell.imageViewPlaylistOwner.image = UIImage(named: _sysDefaultUserProfileImage)
        }   else {
            handleOwnerProfileImageCacheForCell(playlistCacheData.owner, playlistCacheData.ownerImageURL, playlistCell)
        }
        
        if  playlistCacheData.largestImageURL != nil {
            _usedCoverImageURL = URL(string: playlistCacheData.largestImageURL!)
            _noCoverImageAvailable = false
        }
        
        if  playlistCacheData.smallestImageURL != nil {
            _usedCoverImageURL = URL(string: playlistCacheData.smallestImageURL!)
            _noCoverImageAvailable = false
        }
        
        playlistCell.durationsForExpandedState = _sysCellOpeningDurations
        playlistCell.durationsForCollapsedState = _sysCellClosingDurations
        playlistCell.imageViewPlaylistCover.image = UIImage(named: _sysDefaultCoverImage)
        
        // set internal flag covers for "isRadio" playlists
        if  playlistCacheData.isPlaylistRadioSelected {
            playlistCell.imageViewPlaylistCover.image = UIImage(named: _sysDefaultRadioLikedCoverImage)
            playlistCell.imageViewPlaylistIsMine.isHidden = true
           _noCoverSetForInternal = true
        }
        
        // set internal flag covers for "isStarVoted" playlists
        if  playlistCacheData.isPlaylistVotedByStar {
            playlistCell.imageViewPlaylistCover.image = UIImage(named: _sysDefaultStarVotedCoverImage)
            playlistCell.imageViewPlaylistIsMine.isHidden = true
           _noCoverSetForInternal = true
        }
        
        if _noCoverOverrideImageAvailable == false && _noCoverSetForInternal == false {
            if let _image = getImageByFileName(playlistCacheData.coverImagePathOverride!) {
                playlistCell.imageViewPlaylistCover.image = _image
            }   else {
               _handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted image for your playlist")
            }
        }
        
        // set spotify cover image only if no cover image override available, no internalFlag found and at least one cover image are found
        if _noCoverImageAvailable == false && _noCoverOverrideImageAvailable == true && _noCoverSetForInternal == false {
            playlistCell.imageViewPlaylistCover.kf.setImage(
                with: URL(string: playlistCacheData.largestImageURL!),
                placeholder: UIImage(named: _sysDefaultCoverImage),
                options: [
                    .transition(.fade(0.2)),
                    .processor(ResizingImageProcessor(referenceSize: _sysPlaylistCoverImageSize))
                ]
            )
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
                "Error Loading Playlist Cache",
                "This local playlist [index: \(indexPath.row)] is not found in your cache api call!"
            )
            
            return []
        }
        
       _playlistInCloudSelected = getCloudVersionOfDbCachedPlaylist(_playlistInCacheSelected!)
        playlistCell.metaPlayListInCloud = _playlistInCloudSelected
        
        if playlistCell.metaPlayListInCloud == nil {
            _handleErrorAsDialogMessage(
                "Error Loading Cloud Playlist",
                "The local playlist '\(_playlistInCacheSelected!.metaListInternalName)' is not found in spotify api call!"
            )
            
            return []
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
                
                if self.debugMode == true {
                    print ("TBL_ACTION_DETECTED : Hide")
                }
        }
        
        let tblActionShowPlaylistContent = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: UIColor(netHex: 0x222222),
            image: UIImage(named: "icnShowPlaylist_v2"),
            forCellHeight: UInt(self.kCloseCellHeight)) { (action, index) in
                
                if self.debugMode == true {
                    print ("TBL_ACTION_DETECTED : ShowDetails")
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

        if isCellOpening {
            
           _cellHeights[indexPath.row] = kOpenCellHeight; duration = 0.5125
            
            animateFoldingCell(duration)
            animateFoldingCellContentOpen(duration, pCell: cell)
            
            cell.selectedAnimation(true, animated: true, completion: nil)
        }
        
        if isCellClosing {
            
           _cellHeights[indexPath.row] = kCloseCellHeight; duration = 0.1275
            
            animateFoldingCellClose(duration)
            cell.selectedAnimation(false, animated: true, completion: { () -> Void in
                self.animateFoldingCellContentClose(duration, pCell: cell)
            })
        }
    }
    
    func animateFoldingCellContentOpen(_ pDuration: TimeInterval, pCell: FoldingCell) { }
    
    func animateFoldingCellContentClose(_ pDuration: TimeInterval, pCell: FoldingCell) { }
    
    func animateFoldingCell(_ pDuration: TimeInterval) {
        
        UIView.animate(withDuration: pDuration, delay: 0.05, options: .curveEaseOut, animations:
        { () -> Void in
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            
        },  completion: { (Bool) -> Void in
            if self.debugMode == true {
                print ("_ opening cell done")
            }
        })
    }
    
    func animateFoldingCellClose(_ pDuration: TimeInterval) {
        
        UIView.animate(withDuration: pDuration, delay: 0.00, options: .curveEaseIn, animations:
        { () -> Void in
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            
        },  completion: { (Bool) -> Void in
            if self.debugMode == true {
                print ("_ closing cell done")
            }
        })
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
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        _ = self.navigationController!.popViewController(animated: true)
    }
}
