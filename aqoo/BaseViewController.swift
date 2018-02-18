//
//  BaseViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import Kingfisher

class BaseViewController: UIViewController {
    
    //
    // MARK: Base Constants
    //
    
    let debugMode: Bool = true
    let debugLoadFixtures: Bool = true
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let spotifyClient = SpotifyClient.sharedInstance
    let notifier = SPFEventNotifier()
    
    let segueIdentPlayListPage = "showAllUserPlaylists"
    let _sampleSong: String = "spotify:track:3rkge8kur9i26zpByFKvBu"
    let _randomStringRange: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    
    let _sysDefaultCoverImage = "imgUITblPlaylistDefault_v1"
    let _sysDefaultRadioLikedCoverImage = "imgUITblPlaylistIsRadio_v1"
    let _sysDefaultStarVotedCoverImage = "imgUITblPlaylistIsStarRated_v1"
    let _sysDefaultWeeklyCoverImage = "imgUITblPlaylistIsWeekly_v1"
    let _sysDefaultCoverOverrideImage = "imgUICoverOverrideDefault_v1"
    let _sysDefaultUserProfileImage = "imgUITblProfileDefault_v1"
    let _sysDefaultSpotifyUserImage = "imgUITblProfileSpotify_v1"
    
    let _sysPlaylistCoverImageSize = CGSize(width: 128, height: 128)
    let _sysDefaultProviderTag = "_spotify"
    let _sysDefaultSpotifyUsername = "spotify"
    let _sysDefaultAvatarFallbackURL = "https://api.adorable.io/avatars/75"
    let _sysUserProfileImageCRadiusInDeg: CGFloat = 45
    let _sysUserProfileImageSize = CGSize(width: 128, height: 128)
    let _sysPlaylistCoverDetailImageSize = CGSize(width: 255, height: 255)
    let _sysPlaylistCoverOverrideResize = CGSize(width: 512, height: 512)
    let _sysPlaylistCoverOriginInActiveAlpha: CGFloat = 0.65
    
    let metaDateTimeFormat = "dd.MM.Y hh:mm"
    
    //
    // MARK: Base Methods
    //
    
    func _handleErrorAsDialogMessage(_ errorTitle: String, _ errorMessage: String) {
        
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func getDateAsString (_ dateValue: Date, _ dateFormatter: String = "dd.MM.Y hh:mm") -> NSString {
        
        return NSDate().dateToString(Date(), dateFormatter) as! NSString
    }
    
    var getDocumentsUrl: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func getImageByFileName(_ fileName: String) -> UIImage? {
        
        let fileURL = getDocumentsUrl.appendingPathComponent(fileName)
        do {
            
            let imageData = try Data(contentsOf: fileURL)
            
            return UIImage(data: imageData)
            
        } catch {
            
            _handleErrorAsDialogMessage("IO Error (Read)", "\(error.localizedDescription)")
        }
        
        return nil
    }
    
    func getSavedImageFileName(_ image: UIImage, _ fileName: String) -> String? {
        
        let fileURL = getDocumentsUrl.appendingPathComponent(fileName)
        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
            try? imageData.write(to: fileURL, options: .atomic)
            
            return fileName
        }
        
        _handleErrorAsDialogMessage("IO Error (Write)", "unable to save image data to your device")
        
        return nil
    }
    
    func getCoverImageViewByCacheModel(
       _ playlistItem: StreamPlayList,
       _ playlistCoverImageView: UIImageView) -> UIImageView {
        
        var _usedCoverImageURL: URL?
        var _noCoverImageAvailable: Bool = true
        var _noCoverOverrideImageAvailable: Bool = true
        var _noCoverSetForInternal: Bool = false
        
        if  playlistItem.largestImageURL != nil {
            _usedCoverImageURL = URL(string: playlistItem.largestImageURL!)
            _noCoverImageAvailable = false
        }
        
        if  playlistItem.smallestImageURL != nil {
            _usedCoverImageURL = URL(string: playlistItem.smallestImageURL!)
            _noCoverImageAvailable = false
        }
        
        // set internal flag covers for "isRadio" playlists
        if  playlistItem.isPlaylistRadioSelected {
            playlistCoverImageView.image = UIImage(named: _sysDefaultRadioLikedCoverImage)
            _noCoverSetForInternal = true
        }
        
        // set internal flag covers for "isStarVoted" playlists
        if  playlistItem.isPlaylistVotedByStar {
            playlistCoverImageView.image = UIImage(named: _sysDefaultStarVotedCoverImage)
            _noCoverSetForInternal = true
        }
        
        // set internal flag covers for "isWeekly" playlists
        if  playlistItem.isPlaylistYourWeekly {
            playlistCoverImageView.image = UIImage(named: _sysDefaultWeeklyCoverImage)
            _noCoverSetForInternal = true
        }
        
        if _noCoverOverrideImageAvailable == false && _noCoverSetForInternal == false {
            if  let _image = getImageByFileName(playlistItem.coverImagePathOverride!) {
                playlistCoverImageView.image = _image
            }
        }
        
        if _noCoverImageAvailable == false && _noCoverOverrideImageAvailable == true && _noCoverSetForInternal == false {
            playlistCoverImageView.kf.setImage(
                with: _usedCoverImageURL,
                placeholder: UIImage(named: _sysDefaultCoverImage),
                options: [
                    .transition(.fade(0.2)),
                    .processor(ResizingImageProcessor(referenceSize: _sysPlaylistCoverImageSize))
                ]
            )
        }
        
        return playlistCoverImageView
    }
}
