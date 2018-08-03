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
    let debugKFCMode: Bool = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let spotifyClient = SpotifyClient.sharedInstance
    let notifier = SPFEventNotifier()
    
    let _defaultLandingPageSegueId = "showAllUserPlaylists"
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
    
    let _sysPlaylistCacheRefreshEnforce: DateComponents = 3.minutes
    
    let metaDateTimeFormat = "dd.MM.Y hh:mm"
    
    //
    // all predefined filter indices as 'readably' value
    //
    enum filterItem: Int {
        
        case PlaylistLastUpdated = 1
        case PlaylistTitleAlphabetical = 2
        case PlaylistNumberOfTracks = 3
        case PlaylistMostListenend = 4
        case PlaylistBestRated = 5
        case PlaylistHidden = 6
        case PlaylistMostShared = 7
        case PlaylistMostFollower = 8
    }
    
    //
    // this weight presets will be used for order internal playlist order
    //
    enum filterInternalWeight: Int32 {
        
        case PlaylistYourWeekly = 9999
        case PlaylistRadioLiked = 9998
        case PlaylistStarRated = 9997
        case Default = 0
    }
    
    //
    // our available playmodes for (cell) items in playlist. This
    // enum values will also stand for corresponding button tags!
    //
    enum playMode: Int16 {
        
        case Default = 0
        case PlayNormal = 1
        case PlayShuffle = 2
        case PlayRepeatAll = 3
    }
    
    //
    // MARK: Base Methods
    //
    
    func getPlayModeAsString(_ playModeValue : Int16) -> String {
        
        switch playModeValue {
            case playMode.Default.rawValue:
                return "Stop"
            
            case playMode.PlayNormal.rawValue:
                return "Normal"
            
            case playMode.PlayShuffle.rawValue:
                return "Shuffle"
            
            case playMode.PlayRepeatAll.rawValue:
                return "Loop"
            
            default:
                return "unknown"
        }
        
        return ""
    }
    
    func handleErrorAsDialogMessage(_ errorTitle: String, _ errorMessage: String) {
        
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
            
        }   catch {
            
            handleErrorAsDialogMessage("IO Error (Read)", "\(error.localizedDescription)")
        }
        
        return nil
    }
    
    func getSavedImageFileName(_ image: UIImage, _ fileName: String) -> String? {
        
        let fileURL = getDocumentsUrl.appendingPathComponent(fileName)
        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
            try? imageData.write(to: fileURL, options: .atomic)
            
            return fileName
        }
        
        handleErrorAsDialogMessage("IO Error (Write)", "unable to save image data to your device")
        
        return nil
    }
    
    func getInternalCoverImageNameByCacheModel(
       _ playlistItem: StreamPlayList) -> String? {
        
        // set internal flag covers for "isRadio" playlists
        if  playlistItem.isPlaylistRadioSelected {
            return _sysDefaultRadioLikedCoverImage
        }
        
        // set internal flag covers for "isStarVoted" playlists
        if  playlistItem.isPlaylistVotedByStar {
            return _sysDefaultStarVotedCoverImage
        }
        
        // set internal flag covers for "isWeekly" playlists
        if  playlistItem.isPlaylistYourWeekly {
            return _sysDefaultWeeklyCoverImage
        }
        
        return nil
    }
    
    func getCoverImageViewByCacheModel(
       _ playlistItem: StreamPlayList,
       _ playlistCoverImageRawView: UIImageView,
       _ playlistCoverImageNormalView: UIImageView,
       _ playlistCoverImageDetailView: UIImageView?)
        -> (rawView: UIImageView,
            normalView: UIImageView,
            detailView: UIImageView?,
            rawViewCacheKey: String?,
            normalViewCacheKey: String?,
            detailViewCacheKey: String?,
            imageDownloadURL: URL?) {
        
        var _usedCoverImageURL: URL?
        var _usedNormalCoverImageCacheKey: String?
        var _usedDetailCoverImageCacheKey: String?
        var _usedRawCoverImageCacheKey: String?
        var _noCoverImageAvailable: Bool = true
        var _noCoverOverrideImageAvailable: Bool = true
        var _noCoverSetForInternal: Bool = false
        
        // try to bound cover image using largestImageURL
        if  playlistItem.largestImageURL != nil {
            _usedCoverImageURL = URL(string: playlistItem.largestImageURL!)
            _noCoverImageAvailable = false
            if self.debugKFCMode == true {
                print ("--- use large cover for [\(playlistItem.metaListInternalName)]")
            }
        }
        
        // no large image found? try smallestImageURL instead
        if  playlistItem.smallestImageURL != nil && _noCoverImageAvailable == true {
            _usedCoverImageURL = URL(string: playlistItem.smallestImageURL!)
            _noCoverImageAvailable = false
            if self.debugKFCMode == true {
                print ("--- use small cover for [\(playlistItem.metaListInternalName)]")
            }
        }
        
        // check playlist item is part of internal playlist selection - take internal cover on match
        if  let _imageName = getInternalCoverImageNameByCacheModel(playlistItem) {
            playlistCoverImageNormalView.image = UIImage(named: _imageName)
            _noCoverSetForInternal = true
            if self.debugKFCMode == true {
                print ("--- use internal cover for [\(playlistItem.metaListInternalName)]")
            }
        }
        
        // set user selected images for covers if available (on non-internal playlist only)
        if _noCoverOverrideImageAvailable == false && _noCoverSetForInternal == false {
            if  let _image = getImageByFileName(playlistItem.coverImagePathOverride!) {
                playlistCoverImageNormalView.image = _image
                if self.debugKFCMode == true {
                    print ("--- use cover override for [\(playlistItem.metaListInternalName)]")
                }
            }
        }
        
        // call kingfisher majic and place coverImage using kf-methods (including cache loading) for playlistCover images
        if _noCoverImageAvailable == false &&
           _noCoverOverrideImageAvailable == true &&
           _noCoverSetForInternal == false {
            
           _usedRawCoverImageCacheKey    = String(format: "c0::%@", _usedCoverImageURL!.absoluteString).md5()
           _usedNormalCoverImageCacheKey = String(format: "c1::%@", _usedCoverImageURL!.absoluteString).md5()
           _usedDetailCoverImageCacheKey = String(format: "c2::%@", _usedCoverImageURL!.absoluteString).md5()
            
            // raw cover image handler (used for sharing and editView)
            handleCoverImageByCache(
                playlistCoverImageRawView,
               _usedCoverImageURL!,
               _usedRawCoverImageCacheKey!,
               []
            )
            
            // normal cell view cover image handler
            handleCoverImageByCache(
                playlistCoverImageNormalView,
               _usedCoverImageURL!,
               _usedNormalCoverImageCacheKey!,
                [
                    .transition(.fade(0.1875)),
                    .processor(ResizingImageProcessor(referenceSize: _sysPlaylistCoverImageSize))
                ]
            )
            
            // detail cell view cover image handler
            if  playlistCoverImageDetailView != nil {
                handleCoverImageByCache(
                    playlistCoverImageDetailView!,
                   _usedCoverImageURL!,
                   _usedDetailCoverImageCacheKey!,
                    [
                        .processor(ResizingImageProcessor(referenceSize: _sysPlaylistCoverDetailImageSize))
                    ]
                )
            }
        }
        
        return (
            rawView: playlistCoverImageRawView,
            normalView: playlistCoverImageNormalView,
            detailView: playlistCoverImageDetailView,
            rawViewCacheKey: _usedRawCoverImageCacheKey,
            normalViewCacheKey: _usedNormalCoverImageCacheKey,
            detailViewCacheKey: _usedDetailCoverImageCacheKey,
            imageDownloadURL: _usedCoverImageURL
        )
    }
    
    func getSecondsAsHoursMinutesSeconds (_ seconds : Int) -> (Int, Int, Int) {
        
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func getSecondsAsHoursMinutesSecondsString (_ seconds : Int) -> String {
        
        let (h, m, s) = getSecondsAsHoursMinutesSeconds ( seconds )
        
        return "\(h) hours, \(m) min, \(s) sec"
    }
    
    func getSecondsAsHoursMinutesSecondsDigits (_ seconds : Int) -> String {
        
        let (h, m, s) = getSecondsAsHoursMinutesSeconds ( seconds )
        
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    func getSecondsAsMinutesSecondsDigits (_ seconds : Int) -> String {
        
        let (h, m, s) = getSecondsAsHoursMinutesSeconds ( seconds )
        
        return String(format: "%02d:%02d", m, s)
    }
    
    func getHumanReadableDate(_ date : Date) -> String {
        
        var secondsAgo = Int(Date().timeIntervalSince(date))
        if  secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        if  secondsAgo < minute  {
            
            if  secondsAgo < 2 {
                return "just now"
            }   else {
                return "\(secondsAgo) secs ago"
            }
            
        }   else if secondsAgo < hour {
            
            let min = (secondsAgo / minute)
            if  min == 1 {
                return "\(min) min ago"
            }   else {
                return "\(min) mins ago"
            }
            
        }   else if secondsAgo < day {
            
            let hr = (secondsAgo / hour)
            if  hr == 1 {
                return "\(hr) hr ago"
            }   else {
                return "\(hr) hrs ago"
            }
            
        }   else if secondsAgo < week {
            
            let day = (secondsAgo / day)
            if  day == 1 {
                return "\(day) day ago"
            }   else {
                return "\(day) days ago"
            }
            
        }   else {
            
            let formatter = DateFormatter()
                formatter.dateFormat = "MMM dd, hh:mm a"
                formatter.locale = Locale(identifier: "en_US")
            
            let strDate: String = formatter.string(from: date)
            
            return strDate
        }
    }
    
    func getRandomNumber(between lower: Int, and upper: Int) -> Int {
        
        return Int(arc4random_uniform(UInt32(upper - lower))) + lower
    }
    
    func getRandomUniqueNumberArray(forLowerBound lower: Int, andUpperBound upper:Int, andNumNumbers iterations: Int) -> [Int] {
        
        guard iterations <= (upper - lower) else { return [] }
        
        var numbers: Set<Int> = Set<Int>()
        
        (0..<iterations).forEach { _ in
            let beforeCount = numbers.count
            repeat {
                numbers.insert(getRandomNumber(between: lower, and: upper))
            }   while numbers.count == beforeCount
        }
        
        return numbers.map{ $0 }
    }
    
    func handleCoverImageByCache(
       _ coverImageView: UIImageView,
       _ coverImageURL: URL,
       _ coverCacheKey: String,
       _ coverOptions: KingfisherOptionsInfo? = nil) {
        
        ImageCache.default.retrieveImage(forKey: "\(coverCacheKey)", options: nil) {
            
            image, cacheType in
            
            // cover image already cached?
            if  let _cacheImage = image {
                
                coverImageView.image = _cacheImage
                if  self.debugKFCMode == true {
                    print("--- KFC :: image loaded from cache: \(_cacheImage) [cacheType: \(cacheType)]")
                    print("--- KFC :: image_key = [\(coverCacheKey)]")
                }
                
            // no cached version for cover image found? retrieve coverImage now ...
            }   else {
                coverImageView.kf.setImage(
                    with: coverImageURL,
                    placeholder: UIImage(named: self._sysDefaultCoverImage),
                    options: coverOptions,
                    completionHandler: {
                        (image, error, cacheType, imageUrl) in
                        
                        if  image != nil {
                            ImageCache.default.store(image!, forKey: coverCacheKey)
                        }
                        
                        if error != nil && self.debugKFCMode == true {
                        
                            print ("--- KFC :: ERROR unable to fetch image and transfer data into local cache!")
                            print ("\(coverImageURL)")
                        }
                    }
                )
                
                if  self.debugKFCMode == true {
                    print("\n--- KFC :: image doesn't exist in cache, corresponding cache entry was created")
                    print("--- KFC :: image_key = [\(coverCacheKey)]")
                }
            }
        }
    }
}
