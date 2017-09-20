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

    let spfSessionUserDefaultsKey = "SpotifySession"
    let spfSessionRequestSuccessNotifierId = "sessionUpdated"
    let spfSessionRequestCanceledNotifierId = "sessionFail"
    let spfSecretPropertyListFile = "Keys"

    var window: UIWindow?
    var spfKeys: NSDictionary?
    var spfSession: SPTSession?
    var spfCurrentSession: SPTSession?
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
        if let path = Bundle.main.path(forResource: spfSecretPropertyListFile, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) {
                
                if let spfClientId = dict["spfClientId"] as? String {
                    spfAuth.clientID = spfClientId
                    print ("_dbg: using spotify clientId: \(spfClientId)")
                }
                
                if let spfCallbackURL = dict["spfClientCallbackURL"] as? String {
                    spfAuth.redirectURL = URL(string: spfCallbackURL)
                    print ("_dbg: using spotify callBackURL: \(spfCallbackURL)")
                }
            }
        }
        
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
                    
                    let userDefaults = UserDefaults.standard
                    let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                    
                    userDefaults.set(sessionData, forKey: self.spfSessionUserDefaultsKey)
                    userDefaults.synchronize()
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name.init(rawValue: self.spfSessionRequestSuccessNotifierId),
                        object: self
                    )
                    
                }   else {
                    
                    print (error!.localizedDescription)
                    
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

