//
//  PlaylistViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import Kingfisher
import FoldingCell

class PlaylistViewController:   BaseViewController,
                                SPTAudioStreamingPlaybackDelegate,
                                SPTAudioStreamingDelegate,
                                UITableViewDataSource,
                                UITableViewDelegate {
    
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
    
    let _sysDefaultProviderTag = "_spotify"
    let _sysCacheCheckInSeconds = 99
    
    let _imgCacheInMb: UInt = 512
    let _imgCacheRevalidateInDays: UInt = 30
    let _imgCacheRevalidateTimeoutInSeconds: Double = 10.0

    //
    // MARK: Class Variables
    //
    
    var _cellHeights = [CGFloat]()
    var _defaultStreamingProvider: StreamProvider?
    var _cacheTimer: Timer!
    
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUITableView()
        setupUIEventObserver()
        setupUICacheProcessor()

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
        
        let _cellBackgroundView = UIView()
        let playlistData = spotifyClient.playlistsInCache[indexPath.row]
        let playlistCell = tableView.dequeueReusableCell(
            withIdentifier: "playListItem",
            for: indexPath) as! PlaylistTableFoldingCell

        let openingDurations: [TimeInterval] = [0.255, 0.215, 0.225]
        let closingDurations: [TimeInterval] = [0.075, 0.065, 0.015]
        
        playlistCell.lblPlaylistName.text = playlistData.name
        
        if playlistData.isMine {
            
            let triangle = BaseTriangleView(frame: CGRect(x: 10, y: 20, width: 25 , height: 30))
            triangle.backgroundColor = .red
            playlistCell.addSubview(triangle)
        }
        
        playlistCell.durationsForExpandedState = openingDurations
        playlistCell.durationsForCollapsedState = closingDurations
        playlistCell.imageViewPlaylistCover.kf.setImage(
            with: URL(string: playlistData.largestImageURL!),
            placeholder: UIImage(named: "imgUITblPlaylistDefault_v1"),
            options: [
                .transition(.fade(0.2)),
                .processor(ResizingImageProcessor(referenceSize: CGSize(width: 100, height: 100)))
            ]
        )
        
        return playlistCell
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
                print ("_ opening done")
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
                print ("_ opening done")
            }
        })
    }
    
    //
    // MARK: Class IBAction Methods
    //
    
    @IBAction func btnRefreshPlaylistAction(_ sender: Any) {
        
        handlePlaylistCloudRefresh()
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        _ = self.navigationController!.popViewController(animated: true)
    }
}
