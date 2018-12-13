//
//  DFDates.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 12.12.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Foundation

class DFDates {

    //
    // MARK: Class Constants (Statics)
    //
    
    static let sharedInstance = DFDates()
    
    //
    // MARK: Class Constants (Public)
    //
    
    func getDateAsString (_ dateValue: Date, _ dateFormatter: String = "dd.MM.Y hh:mm") -> NSString {
        
        return NSDate().dateToString(Date(), dateFormatter) as! NSString
    }
    
    func getSecondsAsHoursMinutesSeconds (_ seconds : Int) -> (Int, Int, Int) {
        
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func getSecondsAsHoursMinutesSecondsString (_ seconds : Int) -> String {
        
        let (h, m, s) = getSecondsAsHoursMinutesSeconds ( seconds )
        
        return "\(h) hours, \(m) min, \(s) sec"
    }
    
    func getSecondsAsHoursMinutesSecondsDigits (_ seconds : Int) -> String {
        
        let (h, m, s) = getSecondsAsHoursMinutesSeconds ( seconds )
        
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    func getSecondsAsMinutesSecondsDigits (_ seconds : Int) -> String {
        
        let (h, m, s) = getSecondsAsHoursMinutesSeconds ( seconds )
        
        return String(format: "%02d:%02d", m, s)
    }
    
    func getHumanReadableDate(_ date : Date) -> String {
        
        var secondsAgo = Int(Date().timeIntervalSince(date))
        if  secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        if  secondsAgo < minute  {
            
            if  secondsAgo < 2 {
                return "just now"
            }   else {
                return "\(secondsAgo) secs ago"
            }
            
        }   else if secondsAgo < hour {
            
            let min = (secondsAgo / minute)
            
            if  min == 1 {
                return "\(min) min ago"
            }   else {
                return "\(min) mins ago"
            }
            
        }   else if secondsAgo < day {
            
            let hr = (secondsAgo / hour)
            
            if  hr == 1 {
                return "\(hr) hr ago"
            }   else {
                return "\(hr) hrs ago"
            }
            
        }   else if secondsAgo < week {
            
            let day = (secondsAgo / day)
            
            if  day == 1 {
                return "\(day) day ago"
            }   else {
                return "\(day) days ago"
            }
            
        }   else {
            
            let formatter = DateFormatter()
                formatter.dateFormat = "MMM dd, hh:mm a"
                formatter.locale = Locale(identifier: "en_US")
            
            let strDate: String = formatter.string(from: date)
            
            return strDate
        }
    }
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
