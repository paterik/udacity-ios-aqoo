//
//  PlaylistEditViewSecondPage.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.06.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import fluid_slider

class PlaylistEditViewSecondPage: BasePlaylistEditViewController {
    
    var playlistUpdateDetected: Bool = false
    
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet weak var cViewPlaylistRatingIntensity: Slider!
    @IBOutlet weak var cViewPlaylistRatingEmotional: Slider!
    @IBOutlet weak var cViewPlaylistRatingDepth: Slider!
    @IBOutlet weak var lblPlaylistRatingAverageValue: UILabel!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUIPlaylistRatingSliders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        appDelegate.restrictRotation = .portrait
    }
    
    //
    // MARK: Class IABaction Methods
    //
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {
        
        handlePlaylistMetaUpdate()
        dismiss(animated: true, completion: nil)
    }
}
