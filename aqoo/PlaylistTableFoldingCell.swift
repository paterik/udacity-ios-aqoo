//
//  PlaylistTableFoldingCell.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 15.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import FoldingCell
import Spotify

class PlaylistTableFoldingCell: FoldingCell {
    
    var metaIndexPathRow: Int?
    var metaOwnerName: String?
    var metaPlaylistInDb: StreamPlayList?
    var metaPlayListInCloud: SPTPartialPlaylist?
    var imageCacheKeyNormalView: String?
    var imageCacheKeyDetailView: String?
    
    @IBOutlet weak var imageViewPlaylistCover: UIImageView!
    @IBOutlet weak var imageViewPlaylistCoverRaw: UIImageView!
    @IBOutlet weak var imageViewPlaylistCoverInDetail: UIImageView!
    @IBOutlet weak var imageViewContentChangedManually: UIImageView!
    @IBOutlet weak var imageViewPlaylistOwner: UIImageView!
    @IBOutlet weak var imageViewPlaylistOwnerInDetail: UIImageView!
    @IBOutlet weak var imageViewPlaylistIsSpotify: UIImageView!
    @IBOutlet weak var imageViewPlaylistIsPlaying: UIImageView!
    
    @IBOutlet weak var lblPlaylistName: UILabel!
    @IBOutlet weak var lblPlaylistNameInDetail: UILabel!
    @IBOutlet weak var lblPlaylistPlaytimeInDetail: UILabel!
    
    @IBOutlet weak var lblPlaylistCreatedAt: UILabel!
    @IBOutlet weak var lblPlaylistUpdatedAt: UILabel!
    
    @IBOutlet weak var lblPlaylistMetaTrackCount: UILabel!
    @IBOutlet weak var lblPlaylistMetaFollowerCount: UILabel!
    @IBOutlet weak var lblPlaylistMetaShareCount: UILabel!
    @IBOutlet weak var lblPlaylistMetaUpdateCount: UILabel!
    @IBOutlet weak var lblPlaylistMetaPlayCount: UILabel!
    @IBOutlet weak var lblPlaylistMetaTrackCountInDetail: UILabel!
    
    @IBOutlet weak var hViewPlaylistPlayModeIndicatorInDetail: PlaylistMusicIndicatorView!
    @IBOutlet weak var hViewPlaylistPlayModeIndicator: PlaylistMusicIndicatorView!
    @IBOutlet weak var hViewCellNormalCategoryFrame: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameFirst: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameSecond: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameThird: UIView!
    @IBOutlet weak var hViewCellOpenCategoryFrameFourth: UIView!
    
    @IBOutlet weak var cViewPlaylistStatusMarker: UIImageView!
    @IBOutlet weak var cViewPlaylistIsFavoriteMarker: UIView!
    
    @IBOutlet weak var cViewPlaylistRatingIntensity: UIView!
    @IBOutlet weak var cViewPlaylistRatingEmotional: UIView!
    @IBOutlet weak var cViewPlaylistRatingDepth: UIView!
    
    @IBOutlet weak var cViewCellNormalRight: UIView!
    @IBOutlet weak var cViewCellNormalLeft: UIView!
    
    @IBOutlet weak var cViewCellCloseContentRowFirst: RotatedView!
    @IBOutlet weak var cViewCellOpenContentRowFirst: UIView!
    @IBOutlet weak var cViewCellOpenContentRowSecond: UIView!
    @IBOutlet weak var cViewCellOpenContentRowThird: RotatedView!
    @IBOutlet weak var cViewCellOpenContentRowFourth: RotatedView!
    
    @IBOutlet weak var btnPlaylistDelete: UIButton!
    @IBOutlet weak var btnPlaylistShare: UIButton!
    @IBOutlet weak var btnPlaylistEdit: UIButton!
    @IBOutlet weak var btnPlaylistShowDetail: UIButton!
    
    @IBOutlet weak var btnPlayRepeatMode: UIButton!
    @IBOutlet weak var btnPlayShuffleMode: UIButton!
    @IBOutlet weak var btnPlayNormalMode: UIButton!

    var mode: PlaylistMusicPlayMode = .playNormal {
        
        didSet {
            
            switch mode {
                
                case .playNormal:
                    
                    btnPlayNormalMode.backgroundColor = UIColor(netHex: 0x1ED761)
                    btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_1"), for: UIControlState.normal)
                    btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_0"), for: [UIControlState.selected, UIControlState.highlighted])
                    
                    break
                
                case .playShuffle:
                    
                    btnPlayShuffleMode.backgroundColor = UIColor(netHex: 0x1ED761)
                    btnPlayShuffleMode.setImage(UIImage(named : "icnSetPlayShuffle_1"), for: UIControlState.normal)
                    btnPlayShuffleMode.setImage(UIImage(named : "icnSetPlayShuffle_0"), for: [UIControlState.selected, UIControlState.highlighted])
                    
                    break
                
                case .playLoop:
                    
                    btnPlayRepeatMode.backgroundColor = UIColor(netHex: 0x1ED761)
                    btnPlayRepeatMode.setImage(UIImage(named : "icnSetPlayRepeatAll_1"), for: UIControlState.normal)
                    btnPlayRepeatMode.setImage(UIImage(named : "icnSetPlayRepeatAll_0"), for: [UIControlState.selected, UIControlState.highlighted])
                    
                    break
                
                case .clear:
                    
                    resetPlayNormalButton()
                    resetPlayLoopButton()
                    resetPlayShuffleButton()
                    
                    break
                
                default: return
            }
        }
    }
    
    func resetPlayNormalButton() {
        
        btnPlayNormalMode.backgroundColor = UIColor.clear
        btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_0"), for: UIControlState.normal)
        btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_1"), for: [UIControlState.selected, UIControlState.highlighted])
    }
    
    func resetPlayLoopButton() {
        
        btnPlayRepeatMode.backgroundColor = UIColor.clear
        btnPlayRepeatMode.setImage(UIImage(named : "icnSetPlayRepeatAll_0"), for: UIControlState.normal)
        btnPlayRepeatMode.setImage(UIImage(named : "icnSetPlayRepeatAll_1"), for: [UIControlState.selected, UIControlState.highlighted])
    }
    
    func resetPlayShuffleButton() {
        
        btnPlayShuffleMode.backgroundColor = UIColor.clear
        btnPlayShuffleMode.setImage(UIImage(named : "icnSetPlayShuffle_0"), for: UIControlState.normal)
        btnPlayShuffleMode.setImage(UIImage(named : "icnSetPlayShuffle_1"), for: [UIControlState.selected, UIControlState.highlighted])
    }
    
    var state: PlaylistMusicIndicatorViewState = .stopped {
        
        didSet {
            hViewPlaylistPlayModeIndicator.state = state
            hViewPlaylistPlayModeIndicatorInDetail.state = state
        }
    }
}
