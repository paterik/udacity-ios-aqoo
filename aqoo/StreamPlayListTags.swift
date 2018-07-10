//
//  StreamPlayListTags.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 10.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//


import CoreStore
import CryptoSwift

class StreamPlayListTags: NSManagedObject {
    
    @NSManaged var playlistTag: String
    @NSManaged var playlist: StreamPlayList?
    @NSManaged var updatedAt: Date?
    @NSManaged var createdAt: Date?
}
