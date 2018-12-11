//
//  ProxyStreamPlayListExtended.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 19.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

class ProxyStreamPlayListExtended {
    
    //
    // MARK: Properties
    //
    
    var playlistIdentifier: String
    var playlistSnapshotId: String
    var playlistFirstTrackCoverUrl: String?
    var playlistFollowerCount: Int
    
    init(identifier: String, snapshotId: String, followerCount: Int, coverUrl: String?) {
        
        playlistIdentifier = identifier
        playlistSnapshotId = snapshotId
        playlistFollowerCount = followerCount
        playlistFirstTrackCoverUrl = coverUrl
    }
}
