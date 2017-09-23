//
//  BaseViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import UIKit
import Spotify

class BaseViewController: UIViewController {
    
    //
    // MARK: Base Constants
    //
    
    let appDebugMode: Bool = true
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let segueIdentLandingPage  = "showLandingPage"
    let segueIdentPlayListPage = "showPlayListPage"
    
    
    //
    // MARK: Base Methods
    //
    
    func isSpotifyTokenValid() -> Bool {
        
        let userDefaults = UserDefaults.standard
        
        if  let sessionObj:AnyObject = userDefaults.object(
            forKey: appDelegate.spfSessionUserDefaultsKey) as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            
            if  let _firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) {
                if _firstTimeSession is SPTSession {
                    
                    appDelegate.spfCurrentSession = _firstTimeSession as? SPTSession
                    appDelegate.spfIsLoggedIn =  appDelegate.spfCurrentSession != nil && appDelegate.spfCurrentSession!.isValid()
                    
                    return appDelegate.spfIsLoggedIn
                    
                }
            }
        }
        
        return false
    }
    
    func closeSpotifySession() {
    
        let storage = HTTPCookieStorage.shared
        
        appDelegate.spfIsLoggedIn = false
        appDelegate.spfCurrentSession = nil
        
        SPTAuth.defaultInstance().session = nil
        
        for cookie: HTTPCookie in storage.cookies! {
            
            if  (cookie.domain as NSString).range(of: "spotify."  ).length > 0 ||
                (cookie.domain as NSString).range(of: "facebook." ).length > 0 {
                
                storage.deleteCookie(cookie)
            }
        }
    }
    
    func _handleErrorAsDialogMessage(_ errorTitle: String, _ errorMessage: String) {
        
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}
