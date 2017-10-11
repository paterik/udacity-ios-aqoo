//
//  AppDelegate.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import CoreData
import CoreStore
import Spotify
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTAudioStreamingDelegate {

    let spfSessionUserDefaultsKey = "SpotifySession"
    let spfSessionRequestSuccessNotifierId = "sessionUpdated"
    let spfSessionRequestCanceledNotifierId = "sessionFail"
    let spfSessionPlaylistLoadCompletedNotifierId = "loadPlaylistCompleted"
    let spfCachePlaylistLoadCompletedNotifierId = "loadCachePlaylistCompleted"
    let spfSecretPropertyListFile = "Keys"

    var window: UIWindow?
    var spfKeys: NSDictionary?
    var spfSession: SPTSession?
    var spfCurrentSession: SPTSession?
    var spfIsLoggedIn: Bool = false
    var spfUsername: String = ""
    var spfLoginUrl: URL?
    var spfAuth = SPTAuth()
    var coreStreamingProvider = [StreamProvider]()
    
    func _setupProviderFixtures() {
    
        print ("_setupProviderFixtures()")
        
        CoreStore.perform(
            asynchronous: { ( transaction ) -> Void in
                let provider = transaction.create(Into<StreamProvider>())
                
                provider.name = "Spotify"
                provider.tag = "_spotify"
                provider.isActive = true
                provider.details = "our primary streaming provider for aqoo"

            },
            completion: { _ in }
        )
    }
    
    func setupSystemDB () {
        
        try! CoreStore.addStorageAndWait(
            SQLiteStore(
                fileName: "aqoo.sqlite",
                configuration: "Default",
                localStorageOptions: .recreateStoreOnModelMismatch
            )
        )
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [StreamProvider]? in
                
                return transaction.fetchAll(From<StreamProvider>())
            },
            
            success: { (transactionProvider) in
                
                if  transactionProvider?.isEmpty == true {
                    print ("_ no provider found, load fixtures now ...")
                    self._setupProviderFixtures()
                }   else {
                    
                    print ("_ provider already set, using primary provider now!")
                    self.coreStreamingProvider = transactionProvider!
                }
            },
            
            failure: { (error) in
                
                print ("dbg: error while fetching streaming providers from db \(error.localizedDescription)")
            }
        )
    }
    
    func setupSystemAPI() {
    
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
    
    func setupSystemConfig() {
    
        // load api keys from special "Keys.plist" file (you have to generate one if you use this sources for your
        // own app or you want to compile this app by yourself)
        if let path = Bundle.main.path(forResource: spfSecretPropertyListFile, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) {
                
                if let spfClientId = dict["spfClientId"] as? String {
                    spfAuth.clientID = spfClientId
                    print ("_dbg: using spotify clientId => \(spfClientId)\n")
                }
                
                if let spfCallbackURL = dict["spfClientCallbackURL"] as? String {
                    spfAuth.redirectURL = URL(string: spfCallbackURL)
                    print ("_dbg: using spotify callBackURL => \(spfCallbackURL)\n")
                }
            }
        }
        
        setupSystemAPI()
    }
    
    func application(
       _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        setupSystemDB()
        setupSystemConfig()
        
        return true
    }
    
    func application(
       _ application: UIApplication,
         open url: URL,
         sourceApplication: String?,
         annotation: Any) -> Bool {
        
        if spfAuth.canHandle(url) {
            
            spfAuth.handleAuthCallback(withTriggeredAuthURL: url) {
                
                error, session in
                
                if error == nil && session != nil {
                    
                    self.spfAuth.session = session
                    
                    let userDefaults = UserDefaults.standard
                    let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                    
                    userDefaults.set(sessionData, forKey: self.spfSessionUserDefaultsKey)
                    userDefaults.synchronize()
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name.init(rawValue: self.spfSessionRequestSuccessNotifierId),
                        object: self
                    )
                    
                }   else {
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name.init(rawValue: self.spfSessionRequestCanceledNotifierId),
                        object: self
                    )
                }
            }
            
            return true
        }
        
        return false
    }
    
    func isSpotifyTokenValid() -> Bool {
        
        let userDefaults = UserDefaults.standard
        
        if  let sessionObj:AnyObject = userDefaults.object(
            forKey: spfSessionUserDefaultsKey) as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            
            if  let _firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) {
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
}

