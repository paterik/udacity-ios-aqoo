//
//  PlaylistCollectionViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 17.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Kingfisher
import LetterAvatarKit

class PlaylistCollectionViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var collectionView: UICollectionView!
    
    //
    // MARK: Class Variables
    //
    
    let coverCellIdent = "CoverCollectionCell"
    let coverCellImageCornerRadius: CGFloat = 4.0
    
    //
    // MARK: Class Variables
    //
    
    var cacheTimer: Timer!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

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
        
        appDelegate.restrictRotation = .all
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        if  cacheTimer != nil {
            cacheTimer.invalidate()
        }
    }
    
    //
    // MARK: Class Delegate Method Overloads
    //
    
    @objc
    func collectionView(
       _ collectionView: UICollectionView,
         numberOfItemsInSection section: Int) -> Int {
        
        return spotifyClient.playlistsInCache.count
    }
    
    func collectionView(
       _ collectionView: UICollectionView,
         cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let playlistCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: coverCellIdent,
            for: indexPath) as? PlaylistColletionViewCell else {
                
            handleErrorAsDialogMessage("UI Error (Cell)", "unable to fetch cell from dequeue cache")
                
            return UICollectionViewCell()
        }
        
        // load corresponding playlistItem based on current indexPath.row of collectionViewCell
        let playlistItem = spotifyClient.playlistsInCache[indexPath.row]
        
        // set trackCount to corresponding label in cellView
        playlistCell.lblPlaylistMetaTrackCount.text = String(playlistItem.trackCount)
        
        // set default cover image using makeLetterAvatar vendor library call
        playlistCell.imageViewPlaylistCover.image = UIImage.makeLetterAvatar(withUsername: playlistItem.metaListInternalName)
        
        // set final cover image based on current playlist model and corresponding imageView
        let coverImageBlock = getCoverImageViewByCacheModel(
            playlistItem,
            playlistCell.imageViewPlaylistCover,
            playlistCell.imageViewPlaylistCover,
            nil
        )

        
        if  coverImageBlock.normalView != nil {
            playlistCell.imageCacheKey = coverImageBlock.normalViewCacheKey
            playlistCell.imageViewPlaylistCover = coverImageBlock.normalView
        }
        
        return playlistCell
    }
    
    func collectionView(
       _ collectionView: UICollectionView,
         didSelectItemAt indexPath: IndexPath) {
        
        if  debugMode {
            print("Cell [\(indexPath.row)] selected")
        }
    }
    
    @objc
    func collectionView(
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
        )
    }
}
