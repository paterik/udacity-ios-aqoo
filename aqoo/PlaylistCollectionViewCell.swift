//
//  PlaylistCollectionViewCell.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 17.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Kingfisher

class PlaylistColletionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageViewPlaylistCover: UIImageView!
    
    @IBOutlet var lblPlaylistName: UILabel!
    
    var imageCacheKey: String?
    var playlistName: String?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageViewPlaylistCover.backgroundColor = UIColor(netHex: 0xff0000)
        imageViewPlaylistCover.image = UIImage(named: "imgUITblProfileDefault_v1")
        
        if  imageCacheKey != nil {
            print ("CELL CACHE KEY ::: \(imageCacheKey!)")
            ImageCache.default.retrieveImage(forKey: "\(imageCacheKey!)", options: nil) {
                image, cacheType in
                if  let _cacheImage = image {
                    
                    self.imageViewPlaylistCover.image = _cacheImage
                    print ("--- Image loaded from cache: \(_cacheImage) [cacheType: \(cacheType)]")
                    print ("--- key: \(self.imageCacheKey!)")
                    print ("--- playlist: \(self.playlistName!)\n")
                    
                } else {
                    print ("--- Image not available :(")
                    print ("--- key: \(self.imageCacheKey!)")
                    print ("--- playlist: \(self.playlistName!)\n")
                    self.imageViewPlaylistCover.backgroundColor = UIColor(netHex: 0x00ff00)
                    self.imageViewPlaylistCover.image = UIImage(named: "imgUITblProfileDefault_v1")
                }
            }
            
        }   else {
            print ("--- no image key for playlist found!")
            print ("--- key : empty")
            print ("--- playlist: \(playlistName!)\n")
        }
    }
}
