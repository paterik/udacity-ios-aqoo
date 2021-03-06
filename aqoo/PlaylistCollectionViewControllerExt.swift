//
//  PlaylistCollectionViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 17.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

extension PlaylistCollectionViewController {
 
    func setupUIBase() {
     
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    func refreshCollectionView() {
        
        if isDataAvailable() {
            collectionView?.reloadData()
        }
    }
    
    func isDataAvailable() -> Bool {
        
        return spotifyClient.playlistsInCache.count > 0
    }
}
