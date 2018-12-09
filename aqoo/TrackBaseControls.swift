//
//  TrackBaseControls.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 10.11.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import fluid_slider

class TrackBaseControls: UIView {
    
    //
    // MARK: Class IBOutlet definitions
    //
    
    @IBOutlet weak var cViewTrackPositionIndex: Slider!
    @IBOutlet weak var btnSetPreviousTrack: UIButton!
    @IBOutlet weak var btnSetNextTrack: UIButton!
}
