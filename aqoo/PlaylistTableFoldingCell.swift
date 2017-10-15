//
//  PlaylistTableFoldingCell.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 15.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import FoldingCell

class PlaylistTableFoldingCell: FoldingCell {

    @IBOutlet weak var imageViewPlaylistCover: UIImageView!
    @IBOutlet weak var lblPlaylistName: UILabel!
    @IBOutlet weak var lblPlaylistPlaytime: UILabel!
    
    override func animationDuration(_ itemIndex:NSInteger, type:AnimationType)-> TimeInterval {
        
        // durations count equal it itemCount
        let durations = [0.33, 0.26, 0.26] // timing animation for each view
        
        return durations[itemIndex]
    }
}
