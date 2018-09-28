//
//  ProxyStreamPlayListExtended.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 19.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

class ProxyStreamPlayListExtended {
    
    var playlistIdentifier: String
    var playlistSnapshotId: String
    var playlistFollowerCount: Int
    
    init(identifier: String, snapshotId: String, followerCount: Int) {
        
        playlistIdentifier = identifier
        playlistSnapshotId = snapshotId
        playlistFollowerCount = followerCount
    }
}
