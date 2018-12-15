//
//  PlaylistTableFoldingCell.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 15.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import FoldingCell
import Kingfisher
import Spotify

class PlaylistTableFoldingCell: FoldingCell {
    
    //
    // MARK: Class Constants (Statics)
    //
    
    static let sharedInstance = PlaylistTableFoldingCell()
    
    //
    // MARK: Class Constants
    //
    
    let sysPlaylistMetaFieldEmptyAlpha: CGFloat = 0.475
    let sysUserProfileImageSize = CGSize(width: 128, height: 128)
    let sysUserProfileImageCRadiusInDeg: CGFloat = 45
    let sysDefaultCoverImage = "imgUITblPlaylistDefault_v1"
    let sysDefaultUserProfileImage = "imgUITblProfileDefault_v1"
    let sysBVC = BaseViewController.sharedInstance
    let dfDates = DFDates.sharedInstance
    
    //
    // MARK: Class Properties
    //
    
    var metaIndexPathRow: Int?
    var metaOwnerName: String?
    var metaPlaylistInDb: StreamPlayList?
    var metaPlayListInCloud: SPTPartialPlaylist?
    var imageCacheKeyNormalView: String?
    var imageCacheKeyDetailView: String?
    
    //
    // MARK: Class IBOutlet definitions
    //
    
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
    
    @IBOutlet weak var btnPlayNormalMode: UIButton!

    var mode: PlaylistMusicPlayMode = .playNormal {
        
        didSet {
            
            switch mode {
                
                case .playNormal:
                    
                    btnPlayNormalMode.backgroundColor = UIColor(netHex: 0x1ED761)
                    btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_1"), for: UIControlState.normal)
                    btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_0"), for: [UIControlState.selected, UIControlState.highlighted])
                    
                    break
                
                case .clear:
                    
                    resetPlayNormalButton()
                    
                    break
                
                default: return
            }
        }
    }
    
    func handlePlaylistCellCoverImages(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        // set default cover image using makeLetterAvatar vendor library call (for normal and detail cell view)
        playlistCell.imageViewPlaylistCover.image = UIImage(named: sysDefaultCoverImage)
        playlistCell.imageViewPlaylistCoverInDetail.image = UIImage(named: sysDefaultCoverImage)
        
        // set final cover image based on current playlist model and corresponding imageView
        var playlistCoverView: UIImageView! = playlistCell.imageViewPlaylistCover
        var playlistCoverRawView: UIImageView! = playlistCell.imageViewPlaylistCoverRaw
        var playlistCoverDetailView: UIImageView! = playlistCell.imageViewPlaylistCoverInDetail
        
        if  playlistItem.coverImagePathOverride != nil {
            if  let _image = sysBVC.getImageByFileName(playlistItem.coverImagePathOverride!) {
                playlistCoverView.image = _image
                playlistCoverDetailView.image = _image
            }   else {
                sysBVC.handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted cover image for your playlist")
            }
            
        }   else {
            
            var coverImageBlock = sysBVC.getCoverImageViewByCacheModel(
                playlistItem,
                playlistCoverRawView,
                playlistCoverView,
                playlistCoverDetailView
            )
            
            // set image cover in foldingCell normalView and set corresponding cacheKey
            if  coverImageBlock.normalView != nil {
                playlistCell.imageCacheKeyNormalView = coverImageBlock.normalViewCacheKey
                playlistCoverView = coverImageBlock.normalView
            }
            
            // set image cover in foldingCell detailView and set cacheKey
            if  coverImageBlock.detailView != nil {
                playlistCell.imageCacheKeyDetailView = coverImageBlock.detailViewCacheKey
                playlistCoverDetailView = coverImageBlock.detailView
            }
        }
    }
    
    func handlePlaylistCellMetaFields(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        playlistCell.metaPlaylistInDb = playlistItem
        
        // add some meta data in normalView of our playlistItemCell
        playlistCell.lblPlaylistName.text = playlistItem.metaListInternalName
        playlistCell.lblPlaylistNameInDetail.text = playlistItem.metaListInternalName
        playlistCell.lblPlaylistMetaTrackCount.text = String(playlistItem.trackCount)
        
        // add some meta data in detailView of our playlistItemCell
        playlistCell.lblPlaylistMetaTrackCountInDetail.text = playlistItem.trackCount.hrFormatted
        playlistCell.lblPlaylistMetaPlayCount.text = playlistItem.metaNumberOfPlayed.hrFormatted
        playlistCell.lblPlaylistMetaUpdateCount.text = playlistItem.metaNumberOfUpdates.hrFormatted
        playlistCell.lblPlaylistMetaShareCount.text = playlistItem.metaNumberOfShares.hrFormatted
        playlistCell.lblPlaylistMetaFollowerCount.text = playlistItem.metaNumberOfFollowers.hrFormatted
        
        playlistCell.lblPlaylistMetaFollowerCount.alpha = 1.0
        if  playlistItem.metaNumberOfFollowers == 0 {
            playlistCell.lblPlaylistMetaFollowerCount.alpha = sysPlaylistMetaFieldEmptyAlpha
        }
        
        playlistCell.lblPlaylistMetaShareCount.alpha = 1.0
        if  playlistItem.metaNumberOfShares == 0 {
            playlistCell.lblPlaylistMetaShareCount.alpha = sysPlaylistMetaFieldEmptyAlpha
        }
        
        playlistCell.lblPlaylistMetaUpdateCount.alpha = 1.0
        if  playlistItem.metaNumberOfUpdates == 0 {
            playlistCell.lblPlaylistMetaUpdateCount.alpha = sysPlaylistMetaFieldEmptyAlpha
        }
        
        playlistCell.lblPlaylistMetaPlayCount.alpha = 1.0
        if  playlistItem.metaNumberOfPlayed == 0 {
            playlistCell.lblPlaylistMetaPlayCount.alpha = sysPlaylistMetaFieldEmptyAlpha
        }
    }
    
