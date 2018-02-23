//
//  AppConfig.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 23.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import CoreStore
import CryptoSwift

class AppConfig: NSManagedObject {
    
    @NSManaged var defaultPlaylistTableFilterKey: Int16
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var provider: StreamProvider?
}
