//
//  PlaylistCollectionViewCell.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 17.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

class PlaylistColletionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageViewPlaylistCover: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageViewPlaylistCover.backgroundColor = UIColor(netHex: 0xff0000)
        imageViewPlaylistCover.image = UIImage(named: "imgUITblProfileDefault_v1")
    }
}
