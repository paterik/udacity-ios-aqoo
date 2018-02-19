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
    
    let providerFixtureData = [
        ("Spotify", "_spotify", true, "our primary streaming provider spotify for aqoo (will be default)"),
        ("SoundCloud", "_soundcloud", false, "our soundcloud streaming provider (not implemented yet)"),
        ("MixCloud", "_mixcloud", false, "our mixcloud streaming provider (not implemented yet)"),
    ]

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
                        name: NSNotification.Name.init(rawValue: self.spotifyClient.notifier.notifySessionRequestSuccess),
                        object: self
                    )
                    
                }   else {
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name.init(rawValue: self.spotifyClient.notifier.notifySessionRequestSuccess),
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
                
                return transaction.fetchAll(
                    From<StreamProvider>().where((\StreamProvider.isActive == true))
                )
            },
            
            success: { (transactionProvider) in
                
                if  transactionProvider?.isEmpty == true {
                    self.loadProviderFixtures()
                }
            },
            
            failure: { (error) in
                
                print ("dbg [init] : error while fetching streaming providers from db \(error.localizedDescription)")
            }
        )
    }
    
    internal func loadProviderFixtures() {
        
        CoreStore.perform(
            
            asynchronous: { ( transaction ) -> Void in
                
                for (_providerName, _providerTag, _enabled, _description) in self.providerFixtureData {
                    
                    var provider = transaction.create(Into<StreamProvider>())
                    
                    provider.name = _providerName
                    provider.tag = _providerTag
                    provider.isActive = _enabled as Bool
                    provider.details = _description
                }
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): print (error)
                case .success(let userInfo): print("dbg [init] : provider fixtures loaded successfully")
                }
            }
        )
    }
}

