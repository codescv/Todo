//
//  NSDate+ESAdditions.swift
//  Todo
//
//  Created by Chi Zhang on 12/26/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import Foundation

extension NSDate {
    class func today() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: NSDate())
        return calendar.dateFromComponents(components)!
    }
    
    class func tomorrow() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: NSDate())
        components.day += 1
        return calendar.dateFromComponents(components)!
    }
    
    func isToday() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        let todayComponents = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: NSDate())
        let components = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: self)
        return todayComponents.year == components.year && todayComponents.month == components.month && todayComponents.day == components.day
    }
    
    class func dateWithYMD(year year: Int, month: Int, day: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.dateFromComponents(components)!
    }
    
    func weekday() -> Int {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: NSDate())
        return components.weekday
    }
    
    func nearestWeekday(nextWeekday: Int) -> NSDate {
        let thisWeekday = self.weekday()
        let delta = NSDateComponents()
        var deltaDays = (nextWeekday - thisWeekday) % 7
        if deltaDays < 0 {
            deltaDays += 7
        }
        delta.day = deltaDays
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateByAddingComponents(delta, toDate: self, options: [])!
    }
    
    func yyyymmdd(separator separator: String = "-") -> String {
        let fm = NSDateFormatter()
        fm.dateFormat = ["YYYY", "MM", "dd"].joinWithSeparator(separator)
        return fm.stringFromDate(self)
    }
    
    func shortString() -> String {
        let fm = NSDateFormatter()
        fm.dateFormat = "HH:mm"
        return fm.stringFromDate(self)
    }
}
