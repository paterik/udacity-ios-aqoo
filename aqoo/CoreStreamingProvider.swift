//
//  CoreStreamingProvider.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 24.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import CoreStore

class CoreStreamingProvider: NSManagedObject {
    
    @NSManaged var name: String
    @NSManaged var tag: String
    @NSManaged var details: String?
    @NSManaged var isActive: Bool
    @NSManaged var playlists: [StreamPlayList]
}
