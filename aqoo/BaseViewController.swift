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
    
    //
    // MARK: Base Methods
    //
    
    func isSpotifyTokenValid() -> Bool {
        
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: appDelegate.spfSessionUserDefaultsKey) as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            appDelegate.spfCurrentSession = firstTimeSession
            
            return appDelegate.spfCurrentSession != nil && appDelegate.spfCurrentSession!.isValid()
        }
        
        return false
    }
    
    func _handleErrorAsDialogMessage(_ errorTitle: String, _ errorMessage: String) {
        
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}