    func handlePlaylistTimeAndDateMeta(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        playlistCell.lblPlaylistUpdatedAt.alpha = sysPlaylistMetaFieldEmptyAlpha
        playlistCell.lblPlaylistUpdatedAt.text = "not yet"
        if  let playlistUpdatedAt = playlistItem.updatedAt as? Date {
            playlistCell.lblPlaylistUpdatedAt.alpha = 1.0
            playlistCell.lblPlaylistUpdatedAt.text = dfDates.getHumanReadableDate(playlistUpdatedAt)
        }
        
        playlistCell.lblPlaylistCreatedAt.alpha = sysPlaylistMetaFieldEmptyAlpha
        playlistCell.lblPlaylistCreatedAt.text = "not yet"
        if  let playlistCreatedAt = playlistItem.createdAt as? Date {
            playlistCell.lblPlaylistCreatedAt.alpha = 1.0
            playlistCell.lblPlaylistCreatedAt.text = dfDates.getHumanReadableDate(playlistCreatedAt)
        }
        
        // metaListOverallPlaytimeInSeconds
        playlistCell.lblPlaylistPlaytimeInDetail.alpha = sysPlaylistMetaFieldEmptyAlpha
        playlistCell.lblPlaylistPlaytimeInDetail.text = "unknown"
        if  let playlistOverallPlaytime = playlistItem.metaListOverallPlaytimeInSeconds as? Int32 {
            playlistCell.lblPlaylistPlaytimeInDetail.alpha = 1.0
            playlistCell.lblPlaylistPlaytimeInDetail.text = dfDates.getSecondsAsHoursMinutesSecondsString(Int(playlistOverallPlaytime))
        }
    }
    
    func handlePlaylistRatingBlockMeta(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        let maxRatingBarWidth = Float(playlistCell.cViewPlaylistRatingIntensity.frame.width)
        let maxRatingBarHeight = Float(playlistCell.cViewPlaylistRatingIntensity.frame.height)
        let calcRatingBarWidthForArousal = (playlistItem.metaListRatingArousal * maxRatingBarWidth) / 100
        let calcRatingBarWidthForValence = (playlistItem.metaListRatingValence * maxRatingBarWidth) / 100
        let calcRatingBarWidthForDepth = (playlistItem.metaListRatingDepth * maxRatingBarWidth) / 100
        
        let cViewIcnRatingIntensity = UIImageView(image: UIImage(named: "icnRateIntensity_v1")!)
        let cViewIcnRatingEmotional = UIImageView(image: UIImage(named: "icnRateEmotional_v1")!)
        let cViewIcnRatingDepth = UIImageView(image: UIImage(named: "icnRateDepth_v1")!)
        
        cViewIcnRatingIntensity.frame = CGRect(x: 2, y: 3, width: 11, height: 11)
        cViewIcnRatingEmotional.frame = CGRect(x: 2, y: 3, width: 11, height: 11)
        cViewIcnRatingDepth.frame = CGRect(x: 2, y: 3, width: 11, height: 11)
        
        // add intensity (arousal) rating
        for subview in playlistCell.cViewPlaylistRatingIntensity.subviews {
            subview.removeFromSuperview()
        };  playlistCell.cViewPlaylistRatingIntensity.addSubview(
            getRatingLabel(0, 0, CGFloat(calcRatingBarWidthForArousal), CGFloat(maxRatingBarHeight))
        );  playlistCell.cViewPlaylistRatingIntensity.addSubview(cViewIcnRatingIntensity)
        
        // add emotional (valence) rating
        for subview in playlistCell.cViewPlaylistRatingEmotional.subviews {
            subview.removeFromSuperview()
        };  playlistCell.cViewPlaylistRatingEmotional.addSubview(
            getRatingLabel(0, 0, CGFloat(calcRatingBarWidthForValence), CGFloat(maxRatingBarHeight))
        );  playlistCell.cViewPlaylistRatingEmotional.addSubview(cViewIcnRatingEmotional)
        
        // add depth ("intellectual") rating
        for subview in playlistCell.cViewPlaylistRatingDepth.subviews {
            subview.removeFromSuperview()
        };  playlistCell.cViewPlaylistRatingDepth.addSubview(
            getRatingLabel(0, 0, CGFloat(calcRatingBarWidthForDepth), CGFloat(maxRatingBarHeight))
        );  playlistCell.cViewPlaylistRatingDepth.addSubview(cViewIcnRatingDepth)
    }
    
