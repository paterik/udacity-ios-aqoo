//
//  SpotifyClient.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import Kingfisher

class SpotifyClient: SPFClientPlaylists {
    
    //
    // MARK: Constants (Statics)
    //
    
    static let sharedInstance = SpotifyClient()
    
    //
    // MARK: Constants (Special)
    //

    let debugMode: Bool = true
    
    //
    // MARK: Constants (Normal)
    //
    
    let spfSessionUserDefaultsKey: String = "SpotifySession"
    let spfStreamingProviderDbTag: String = "_spotify"
    let spfSecretPropertyListFile = "Keys"
    
    //
    // MARK: Variables
    //
    
    var spfKeys: NSDictionary?
    var spfSession: SPTSession?
    var spfCurrentSession: SPTSession?
    var spfStreamingProvider: StreamProvider?
    var spfIsLoggedIn: Bool = false
    var spfUsername: String = "unknown"
    var spfUserDefaultImage: UIImage?
    var spfUserDefaultImageUrl: URL?
    var spfLoginUrl: URL?
    var spfAuth = SPTAuth()
    
    func initAPI() {
        
        // load api keys from special "Keys.plist" file (you have to generate one if you use this sources for your
        // own app or you want to compile this app by yourself)
        if let path = Bundle.main.path(forResource: spfSecretPropertyListFile, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) {
                
                if let spfClientId = dict["spfClientId"] as? String {
                    spfAuth.clientID = spfClientId
                    if debugMode == true { print ("dbg [init] : using spotify clientId => \(spfClientId)") }
                }
                
                if let spfCallbackURL = dict["spfClientCallbackURL"] as? String {
                    spfAuth.redirectURL = URL(string: spfCallbackURL)
                    if debugMode == true { print ("dbg [init] : using spotify callBackURL => \(spfCallbackURL)") }
                }
            }
        }
        
