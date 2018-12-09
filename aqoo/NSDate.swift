//
//  NSDate.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 06.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

extension NSDate {
    
    func dateToString(
       _ date: Date!,
       _ format: String) -> NSString {
        
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
        
        return dateFormatter.string(from: date) as NSString
    }
    
    func dateFromString(
       _ date: NSString,
       _ format: String) -> NSDate {
        
        let formatter = DateFormatter()
        let locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        formatter.locale = locale as Locale!
        formatter.dateFormat = format
        
        return formatter.date(from: date as String)! as NSDate
    }
}