    func handlePlaylistOwnerImageMeta(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        playlistCell.metaOwnerName = playlistItem.owner
        
        // ignore "spotify label" for all internal playlist - otherwise activate spotify marker
        playlistCell.imageViewPlaylistIsSpotify.isHidden = false
        if  playlistItem.isSpotify == false {
            playlistCell.imageViewPlaylistIsSpotify.isHidden = true
        }
        
        playlistCell.imageViewPlaylistOwner.image = UIImage(named: sysDefaultUserProfileImage)
        if  playlistItem.ownerImageURL != nil && playlistItem.ownerImageURL != "" {
            handleOwnerProfileImageCacheForCell(playlistItem.owner, playlistItem.ownerImageURL, playlistCell)
        }
    }
    
    func handleOwnerProfileImageCacheForCell(
       _ userName: String,
       _ userProfileImageURL: String,
       _ playlistCell: PlaylistTableFoldingCell) {
        
        if  userName == sysBVC._sysDefaultSpotifyUsername {
            playlistCell.imageViewPlaylistOwner.image = UIImage(named: sysDefaultUserProfileImage)
            playlistCell.imageViewPlaylistOwnerInDetail.image = playlistCell.imageViewPlaylistOwner.image
        }   else {
            
            let _profileImageProcessor = ResizingImageProcessor(
                referenceSize: sysUserProfileImageSize)
                .append(another: RoundCornerImageProcessor(cornerRadius: sysUserProfileImageCRadiusInDeg))
                .append(another: BlackWhiteProcessor())
            
            playlistCell.imageViewPlaylistOwner.kf.setImage(
                with: URL(string: userProfileImageURL),
                placeholder: UIImage(named: sysDefaultUserProfileImage),
                options: [.transition(.fade(0.2)), .processor(_profileImageProcessor)],
                completionHandler: {
                    (image, error, cacheType, imageUrl) in
                    
                    if  image != nil {
                        playlistCell.imageViewPlaylistOwnerInDetail.image = image
                    }
                }
            )
        }
    }
    
    func handlePlaylistIncompleteData(
       _ playlistCell: PlaylistTableFoldingCell,
       _ playlistItem: StreamPlayList) {
        
        playlistCell.lblPlaylistName.alpha = 1
        playlistCell.imageViewPlaylistCover.alpha = 1
        playlistCell.imageViewPlaylistOwner.alpha = 1
        playlistCell.lblPlaylistMetaTrackCount.backgroundColor = UIColor(netHex: 0x222222)
        if  playlistCell.metaPlaylistInDb!.isIncomplete {
            playlistCell.imageViewPlaylistCover.alpha = 0.475
            playlistCell.imageViewPlaylistOwner.alpha = 0.475
            playlistCell.lblPlaylistName.alpha = 0.475
            playlistCell.lblPlaylistMetaTrackCount.backgroundColor = UIColor(netHex: 0xFC1155)
        }
    }
    
    func getRatingLabel(
       _ x: CGFloat,
       _ y: CGFloat,
       _ width: CGFloat,
       _ height: CGFloat) -> UILabel {
        
        let playlistRatingLabel = UILabel()
        
        playlistRatingLabel.frame = CGRect(x, y, width, height)
        playlistRatingLabel.lineBreakMode = .byWordWrapping
        playlistRatingLabel.textColor = UIColor.white
        playlistRatingLabel.backgroundColor = UIColor(netHex: 0x12AD5E)
        playlistRatingLabel.textAlignment = .right
        playlistRatingLabel.numberOfLines = 1
        playlistRatingLabel.font = UIFont(name: "Helvetica-Neue", size: 9)
        
        return playlistRatingLabel
    }
    
    func resetPlayNormalButton() {
        
        btnPlayNormalMode.backgroundColor = UIColor.clear
        btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_0"), for: UIControlState.normal)
        btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_1"), for: [UIControlState.selected, UIControlState.highlighted])
    }
    
    var state: PlaylistMusicIndicatorViewState = .stopped {
        
        didSet {
            hViewPlaylistPlayModeIndicator.state = state
            hViewPlaylistPlayModeIndicatorInDetail.state = state
        }
    }
}
