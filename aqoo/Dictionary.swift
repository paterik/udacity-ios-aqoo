//
//  Dictionary.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 09.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

/*extension Dictionary {
    
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}*/

extension Dictionary {
    /// Return a new dictionary with values from `self` and `other`.  For duplicate keys, self wins.
    func combinedWith( other: Dictionary<Key,Value>) -> Dictionary<Key,Value> {
        var other = other
        for (key, value) in self {
            other[key] = value
        }
        return other
    }
}
