//
//  ProxStreamPlayListTrack.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 22.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

class ProxStreamPlayListTrack {
    
    var playlistIdentifier: String
    var trackIdentifier: String?
    var trackURIInternal: URL
    var trackDuration: TimeInterval
    var trackExplicit: Bool
    var trackPopularity: Double
    var trackAddedAt: NSDate
    var trackNumber: Int
    var discNumber: Int
    var trackName: String
    var albumName: String
    
    init(plIdentifier: String,
         tIdentifier: String?,
         tURIInternal: URL,
         tDuration: TimeInterval,
         tExplicit: Bool,
         tPopularity: Double,
         tAddedAt: NSDate,
         tTrackNumber: Int,
         tDiscNumber: Int,
         tName: String,
         aName: String
         ) {
        
        playlistIdentifier = plIdentifier
        if  tIdentifier != nil {
            trackIdentifier = tIdentifier!
        }
        
        trackURIInternal = tURIInternal
        trackDuration = tDuration
        trackExplicit = tExplicit
        trackPopularity = tPopularity
        trackAddedAt = tAddedAt
        trackNumber = tTrackNumber
        discNumber = tDiscNumber
        trackName = tName
        albumName = aName
    }
}
