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
    // MARK: Constants (Normal)
    //
    
    let spfInternalNoImageURL = "https://127.0.0.1/no_image"
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
    var spfEnforceSessionKill: Bool = false
    var spfUsername: String = "unknown"
    var spfUserDefaultImage: UIImage?
    var spfUserDefaultImageUrl: URL?
    var spfLoginUrl: URL?
    var spfAuth = SPTAuth()
    
    func initAPI() {
        
        // load api keys from special "Keys.plist" file (you have to generate one if you use
        // this sources for your own app or you want to compile this app by yourself!)
        if let path = Bundle.main.path(forResource: spfSecretPropertyListFile, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) {
                
                if let spfClientId = dict["spfClientId"] as? String {
                    spfAuth.clientID = spfClientId
                    if debugMode { print ("dbg [init] : using spotify clientId => \(spfClientId)") }
                }
                
                if let spfCallbackURL = dict["spfClientCallbackURL"] as? String {
                    spfAuth.redirectURL = URL(string: spfCallbackURL)
                    if debugMode { print ("dbg [init] : using spotify callBackURL => \(spfCallbackURL)") }
                }
            }
        }
        
        _initAPIContext()
    }
    
    func getUserProfileImageURLByUserName(_ userName: String, _ accessToken: String) {
        
        var _profileImageURL: URL?
        var _profileImageURLAvailable: Bool = false
 
        SPTUser.request(userName, withAccessToken: accessToken, callback: {
            
            ( error, response ) in
            
            if  let _user = response as? SPTUser {
                
                _profileImageURL = self.getUserProfileImageURLBySPTUser(_user)
                if _profileImageURL!.absoluteString != URL(string: self.spfInternalNoImageURL)!.absoluteString {
                   _profileImageURLAvailable = true
                }
                
                NotificationCenter.default.post(
                    name: NSNotification.Name.init(rawValue: self.notifier.notifyUserProfileLoadCompleted),
                    object: nil,
                    userInfo: [
                        "profileUser": _user,
                        "profileImageURL": _profileImageURL!,
                        "profileImageURLAvailable" : _profileImageURLAvailable,
                        "date": Date()
                    ]
                )
            }
        })
    }
    
    func getUserProfileImageURLBySPTUser(_ user: SPTUser) -> URL? {
        
        var _profileImageURL: URL?
        
        if  let _largestImage = user.largestImage as? SPTImage {
            if  _largestImage.size != CGSize(width: 0, height: 0) {
                _profileImageURL = _largestImage.imageURL
                
                return _profileImageURL
            }
        }
        
        if  let _smallestImage = user.smallestImage as? SPTImage {
            if  _smallestImage.size != CGSize(width: 0, height: 0) {
                _profileImageURL = _smallestImage.imageURL
                
                return _profileImageURL
            }
        }
        
        if _profileImageURL == nil {
            
            for (index, userImageAlt) in (user.images?.enumerated())! {
                if let _userImageAlt = userImageAlt as? SPTImage {
                    if _userImageAlt.imageURL != nil {
                       _profileImageURL = _userImageAlt.imageURL
                        
                        return _profileImageURL
                    }
                }
            }
        }
        
        return URL(string: spfInternalNoImageURL)
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
        let userDefaults = UserDefaults.standard
        
        SPTAuth.defaultInstance().session = nil
        spfIsLoggedIn = false
        spfCurrentSession = nil
        spfEnforceSessionKill = true
        
        for cookie: HTTPCookie in storage.cookies! {
            
            if  (cookie.domain as NSString).range(of: "spotify."  ).length > 0 ||
                (cookie.domain as NSString).range(of: "facebook." ).length > 0 {
                
                storage.deleteCookie(cookie)
            }
        }
        
        userDefaults.removeObject(forKey: spfSessionUserDefaultsKey)
        userDefaults.synchronize()
    }
    
    internal func _initAPIContext() {
        
        spfAuth.sessionUserDefaultsKey = spfSessionUserDefaultsKey
        spfAuth.requestedScopes = [
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
            SPTAuthUserReadEmailScope,
            SPTAuthStreamingScope,
            SPTAuthPlaylistReadCollaborativeScope
        ]
        
        spfLoginUrl = spfAuth.spotifyWebAuthenticationURL()
    }
}
