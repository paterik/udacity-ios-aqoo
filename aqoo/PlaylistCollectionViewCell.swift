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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageViewPlaylistCover.backgroundColor = UIColor(netHex: 0xff0000)
        imageViewPlaylistCover.image = UIImage(named: "imgUITblPlaylistDefault_v1")
        
        if  imageCacheKey != nil {
            ImageCache.default.retrieveImage(forKey: "\(imageCacheKey!)", options: nil) {
                image, cacheType in
                if  let _cacheImage = image {
                    self.imageViewPlaylistCover.image = _cacheImage
                }   else {
                    self.imageViewPlaylistCover.backgroundColor = UIColor(netHex: 0xff0000)
                    self.imageViewPlaylistCover.image = UIImage(named: "imgUITblProfileDefault_v1")
                }
            }
        }
    }
}
