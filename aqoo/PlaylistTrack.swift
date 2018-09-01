//
//  PlaylistTrack.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 01.09.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

class PlaylistTrack {
    
    //
    // MARK: Constants (Statics)
    //
    
    static let sharedInstance = PlaylistTrack()
    
    //
    // MARK: Properties
    //
    
    var cell: PlaylistTracksTableCell?
    var selected: StreamPlayListTracks?
    
    var index: Int = 0
    var timePosition: Int = 0
    var timeProgress: Float = 0.0
    var interval: TimeInterval?
    var isPlaying: Bool = false
    var isPlayingInManualMode: Bool = false
    
    func reset() {
        
        cell = nil
        index = 0
        timePosition = 0
        timeProgress = 0.0
        interval = nil
        isPlayingInManualMode = false
        isPlaying = false
    }
}
