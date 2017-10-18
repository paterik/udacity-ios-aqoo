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
    
    @IBOutlet weak var hViewCellNormalCategoryFrame: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameFirst: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameSecond: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameThird: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameFourth: UIView!
    
    @IBOutlet weak var cViewCellOpen: UIView!
    @IBOutlet weak var cViewCell: UIView!
    
    @IBOutlet weak var cViewCellNormal: RotatedView!
    @IBOutlet weak var cViewCellNormalRight: UIView!
    @IBOutlet weak var cViewCellNormalLeft: UIView!
    
    override func animationDuration(
        _ itemIndex: NSInteger,
          type:AnimationType)-> TimeInterval {

        let durations = [0.33, 0.26, 0.26]
        
        return durations[itemIndex]
    }
}
