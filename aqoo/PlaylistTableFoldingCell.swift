//
//  PlaylistTableFoldingCell.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 15.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import FoldingCell

class PlaylistTableFoldingCell: FoldingCell {
    
    @IBOutlet weak var imageViewPlaylistCover: UIImageView!
    @IBOutlet weak var imageViewPlaylistCoverInDetail: UIImageView!
    @IBOutlet weak var imageViewPlaylistOwner: UIImageView!
    
    @IBOutlet weak var lblPlaylistName: UILabel!
    @IBOutlet weak var lblPlaylistNameInDetail: UILabel!
    @IBOutlet weak var lblPlaylistPlaytime: UILabel!
    @IBOutlet weak var lblPlaylistPlaytimeInDetail: UILabel!
    
    @IBOutlet weak var lblPlaylistCreatedAt: UILabel!
    @IBOutlet weak var lblPlaylistUpdatedAt: UILabel!
    
    @IBOutlet weak var lblPlaylistMetaFollowerCount: UILabel!
    @IBOutlet weak var lblPlaylistMetaShareCount: UILabel!
    @IBOutlet weak var lblPlaylistMetaUpdateCount: UILabel!
    @IBOutlet weak var lblPlaylistMetaTrackCount: UILabel!
    @IBOutlet weak var lblPlaylistMetaPlayCount: UILabel!
    
    @IBOutlet weak var hViewCellNormalCategoryFrame: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameFirst: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameSecond: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameThird: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameFourth: UIView!
    
    @IBOutlet weak var cViewPlaylistStatusMarker: UIImageView!
    @IBOutlet weak var cViewPlaylistIsFavoriteMarker: UIView!
    
    @IBOutlet weak var cViewCellNormalRight: UIView!
    @IBOutlet weak var cViewCellNormalLeft: UIView!
    
    @IBOutlet weak var cViewCellOpenContentRowFirst: UIView!
    @IBOutlet weak var cViewCellOpenContentRowSecond: UIView!
    @IBOutlet weak var cViewCellOpenContentRowThird: RotatedView!
    @IBOutlet weak var cViewCellOpenContentRowFourth: RotatedView!
    
    @IBOutlet weak var btnPlaylistDelete: UIButton!
    @IBOutlet weak var btnPlaylistShare: UIButton!
    @IBOutlet weak var btnPlaylistEdit: UIButton!
    @IBOutlet weak var btnPlaylistShowDetail: UIButton!
    
    @IBOutlet weak var btnPlaylistPlayNormal: UIButton!
    @IBOutlet weak var btnPlaylistPlayLoop: UIButton!
    @IBOutlet weak var btnPlaylistPlayShuffle: UIButton!
    
    @IBOutlet weak var cbxPlaylistTaggedAsFavorite: UISwitch!
    
    override func animationDuration(
        _ itemIndex: NSInteger,
          type:AnimationType)-> TimeInterval {

        // [0.33, 0.26, 0.26]
        // [0.2725, 0.2075, 0.1875]
        let durations = [0.26, 0.2, 0.2]
        
        return durations[itemIndex]
    }
}
