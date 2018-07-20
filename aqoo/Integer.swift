//
//  Integer.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 11.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

extension Int {
    // max: 2.147.483.647
    var hrFormatted: String {
        
        if  self >= 1000, self <= 999999 {
            return String(format: "%.1dk", locale: Locale.current, self / 1000)
        }
        
        if  self > 999999 {
            return String(format: "%.1dM", locale: Locale.current, self / 1000000)
        }
        
        // stop handling numbers beyond type maximum ;)
        if  self >= 2147483647 {
            return "∞"
        }
        
        if  self == 0 {
            return "-"
        }
        
        return String(format: "%.0d", locale: Locale.current, self)
    }
}

extension Int32 {
    // max: 2.147.483.647
    var hrFormatted: String {
        
        if  self >= 1000, self <= 999999 {
            return String(format: "%.1dk", locale: Locale.current, self / 1000)
        }
        
        if  self > 999999 {
            return String(format: "%.1dM", locale: Locale.current, self / 1000000)
        }
        
        // stop handling numbers beyond type maximum ;)
        if  self >= 2147483647 {
            return "∞"
        }
        
        if  self == 0 {
            return "-"
        }
        
        return String(format: "%.0d", locale: Locale.current, self)
    }
}

extension Int64 {
    // max: 9.223.372.036.854.775.807
    var hrFormatted: String {
        
        if  self >= 1000, self <= 999999 {
            return String(format: "%.1dk", locale: Locale.current, self / 1000)
        }
        
        if  self > 999999 {
            return String(format: "%.1dM", locale: Locale.current, self / 1000000)
        }
        
        if  self > 999999999 {                                             999999999
            return String(format: "%.1dB", locale: Locale.current, self / 1000000000)
        }
        
        if  self > 999999999999 {
            return String(format: "%.1dT", locale: Locale.current, self / 1000000000000)
        }
        
        // stop handling numbers beyond quatrillion ;)
        if  self > 999999999999999 {
            return "∞"
        }
        
        if  self == 0 {
            return "-"
        }
        
        return String(format: "%.0d", locale: Locale.current, self)
    }
}
