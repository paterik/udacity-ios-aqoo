//
//  DFNumbers.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 12.12.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

class DFNumbers {
    
    //
    // MARK: Class Constants (Statics)
    //
    
    static let sharedInstance = DFNumbers()
    
    //
    // MARK: Class Constants (Public)
    //
    
    func getRandomNumber(between lower: Int, and upper: Int) -> Int {
        
        return Int(arc4random_uniform(UInt32(upper - lower))) + lower
    }
    
    func getRandomUniqueNumberArray(forLowerBound lower: Int, andUpperBound upper:Int, andNumNumbers iterations: Int) -> [Int] {
        
        guard iterations <= (upper - lower) else { return [] }
        
        var numbers: Set<Int> = Set<Int>()
        
        (0..<iterations).forEach { _ in
            let beforeCount = numbers.count
            repeat {
                numbers.insert(getRandomNumber(between: lower, and: upper))
            }   while numbers.count == beforeCount
        }
        
        return numbers.map{ $0 }
    }
}
