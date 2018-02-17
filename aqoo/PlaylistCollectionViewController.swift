//
//  PlaylistCollectionViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 17.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Kingfisher

class PlaylistCollectionViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var collectionView: UICollectionView!
    
    let coverCellIdent = "CoverCollectionCell"
    let coverCellImageCornerRadius: CGFloat = 4.0
    let _sysDefaultCoverImage = "imgUITblPlaylistDefault_v1"
    let _sysDefaultRadioLikedCoverImage = "imgUITblPlaylistIsRadio_v1"
    let _sysDefaultStarVotedCoverImage = "imgUITblPlaylistIsStarRated_v1"
    let _sysDefaultWeeklyCoverImage = "imgUITblPlaylistIsWeekly_v1"
    let _sysPlaylistCoverImageSize = CGSize(width: 128, height: 128)
    
    var _cacheTimer: Timer!
    var _usedCoverImageURL: URL?
    var _noCoverImageAvailable: Bool = true
    var _noCoverOverrideImageAvailable: Bool = true
    var _noCoverSetForInternal: Bool = false
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        setupUIBase()
    }
    
    override func willRotate(
        to toInterfaceOrientation: UIInterfaceOrientation,
        duration: TimeInterval) {
        
        collectionView!.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        _cacheTimer.invalidate()
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    //
    // MARK: Class Delegate MEthod Overloads
    //
    
    @objc func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
        
        return spotifyClient.playlistsInCache.count
    }
    
    func collectionView(
       _ collectionView: UICollectionView,
         cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let playlistItem = spotifyClient.playlistsInCache[indexPath.row]
        let playlistCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: coverCellIdent,
            for: indexPath) as! PlaylistColletionViewCell
        
        if  playlistItem.largestImageURL != nil {
            _usedCoverImageURL = URL(string: playlistItem.largestImageURL!)
            _noCoverImageAvailable = false
        }
        
        if  playlistItem.smallestImageURL != nil {
            _usedCoverImageURL = URL(string: playlistItem.smallestImageURL!)
            _noCoverImageAvailable = false
        }
        
        // set internal flag covers for "isRadio" playlists
        if  playlistItem.isPlaylistRadioSelected {
            playlistCell.imageViewPlaylistCover.image = UIImage(named: _sysDefaultRadioLikedCoverImage)
            _noCoverSetForInternal = true
        }
        
        // set internal flag covers for "isStarVoted" playlists
        if  playlistItem.isPlaylistVotedByStar {
            playlistCell.imageViewPlaylistCover.image = UIImage(named: _sysDefaultStarVotedCoverImage)
            _noCoverSetForInternal = true
        }
        
        // set internal flag covers for "isWeekly" playlists
        if  playlistItem.isPlaylistYourWeekly {
            playlistCell.imageViewPlaylistCover.image = UIImage(named: _sysDefaultWeeklyCoverImage)
            _noCoverSetForInternal = true
        }
        
        if _noCoverOverrideImageAvailable == false && _noCoverSetForInternal == false {
            if let _image = getImageByFileName(playlistItem.coverImagePathOverride!) {
                playlistCell.imageViewPlaylistCover.image = _image
            }   else {
                _handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted image for your playlist")
            }
        }
        
        if _noCoverImageAvailable == false && _noCoverOverrideImageAvailable == true && _noCoverSetForInternal == false {
            playlistCell.imageViewPlaylistCover.kf.setImage(
                with: _usedCoverImageURL,
                placeholder: UIImage(named: _sysDefaultCoverImage),
                options: [
                    .transition(.fade(0.2)),
                    .processor(ResizingImageProcessor(referenceSize: _sysPlaylistCoverImageSize))
                ]
            )
        }
        
        return playlistCell
    }
    
    func collectionView(
       _ collectionView: UICollectionView,
         didSelectItemAt indexPath: IndexPath) {
        
        print("Cell [\(indexPath.row)] selected")
    }
    
    @objc func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        var collectionCellWidth: CGFloat!
        var collectionCellHeight: CGFloat!
        var collectionCellPadding: CGFloat = 10.0
        var collectionCellSpacing: CGFloat = 12.0
        var numberOfCellInRow: CGFloat = 4.0
        
        if UIApplication.shared.statusBarOrientation != UIInterfaceOrientation.portrait {
            numberOfCellInRow = 6.0
            collectionCellPadding = 10.0
            collectionCellSpacing = 12.0
        }
        
        collectionCellWidth = (view.frame.width / numberOfCellInRow) - collectionCellPadding
        collectionCellHeight = collectionCellWidth
        
        flowLayout.itemSize = CGSize(width: collectionCellWidth, height: collectionCellHeight)
        flowLayout.minimumInteritemSpacing = collectionCellSpacing
        flowLayout.minimumLineSpacing = collectionCellSpacing
        
        return CGSize(
            width: collectionCellWidth,
            height: collectionCellHeight
        );
    }
}
