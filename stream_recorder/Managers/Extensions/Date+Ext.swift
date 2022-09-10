//
//  Date+Ext.swift
//  Scanner
//
//  Created by Rum on 01/08/2021.
//

import UIKit

extension Date {
    func stringFromDateWithFormat(_ format: String) -> String {
        let dateFormatter = DateFormatter()

        if Cache.shared.app_language == .Vietnamese {
            dateFormatter.locale = Locale(identifier: "vi_VN")
        } else {
            dateFormatter.locale = Locale(identifier: "en_US")
        }
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    func getStringTime() -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = "dd/MM/yy, HH:mm"
        dateformat.timeZone = TimeZone.current
        return dateformat.string(from: self)
    }
    
    static func timeServer() -> Date {
        return Date()
    }
    
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: Date.timeServer()).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: Date.timeServer()).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: Date.timeServer()).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: Date.timeServer()).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: Date.timeServer()).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: Date.timeServer()).second ?? 0
    }
    
    func offsetFromComment() -> String {

        let minute = minutes(from: self)
        let hour = hours(from: self)
        let day = days(from: self)

        if day >= 1 {
            let dateformat = DateFormatter()
            dateformat.dateFormat = "HH:mm, dd MMM yyyy"
            dateformat.timeZone = TimeZone.current
            return dateformat.string(from: self)
        }
        
        if hour > 1 {
            return String(format: "%i hour ago", hour)
        } else if hour == 1 {
            return String(format: "%i hour ago", hour)
        }
        
        if minute > 1 {
            return String(format: "%i minutes ago", minute)
        } else if minute == 1 {
            return String(format: "%i minute ago", minute)
        }

        return "Just now"
    }
}