        _initAPIContext()
    }
    
    func getUserProfileImageURLByUserName(_ userName: String, _ accessToken: String) -> URL? {
        
        var profileImageURL: URL?
        
        SPTUser.request(userName, withAccessToken: accessToken, callback: {
            
            ( error, response ) in
            
            if  let _user = response as? SPTUser {
                profileImageURL = self.getUserProfileImageURLBySPTUser(_user)
                NotificationCenter.default.post(
                    name: NSNotification.Name.init(rawValue: self.notifier.notifyUserProfileLoadCompleted),
                    object: nil,
                    userInfo: [ "profileUser": _user, "profileImageURL": profileImageURL, "date": Date()]
                )
            }
        })
        
        return profileImageURL
    }
    
    func getUserProfileImageURLBySPTUser(_ user: SPTUser) -> URL? {
        
        var profileImageURL: URL?
        
        if  let _largestImage = user.largestImage as? SPTImage {
            if  _largestImage.size != CGSize(width: 0, height: 0) {
                profileImageURL = _largestImage.imageURL
                if debugMode == true { print ("found largestImage value for user [\(user.canonicalUserName!)]") }
                
                return profileImageURL
            }
        }
        
        if  let _smallestImage = user.smallestImage as? SPTImage {
            if  _smallestImage.size != CGSize(width: 0, height: 0) {
                profileImageURL = _smallestImage.imageURL
                if debugMode == true { print ("found smallestImage value for user [\(user.canonicalUserName!)]") }
                
                return profileImageURL
            }
        }
        
        if  profileImageURL == nil {
            
            for (index, userImageAlt) in user.images.enumerated() {
                if let _userImageAlt = userImageAlt as? SPTImage {
                    if _userImageAlt.imageURL != nil {
                        profileImageURL = _userImageAlt.imageURL
                        if debugMode == true { print ("found image url value for user [\(user.canonicalUserName!)]") }
                        
                        return profileImageURL
                    }
                }
            }
        }
        
        return profileImageURL
    }
    
    func getUserProfileImageByUserName (
        _ userName: String,
        _ accessToken: String) -> String? {

        if userName == nil { return nil }
        
        let kingFisherCacheId: String = "\(userName)"
        
        ImageCache.default.retrieveImage(forKey: kingFisherCacheId, options: nil) {
            
            image, cacheType in
            
            if let _image = image {
                
                print("image for user (key) \(kingFisherCacheId), cacheType: \(cacheType) already exist!")

            } else {
                
                print("image for user (key) \(kingFisherCacheId), doesn't exist - downloading now")
                
                SPTUser.request(userName, withAccessToken: accessToken, callback: {
                    
                    ( error, response ) in
                    
                    if  let _user = response as? SPTUser {
                        if let _userProfileImageURL = self.getUserProfileImageURLBySPTUser(_user) as? URL {
       
                            ImageDownloader.default.downloadImage(with: _userProfileImageURL, options: [], progressBlock: nil) {
                                
                                (image, error, url, data) in
                                
                                ImageCache.default.store( image!, forKey: "\(kingFisherCacheId)", toDisk: true)
                            }
                        }
                    }
                })
            }
        }
        
        return "\(kingFisherCacheId)"
    }
    
    func getDefaultPlaylistImageByUserPhoto(_ session: SPTSession) {
        
        if debugMode == true {
            print ("dbg [session] : fetch current user image using corresponding api call")
        }
        
        spfUserDefaultImage = UIImage(named: "imgUITblPlaylistDefault_v1")
        
        SPTUser.requestCurrentUser(withAccessToken: session.accessToken, callback: {
            
            ( error, response ) in
            
            if  let _currentUser = response as? SPTUser {
                
                ImageDownloader.default.downloadImage(with: _currentUser.largestImage.imageURL, options: [], progressBlock: nil) {
                    
                    (image, error, url, data) in
                    
                    ImageCache.default.store( image!, forKey: _currentUser.canonicalUserName, toDisk: true)
                    self.spfUserDefaultImage = image!
                    self.spfUserDefaultImageUrl = url!
                    
                    if self.debugMode == true {
                        print ("dbg [session] : imageUrl of currentUser is \(url!.absoluteString)")
                    }
                }
            }
        })
    }
    
    func isSpotifyTokenValid() -> Bool {
        
        let userDefaults = UserDefaults.standard
        
        if  let sessionObj:AnyObject = userDefaults.object(
            forKey: spfSessionUserDefaultsKey) as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            
            if let _firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) {
                if _firstTimeSession is SPTSession {
                    
                    spfCurrentSession = _firstTimeSession as? SPTSession
                    spfIsLoggedIn = spfCurrentSession != nil && spfCurrentSession!.isValid()
                    spfUsername = (spfCurrentSession?.canonicalUsername)!
                    
                    return spfIsLoggedIn
                }
            }
        }
        
        return false
    }
    
    func closeSpotifySession() {
        
        let storage = HTTPCookieStorage.shared
        
        SPTAuth.defaultInstance().session = nil
        spfIsLoggedIn = false
        spfCurrentSession = nil
        
        for cookie: HTTPCookie in storage.cookies! {
            
            if  (cookie.domain as NSString).range(of: "spotify."  ).length > 0 ||
                (cookie.domain as NSString).range(of: "facebook." ).length > 0 {
                
                storage.deleteCookie(cookie)
            }
        }
    }
    
    internal func _initAPIContext() {
        
        spfAuth.sessionUserDefaultsKey = spfSessionUserDefaultsKey
        spfAuth.requestedScopes = [
            SPTAuthStreamingScope,
            SPTAuthPlaylistReadPrivateScope,
            SPTAuthPlaylistReadCollaborativeScope,
            SPTAuthPlaylistModifyPublicScope,
            SPTAuthPlaylistModifyPrivateScope,
            SPTAuthUserFollowModifyScope,
            SPTAuthUserFollowReadScope,
            SPTAuthUserLibraryReadScope,
            SPTAuthUserLibraryModifyScope,
            SPTAuthUserReadPrivateScope,
            SPTAuthUserReadTopScope,
            SPTAuthUserReadEmailScope
        ]
        
        spfLoginUrl = spfAuth.spotifyWebAuthenticationURL()
    }
}
