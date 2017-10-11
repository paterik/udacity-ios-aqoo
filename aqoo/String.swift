//
//  String.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 11.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation

extension String {
    
    func dropLast(_ n: Int = 1) -> String {
        return String(characters.dropLast(n))
    }
    
    var dropLast: String {
        return dropLast()
    }
}
