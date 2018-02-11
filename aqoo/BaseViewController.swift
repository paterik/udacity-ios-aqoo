//
//  BaseViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class BaseViewController: UIViewController {
    
    //
    // MARK: Base Constants
    //
    
    let debugMode: Bool = true
    let debugLoadFixtures: Bool = true
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let spotifyClient = SpotifyClient.sharedInstance
    let notifier = SPFEventNotifier()
    
    let segueIdentPlayListPage = "showAllUserPlaylists"
    
    let _sampleSong: String = "spotify:track:3rkge8kur9i26zpByFKvBu"
    
    let _randomStringRange: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    
    let metaDateTimeFormat = "dd.MM.Y hh:mm"
    
    //
    // MARK: Base Methods
    //
    
    func _handleErrorAsDialogMessage(_ errorTitle: String, _ errorMessage: String) {
        
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func getDateAsString (_ dateValue: Date, _ dateFormatter: String = "dd.MM.Y hh:mm") -> NSString {
        
        return NSDate().dateToString(Date(), dateFormatter) as! NSString
    }
    
    var getDocumentsUrl: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func getImageByFileName(_ fileName: String) -> UIImage? {
        
        let fileURL = getDocumentsUrl.appendingPathComponent(fileName)
        do {
            
            let imageData = try Data(contentsOf: fileURL)
            
            return UIImage(data: imageData)
            
        } catch {
            
            _handleErrorAsDialogMessage("IO Error (Read)", "\(error.localizedDescription)")
        }
        
        return nil
    }
    
    func getSavedImageFileName(_ image: UIImage, _ fileName: String) -> String? {
        
        let fileURL = getDocumentsUrl.appendingPathComponent(fileName)
        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
            try? imageData.write(to: fileURL, options: .atomic)
            
            return fileName
        }
        
        _handleErrorAsDialogMessage("IO Error (Write)", "unable to save image data to your device")
        
        return nil
    }
}
