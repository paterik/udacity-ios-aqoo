//
//  StreamFilterMenuItem.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 06.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Persei
import UIKit

public struct StreamFilterMenuItem {
    
    public var itemIndex: Int
    public var title: String?
    public var description: String?
    
    var cause: ReferenceWritableKeyPath<StreamPlayList, Bool>?
    
    // MARK: - Init
    public init(itemIndex: Int, title: String, description: String? = nil ) {
        
        self.itemIndex = itemIndex
        self.title = title
        self.description = description
        self.cause = nil
    }
}
