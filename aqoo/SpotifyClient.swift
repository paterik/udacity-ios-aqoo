//
//  SpotifyClient.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import Spotify
import UIKit

class SpotifyClient: NSObject {
    
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
    var spfLoginUrl: URL?
    var spfAuth = SPTAuth()
    
    func initAPI() {
        
        // load api keys from special "Keys.plist" file (you have to generate one if you use this sources for your
        // own app or you want to compile this app by yourself)
        if let path = Bundle.main.path(forResource: spfSecretPropertyListFile, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) {
                
                if let spfClientId = dict["spfClientId"] as? String {
                    spfAuth.clientID = spfClientId
                    if debugMode == true { print ("_dbg [init]: using spotify clientId => \(spfClientId)") }
                }
                
                if let spfCallbackURL = dict["spfClientCallbackURL"] as? String {
                    spfAuth.redirectURL = URL(string: spfCallbackURL)
                    if debugMode == true { print ("_dbg [init]: using spotify callBackURL => \(spfCallbackURL)\n") }
                }
            }
        }
        
        _initAPIContext()
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
        
        spfIsLoggedIn = false
        spfCurrentSession = nil
        
        SPTAuth.defaultInstance().session = nil
        
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
