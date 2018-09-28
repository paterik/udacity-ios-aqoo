//
//  ProxyPlaylist.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 02.09.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

class ProxyPlaylist {
    
    //
    // MARK: Constants (Statics)
    //
    
    static let sharedInstance = ProxyPlaylist()
    
    //
    // MARK: Properties
    //
    
    var tracks: [StreamPlayListTracks]?
    var trackCheckTimer: Timer!
    var shuffleKeys: [Int]?
    var playMode: Int16 = 0

    func reset() {
        
        tracks = nil
        shuffleKeys = nil
        playMode = 0
    }
}
