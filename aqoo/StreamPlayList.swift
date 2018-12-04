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
    @NSManaged var ownerSharingURL: String
    @NSManaged var ownerImageURL: String
    @NSManaged var ownerFollowerCount: Int
    
    @NSManaged var trackCount: Int32
    @NSManaged var trackCountOld: Int32
    @NSManaged var playableURI: String
    @NSManaged var smallestImageURL: String?
    @NSManaged var largestImageURL: String?
    
    @NSManaged var coverImagePathOverride: String?
    @NSManaged var profileImagePathOverride: String?
   
    @NSManaged var isMine: Bool
    @NSManaged var isSpotify: Bool
    @NSManaged var isPublic: Bool
    @NSManaged var isCollaborative: Bool
    @NSManaged var isIncomplete: Bool
    
    @NSManaged var isPlaylistVotedByStar: Bool
    @NSManaged var isPlaylistRadioSelected: Bool
    @NSManaged var isPlaylistHidden: Bool
    @NSManaged var isPlaylistYourWeekly: Bool
    
    @NSManaged var updatedAt: Date?
    @NSManaged var createdAt: Date?
    
    @NSManaged var metaListInternalDescription: String
    @NSManaged var metaListInternalName: String
    @NSManaged var metaListOverallPlaytimeInSeconds: Int32
    
    //
    // https://www.digitalmusicnews.com/2016/05/17/music-genres-three-attributes/
    //
    @NSManaged var metaListRatingArousal: Float
    @NSManaged var metaListRatingValence: Float
    @NSManaged var metaListRatingDepth: Float
    @NSManaged var metaListRatingOverall: Float
    
    @NSManaged var metaListNameOrigin: String
    @NSManaged var metaListSnapshotId: String
    @NSManaged var metaListSnapshotDate: Date?
    
    @NSManaged var metaListHash: String
    @NSManaged var metaLastListenedAt: Date?

    @NSManaged var metaMediaRessourcesArray: NSArray?
    
    @NSManaged var metaNumberOfShares: Int64
    @NSManaged var metaNumberOfUpdates: Int64
    @NSManaged var metaNumberOfPlayed: Int64
    @NSManaged var metaNumberOfPlayedPartly: Int64
    @NSManaged var metaNumberOfPlayedCompletely: Int64
    @NSManaged var metaNumberOfFollowers: Int
    
    //
    // this property will be used as playmode flag for currently played playlists
    //
    @NSManaged var currentPlayMode: Int16
    
    @NSManaged var metaPreviouslyUpdatedManually: Bool
    @NSManaged var metaPreviouslyUpdated: Bool
    @NSManaged var metaPreviouslyCreated: Bool
    
    //
    // this property will be used as "override" for all order-by presets
    // to select-down (or select-up) a group of specific entities (e.g.
    // internal playlists like 'weekly', 'star voted' or 'liked from radio')
    // this will be result in bottom-/top-only rows for those internals ...
    //
    @NSManaged var metaWeight: Int32
    
    @NSManaged var provider: StreamProvider?
    
    @NSManaged var tags: [StreamPlayListTags]?
    
    @NSManaged var tracks: [StreamPlayListTracks]?
}

extension StreamPlayList {

    func getMD5Fingerprint() -> String {
        
        return String(
            format: "%@:%D:%@:%@",
            self.metaListNameOrigin,
            self.trackCount,
            "\(self.isPublic)",
            "\(self.isCollaborative)").md5()
    }
    
    func getMD5Identifier() -> String {
        
        return playableURI.md5()
    }
    
    var imageList: [String] {
        get { return metaMediaRessourcesArray as? Array<String> ?? [] }
        set { metaMediaRessourcesArray = newValue as NSArray }
    }
}
