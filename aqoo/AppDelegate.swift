//
//  AppDelegate.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import CoreData
import Spotify
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTAudioStreamingDelegate {

    let spfCallbackURL = "aqoo://"
    let spfSessionUserDefaultsKey = "SpotifySession"

    var window: UIWindow?
    var spfKeys: NSDictionary?
    var spfSession: SPTSession?
    var spfPlayer: SPTAudioStreamingController?
    var spfLoginUrl: URL?
    var spfAuth = SPTAuth()
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    func application(
       _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // load api keys from special "Keys.plist" file (you have to generate one if you use this sources for your
        // own app or you want to compile this app by yourself)
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            spfKeys = NSDictionary(contentsOfFile: path)
            if let dict = spfKeys {
                if let spfClientId = dict["spfClientId"] as? String {
                    spfAuth.clientID = spfClientId
                    
                    print ("_dbg: using spotify clientId: \(spfClientId)")
                }
            }
        }
        
        print ("_dbg: start redirect process ...")
        
        spfAuth.redirectURL = URL(string: spfCallbackURL)
        spfAuth.requestedScopes = [SPTAuthStreamingScope]
        spfAuth.sessionUserDefaultsKey = spfSessionUserDefaultsKey
        spfAuth.requestedScopes = [
            SPTAuthStreamingScope,
            SPTAuthPlaylistReadPrivateScope,
            SPTAuthPlaylistModifyPublicScope,
            SPTAuthPlaylistModifyPrivateScope
        ]
        
        spfLoginUrl = spfAuth.spotifyWebAuthenticationURL()
        
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
                    
                }   else { print (error!.localizedDescription) }
                
                let userDefaults = UserDefaults.standard
                let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                    userDefaults.set(sessionData, forKey: "SpotifySession")
                    userDefaults.synchronize()
                
                NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "sessionUpdated"), object: self)
            }
            
            return true
        }
        
        return false
    }
}

