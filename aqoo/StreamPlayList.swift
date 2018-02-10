//
//  StreamPlayList.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 24.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import CoreStore
import CryptoSwift

class StreamPlayList: NSManagedObject {
    
    @NSManaged var owner: String
    @NSManaged var ownerImageURL: String
    @NSManaged var trackCount: Int32
    @NSManaged var playableURI: String
    @NSManaged var smallestImageURL: String?
    @NSManaged var largestImageURL: String?
    
    @NSManaged var coverImagePathOverride: String?
    @NSManaged var profileImagePathOverride: String?
   
    @NSManaged var isHot: Bool
    @NSManaged var isMine: Bool
    @NSManaged var isSpotify: Bool
    @NSManaged var isPublic: Bool
    @NSManaged var isCollaborative: Bool
    
    @NSManaged var isPlaylistVotedByStar: Bool
    @NSManaged var isPlaylistRadioSelected: Bool
    @NSManaged var isPlaylistHidden: Bool
    
    @NSManaged var updatedAt: Date?
    @NSManaged var createdAt: Date?
    
    @NSManaged var metaListInternalDescription: String
    @NSManaged var metaListInternalName: String
    @NSManaged var metaListInternalRating: Float
    @NSManaged var metaListNameOrigin: String
    
    @NSManaged var metaListHash: String
    @NSManaged var metaLastListenedAt: Date?

    @NSManaged var metaMediaRessourcesArray: NSArray?
    
    @NSManaged var metaNumberOfShares: Int64
    @NSManaged var metaNumberOfUpdates: Int64
    @NSManaged var metaNumberOfPlayed: Int64
    @NSManaged var metaNumberOfPlayedPartly: Int64
    @NSManaged var metaNumberOfPlayedCompletely: Int64
    
    @NSManaged var metaPreviouslyUpdatedManually: Bool
    @NSManaged var metaPreviouslyUpdated: Bool
    @NSManaged var metaPreviouslyCreated: Bool
    
    @NSManaged var provider: StreamProvider?
    
    func getMD5FingerPrint() -> String {
    
        return String(
            format: "%@:%D:%@:%@",
            self.metaListNameOrigin,
            self.trackCount,
            "\(self.isPublic)",
            "\(self.isCollaborative)").md5()
    }
}

extension StreamPlayList {
    
    var images: [String] {
        get { return metaMediaRessourcesArray as? Array<String> ?? [] }
        set { metaMediaRessourcesArray = newValue as NSArray }
    }
}
