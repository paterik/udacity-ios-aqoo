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
    var spfLoginUrl: URL?
    var spfAuth = SPTAuth()
    
    func _setupProviderFixtures() {
        
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
                    self._setupProviderFixtures()
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
                    print ("_dbg [init]: using spotify clientId => \(spfClientId)")
                }
                
                if let spfCallbackURL = dict["spfClientCallbackURL"] as? String {
                    spfAuth.redirectURL = URL(string: spfCallbackURL)
                    print ("_dbg [init]: using spotify callBackURL => \(spfCallbackURL)\n")
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
}

