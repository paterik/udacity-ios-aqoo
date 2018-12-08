//
//  PlaylistEditViewThirdPage.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.06.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

class PlaylistEditViewThirdPage: BasePlaylistEditViewController {
    
    var playlistUpdateDetected: Bool = false
    
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet weak var textFieldPlaylistDetails: UITextView!
    @IBOutlet weak var btnResetPlaylistStatistics: UIButton!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUIPlaylistDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    //
    // MARK: Class IABaction Methods
    //
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {
        
        handlePlaylistMetaUpdate()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnResetPlaylistStatisticsAction(_ sender: Any) {
        
        let resetPlaylistStatsRequest = UIAlertController(
            title: "Reset Statistics?",
            message: "do you want to reset all meta statistics from this playlist?",
            preferredStyle: UIAlertControllerStyle.alert
        )
        
        let dlgBtnYesAction = UIAlertAction(title: "Yes", style: .default) { (action: UIAlertAction!) in
            
            return
        }
        
        let dlgBtnCancelAction = UIAlertAction(title: "No", style: .default) { (action: UIAlertAction!) in
            
            return
        }
        
        resetPlaylistStatsRequest.addAction(dlgBtnYesAction)
        resetPlaylistStatsRequest.addAction(dlgBtnCancelAction)
        
        present(resetPlaylistStatsRequest, animated: true, completion: nil)
    }
}
