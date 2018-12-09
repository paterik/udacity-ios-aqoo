//
//  Dictionary.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 09.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

extension Dictionary {
    
    static func += ( lhs: inout Dictionary, rhs: Dictionary ) {
        
        lhs.merge(rhs) { (_, new) in new }
    }
    
    mutating func update(_ other: Dictionary ) {
        
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
    
    func combinedWith(_ other: Dictionary<Key,Value> ) -> Dictionary<Key,Value> {
        var other = other
        for (key, value) in self {
            other[key] = value
        }
        return other
    }
}
