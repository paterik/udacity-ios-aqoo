//
//  aqooTests.swift
//  aqooTests
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import XCTest
import Foundation

@testable import aqoo

class aqooTests: XCTestCase {
    
    var dfDates:DFDates!
    var dfNumbers:DFNumbers!
    
    override func setUp() {
        
        super.setUp()
        
        dfDates = DFDates.sharedInstance
        dfNumbers = DFNumbers.sharedInstance
    }
    
    override func tearDown() {
       
        super.tearDown()
        
        dfDates = nil
        dfNumbers = nil
    }
    
    func testDfNumbersGetRandomNumber() {
        
        var randomNumber: Int = dfNumbers.getRandomNumber(between: 1, and: 10)
        
        XCTAssertTrue(randomNumber >= 1 && randomNumber <= 10)
    }
    
    func testDfNumbersGetRandomNumberArray() {
        
        var randomNumberArray: [Int] = dfNumbers.getRandomUniqueNumberArray(
            forLowerBound: 0,
            andUpperBound: 10,
            andNumNumbers: 10
        )
        
        XCTAssertTrue(randomNumberArray.count == 10)
        
        for randomNumber in randomNumberArray {
            XCTAssertTrue(randomNumber >= 0 && randomNumber <= 10)
        }
    }
    
    func testDfDatesGetDateAsString() {
        
        let dateFormatter = DateFormatter()
        let dateFormatterPattern = "yyyy/MM/dd HH:mm"
        var dateComponents = DateComponents()
        
        dateComponents.year = 1977
        dateComponents.month = 11
        dateComponents.day = 12
        dateComponents.timeZone = TimeZone(abbreviation: "UTC")
        dateComponents.hour = 10
        dateComponents.minute = 25
        dateFormatter.dateFormat = dateFormatterPattern
        
        let userCalendar = Calendar.current
        let someDateTime = userCalendar.date(from: dateComponents)
        
        var someDateTimeAsString: NSString = dfDates.getDateAsString(someDateTime!, dateFormatterPattern)
        
        let someDateTimeFormatted = dateFormatter.date(from: someDateTimeAsString as String)
        
        XCTAssertTrue(someDateTime! == someDateTimeFormatted)
    }
    
    func testDfDatesGetSecondsAsHoursMinutesSeconds() {
        
        let someSeconds = 3749
        let (h, m, s) = dfDates.getSecondsAsHoursMinutesSeconds ( someSeconds )
        
        XCTAssertTrue(h == 1)
        XCTAssertTrue(m == 2)
        XCTAssertTrue(s == 29)
    }
    
    func testDfDatesGetSecondsAsHoursMinutesSecondsString() {
        
        let someSeconds = 3749
        let someSecondsAsFormattedString = dfDates.getSecondsAsHoursMinutesSecondsString( someSeconds )
        
        XCTAssertTrue(someSecondsAsFormattedString == "1 hours, 2 min, 29 sec")
    }
    
    func testDfDatesGetSecondsAsHoursMinutesSecondsDigits() {
     
        let someSeconds = 3749
        let someSecondsAsFormattedString = dfDates.getSecondsAsHoursMinutesSecondsDigits( someSeconds )
        
        XCTAssertTrue(someSecondsAsFormattedString == "01:02:29")
    }
    
    func testDfDatesGetSecondsAsMinutesSecondsDigits() {
        
        let someSeconds = 3749
        let someSecondsAsFormattedString = dfDates.getSecondsAsMinutesSecondsDigits( someSeconds )
        
        XCTAssertTrue(someSecondsAsFormattedString == "62:29")
    }
    
    func testDfDatesGetHumanReadableDate() {
        
        let dateA = Date()
        let dateB = dateA.addingTimeInterval(TimeInterval(3.0)) // add 3 seconds to "now"
        let dateC = dateA.addingTimeInterval(TimeInterval(61.0)) // add 1 minute to "now"
        let dateD = dateA.addingTimeInterval(TimeInterval(61.0 * 2.0)) // add 1 minute to "now"
        let dateE = dateA.addingTimeInterval(TimeInterval(61.0 * 60.0)) // add 1 hour to "now"
        let dateF = dateA.addingTimeInterval(TimeInterval(61.0 * 120.0)) // add 2 hours to "now"
        let dateG = dateA.addingTimeInterval(TimeInterval(61.0 * 1440.0)) // add 1 day to "now"
        let dateH = dateA.addingTimeInterval(TimeInterval(61.0 * 2880.0)) // add 2 days to "now"
        
        let someReadableDateA = dfDates.getHumanReadableDate( dateA )
        let someReadableDateB = dfDates.getHumanReadableDate( dateB )
        let someReadableDateC = dfDates.getHumanReadableDate( dateC )
        let someReadableDateD = dfDates.getHumanReadableDate( dateD )
        let someReadableDateE = dfDates.getHumanReadableDate( dateE )
        let someReadableDateF = dfDates.getHumanReadableDate( dateF )
        let someReadableDateG = dfDates.getHumanReadableDate( dateG )
        let someReadableDateH = dfDates.getHumanReadableDate( dateH )
        
        XCTAssertTrue(someReadableDateA == "just now")
        XCTAssertTrue(someReadableDateB == "2 secs ago")
        XCTAssertTrue(someReadableDateC == "1 min ago")
        XCTAssertTrue(someReadableDateD == "2 mins ago")
        XCTAssertTrue(someReadableDateE == "1 hr ago")
        XCTAssertTrue(someReadableDateF == "2 hrs ago")
        XCTAssertTrue(someReadableDateG == "1 day ago")
        XCTAssertTrue(someReadableDateH == "2 days ago")
    }
}
