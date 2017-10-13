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

    let spotifyClient = SpotifyClient.sharedInstance
    
    let spfSessionRequestSuccessNotifierId = "sessionUpdated"
    let spfSessionRequestCanceledNotifierId = "sessionFail"
    let spfSessionPlaylistLoadCompletedNotifierId = "loadPlaylistCompleted"
    let spfCachePlaylistLoadCompletedNotifierId = "loadCachePlaylistCompleted"

    var window: UIWindow?
    
    func application(
       _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // init our database
        initSystemDB()
        // init our provider collection
        initProviderCollection()
        // init our default streaming provider API (spotify)
        spotifyClient.initAPI()
        
        return true
    }
    
    func application(
       _ application: UIApplication,
         open url: URL,
         sourceApplication: String?,
         annotation: Any) -> Bool {
        
        if  spotifyClient.spfAuth.canHandle(url) {
            spotifyClient.spfAuth.handleAuthCallback(withTriggeredAuthURL: url) {
                
                error, session in
                
                if error == nil && session != nil {
                    
                    self.spotifyClient.spfAuth.session = session
                    
                    let userDefaults = UserDefaults.standard
                    let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                    
                    userDefaults.set(sessionData, forKey: self.spotifyClient.spfSessionUserDefaultsKey)
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
    
    func initSystemDB () {
        
        try! CoreStore.addStorageAndWait(
            
            SQLiteStore(
                fileName: "aqoo.sqlite",
                configuration: "Default",
                localStorageOptions: .recreateStoreOnModelMismatch
            )
        )
    }
    
    func initProviderCollection() {
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [StreamProvider]? in
                
                return transaction.fetchAll(From<StreamProvider>())
            },
            
            success: { (transactionProvider) in
                
                if  transactionProvider?.isEmpty == true {
                    self.loadProviderFixtures()
                }
            },
            
            failure: { (error) in
                
                print ("dbg: error while fetching streaming providers from db \(error.localizedDescription)")
            }
        )
    }
    
    internal func loadProviderFixtures() {
        
        CoreStore.perform(
            
            asynchronous: { ( transaction ) -> Void in
                let provider = transaction.create(Into<StreamProvider>())
                
                provider.name = "Spotify"
                provider.tag = "_spotify"
                provider.isActive = true
                provider.details = "our primary streaming provider for aqoo (will be default)"
                
            },
            
            completion: { _ in }
        )
    }
}

