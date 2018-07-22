//
//  StreamPlayListTracks.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 22.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import CoreStore
import CryptoSwift

class StreamPlayListTracks: NSManagedObject {
    
    @NSManaged var trackIdentifier: String?
    @NSManaged var trackURIInternal: String
    @NSManaged var trackDuration: Int32
    
    @NSManaged var trackExplicit: Bool
    @NSManaged var trackPopularity: Double
    @NSManaged var trackAddedAt: Date
    @NSManaged var trackNumber: Int16
    @NSManaged var discNumber: Int16
    @NSManaged var trackName: String
    @NSManaged var albumName: String
    
    @NSManaged var metaTrackArtists: String
    
    @NSManaged var updatedAt: Date?
    @NSManaged var createdAt: Date?
    
    @NSManaged var playlist: StreamPlayList?
}

extension StreamPlayListTracks {
    
    func getMD5Fingerprint() -> String {
        
        return String(
            format: "%@:%@:%@:%@",
            self.trackName,
            self.trackURIInternal,
            "\(self.trackExplicit)",
            "\(self.trackPopularity)").md5()
    }
    
    func getMD5Identifier() -> String {
        
        return trackURIInternal.md5()
    }
}
