//
//  ProxyStreamPlayListTrack.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 22.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

class ProxyStreamPlayListTrack {
    
    //
    // MARK: Properties
    //
    
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
    var trackArtists: [SPTPartialArtist]
    var albumName: String
    var albumCoverLargestImageURL: String?
    var albumCoverSmallestImageURL: String?
    
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
         tArtists: [SPTPartialArtist],
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
        trackArtists = tArtists
        albumName = aName
    }
}

extension ProxyStreamPlayListTrack {
    
    func getMD5Fingerprint() -> String {
        
        return String(
            format: "%@:%@:%@:%@",
            self.trackName,
            self.trackURIInternal.absoluteString,
            "\(self.trackExplicit)",
            "\(self.trackPopularity)").md5()
    }
    
    func getMD5Identifier() -> String {
        
        return trackURIInternal.absoluteString.md5()
    }
}
