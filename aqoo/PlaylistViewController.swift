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
    // MARK: Constants (sepcial)
    //
    
    let kCloseCellHeight: CGFloat = 90 // 90
    let kOpenCellHeight: CGFloat = 350 // 310
    let kRowsCount = 9999
    
    //
    // MARK: Constants (normal)
    //
    
    let _supportedProviderTag = "_spotify"
    let _playlistCellIdentifier = "playListItem"
    
    //
    // MARK: Class Variables
    //
    
    var _cellHeights = [CGFloat]()

    var _defaultStreamingProvider: StreamProvider?
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUITableView()
        setupUIEventObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        handlePlaylistCloudRefresh()
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
            withIdentifier: _playlistCellIdentifier,
            for: indexPath) as! PlaylistTableFoldingCell

        let durations: [TimeInterval] = [0.26, 0.2, 0.2]
        playlistCell.durationsForExpandedState = durations
        playlistCell.durationsForCollapsedState = durations
        playlistCell.lblDebugRowNumber.text = "#\(indexPath.row + 1)"
        
        // playlistCell.lblPlaylistName.text = playlistData.name
        // playlistCell.imageView?.image = spotifyClient.spfUserDefaultImage
        
        // let processor = OverlayImageProcessor(overlay: .random, fraction: 0.875)
        // cell.imageView?.kf.setImage(with: spotifyClient.spfUserDefaultImageUrl!, options: [.processor(processor)])
        
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
            
            duration = 0.50
            
           _cellHeights[indexPath.row] = kOpenCellHeight
            
            animateFoldingCell(duration)
            animateFoldingCellContentOpen(duration, pCell: cell)
            
            cell.selectedAnimation(true, animated: true, completion: nil)
            
        }
        
        if isCellClosing {
            
            duration = 0.90
            
            for (index, cell) in (tableView.visibleCells as [UITableViewCell]).enumerated()  {
                
                // var point = tableView.convert(cell.center, to: tableView.superview)
                // cell.alpha = ((point.y * 100) / tableView.bounds.maxY) / 100
                // print (cell.alpha)
                
                print ("_ cell #\(index) : \(cell)")
                
                if (index == 3) {
                    
                    // cell.backgroundColor = UIColor(netHex: 0xff0000)
                }                
            }
            
           _cellHeights[indexPath.row] = kCloseCellHeight
            
            animateFoldingCellClose(duration)
            cell.selectedAnimation(false, animated: true, completion: { () -> Void in
                self.animateFoldingCellContentClose(duration, pCell: cell)
                
            })
        }
    }
    
    func animateFoldingCellContentOpen(_ pDuration: TimeInterval, pCell: FoldingCell) { }
    func animateFoldingCellContentClose(_ pDuration: TimeInterval, pCell: FoldingCell) { }
    
    func animateFoldingCell(_ pDuration: TimeInterval) {
        
        UIView.animate(withDuration: pDuration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            self.view.layoutIfNeeded()
        },  completion: nil)
    }
    
    func animateFoldingCellClose(_ pDuration: TimeInterval) {
        
        UIView.animate(withDuration: pDuration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            self.view.layoutIfNeeded()
        },  completion: { (Bool) -> Void in
            
            print ("done")
            
        } )
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
