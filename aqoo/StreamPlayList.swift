//
//  StreamPlayList.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 24.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import CoreStore

class StreamPlayList: NSManagedObject {
    
    @NSManaged var name: String
    @NSManaged var owner: String
    @NSManaged var trackCount: Int64
    @NSManaged var playableURI: String
    @NSManaged var smallestImage: Data?
    @NSManaged var largestImage: Data?
    @NSManaged var isPublic: Bool
    @NSManaged var isCollaborative: Bool
    @NSManaged var updatedAt: Date?
    @NSManaged var createdAt: Date?
    
    @NSManaged var metaListHash: String
    @NSManaged var metaLastListenedAt: Date?
    @NSManaged var metaMarkedAsFavorite: Bool
    @NSManaged var metaNumberOfShares: Int64
    
    @NSManaged var provider: CoreStreamingProvider?
}
