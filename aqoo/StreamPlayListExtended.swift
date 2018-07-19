//
//  StreamPlayListExtended.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 19.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

class StreamPlayListExtended {
    
    var playlistExternalName: String?
    var playlistIdentifier: String?
    var playlistSnapshotId: String?
    var playlistFollowerCount: Int?
    
    init(_ playlistName: String, _ identifier: String, _ snapshotId: String, _ followerCount: Int) {
        
        playlistIdentifier = identifier
        playlistSnapshotId = snapshotId
        playlistFollowerCount = followerCount
        playlistExternalName = playlistName
    }
}
