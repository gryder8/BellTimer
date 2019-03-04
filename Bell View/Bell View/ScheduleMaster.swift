//
//  ScheduleMaster.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/14/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

import UIKit
import Foundation

class ScheduleMaster {
    
    private var defaultScheduleForToday:String = ""
    private var defaultScheduleForNextDay:String = ""
    
    enum weekDay: Int, Decodable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wedensday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }
    
    //The actual DataStucture containing the Default Schedule
    //for the various days of the week.
    struct DefaultDay: Decodable {
        let scheduleType: String
        let dayOfWeek: weekDay
    }
    
    struct SpecialDay: Decodable {
        let scheduleType: String
        let beginDate: Date
        let endDate: Date?
        let desc: String?
    }
    
    struct BellTime: Decodable {
        let desc: String
        let timeInterval: TimeInterval
    }
    
    let calendar = Calendar.current
    
    typealias AllSpecialDays = [SpecialDay]
    
    var allSpecialDays: AllSpecialDays?
    
    typealias BellSchedules = [Schedule]
    
    var allSchedules: BellSchedules?
    
    typealias AllDefaultDays = [DefaultDay]
    
    var allDefaultDays: AllDefaultDays?
    
    
    //Struct that holds all the belltimes
    struct Schedule: Decodable {
        var scheduleType: String
        let bellTimes: [BellTime]
    }
    
    
    init (mainBundle: Bundle) {
        //Parser for Special Days
        let plistURLSpecialDays: URL = mainBundle.url(forResource:"specialDays", withExtension:"plist")!
        
        if let data = try? Data(contentsOf: plistURLSpecialDays) {
            let decoder = PropertyListDecoder()
            allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
        }
        
        //*****************************************************
        
        //Bell Schedule Parser
        
        let pListURLBellSchedules: URL = mainBundle.url(forResource:"Schedules", withExtension:"plist")!
        
        if let data = try? Data(contentsOf: pListURLBellSchedules) {
            let decoder = PropertyListDecoder()
            allSchedules = try! decoder.decode(BellSchedules.self, from:data)
        }
        
        
        //******************************************************
        
        //Default Schedule Parser
        
        let plistURLDefaultDays: URL = mainBundle.url(forResource:"defaultSchedule", withExtension:"plist")!
        
        if let data = try? Data(contentsOf: plistURLDefaultDays) {
            let decoder = PropertyListDecoder()
            allDefaultDays = try! decoder.decode(AllDefaultDays.self, from:data)
        }
        
        let today = Calendar.current.component(.weekday, from:Date())
        let nextDayDateHolder = calendar.date(byAdding: .day, value: 1, to: Date())!
        let nextDay = Calendar.current.component(.weekday, from:nextDayDateHolder)
        
        for defaultDay in allDefaultDays! {
            if defaultDay.dayOfWeek.rawValue == today {
                defaultScheduleForToday = defaultDay.scheduleType
            }
            if defaultDay.dayOfWeek.rawValue == nextDay {
                defaultScheduleForNextDay = defaultDay.scheduleType
            }
        }
        
    }
    
    //************************************************************************************************************
    //************************************************************************************************************
    //************************************************************************************************************
    
    public func getScheduleType(myDate:Date) -> String {
        let now = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        var inputDate = myDate
        inputDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: myDate)!
        var theSpecialDay: SpecialDay?
        for canidateSpecialDay in allSpecialDays!{
            if self.isDateWithininSpecialDay(specialDay: canidateSpecialDay, dateInput: myDate) {
                theSpecialDay = canidateSpecialDay
            }
        }
        
        if (theSpecialDay == nil){
            if (now == inputDate) {
                return defaultScheduleForToday
            } else {
                return defaultScheduleForNextDay //TODO: TEST!
            }
        }
        
        return (theSpecialDay?.scheduleType)!
        
    }
    
    public func getFirstBellDescriptionForNextDay() -> String {
        let calendar = Calendar.current
        var forwardedDate:Date = calendar.date(byAdding: .day, value: 1, to: Date())!
        forwardedDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: forwardedDate)!
        if (specialDayDescIfApplicable(date: forwardedDate) != ""){
            return specialDayDescIfApplicable(date: forwardedDate)
        }
        
        return getNextBellTimeDescription(date: forwardedDate)
    }
    
    private let dateTester = Calendar.current.date(bySettingHour: 16, minute: 00, second: 0, of: Date())!
    
    private func specialDayDescIfApplicable(date:Date) -> String {
        for canidateSpecialDay in allSpecialDays! {
            if self.isDateWithininSpecialDay(specialDay: canidateSpecialDay, dateInput: date) {
                if canidateSpecialDay.desc != nil {
                    return canidateSpecialDay.desc!
                }
            }
        }
        return ""
    }
    
    public func getCurrentPeriodStartTimeInterval() -> TimeInterval {
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
        
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date())
        let currentBellTimes:Array = currentSchedule.bellTimes
        var currentBellTime:BellTime?
        for bellTime in currentBellTimes {
            if bellTime.timeInterval <= currentTimeAsInterval {
                currentBellTime = bellTime
            }
        }
        return (currentBellTime?.timeInterval)!
        }
    
    public func getCurrentBellTimeDescription() -> String {
        

        if (specialDayDescIfApplicable(date: Date()) != ""){
            return specialDayDescIfApplicable(date: Date())
        }
        
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
        
        
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date())
        
        let currentBellTimes:Array = currentSchedule.bellTimes
        
        var currentBellTime:BellTime?
        for bellTime in currentBellTimes {
            if bellTime.timeInterval <= currentTimeAsInterval {
                currentBellTime = bellTime
            }
        }
        let description:String = (currentBellTime?.desc)!
        return description
    }
    
    
    public func getNextBellTimeDescription(date:Date) -> String {
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
        let currentTimeAsInterval:TimeInterval = date.timeIntervalSince(baseTime)
        //        let currentTimeAsInterval:TimeInterval = dateTester.timeIntervalSince(baseTime) /***KEEP FOR TESTING***
        
        
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: date)
        let currentBellTimes:Array = currentSchedule.bellTimes
        
        
        for bellTime in currentBellTimes {
            if bellTime.timeInterval > currentTimeAsInterval {
                return bellTime.desc
            }
        }
        
        return getFirstBellDescriptionForNextDay()
    }
    
    public func getTimeIntervalUntilNextEvent() -> TimeInterval {
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let endTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
        //        let currentTimeAsInterval:TimeInterval = dateTester.timeIntervalSince(baseTime) //***KEEP FOR TESTING***
        
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date())
        
        let currentBellTimes:Array = currentSchedule.bellTimes
        
        for bellTime in currentBellTimes {
            if bellTime.timeInterval > currentTimeAsInterval {
                return bellTime.timeInterval - currentTimeAsInterval
            }
        }
        return endTime.timeIntervalSince(Date()) //time until end of the day
    }
    
    
    private func getBellScheduleFor(dateInput:Date) -> Schedule {
        let currentScheduleType:String = self.getScheduleType(myDate: dateInput)
        
        let currentSchedule:Schedule = self.getScheduleFor(scheduleType: currentScheduleType)
        return currentSchedule
    }
    
    public func getCurrentPeriodLengthAsTimeInterval() -> TimeInterval {
        var beginInterval:TimeInterval = 0.0
        var endInterval:TimeInterval = 0.0
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let endTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
        //        let currentTimeAsInterval:TimeInterval = dateTester.timeIntervalSince(baseTime) //***KEEP FOR TESTING***
        
        
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date())
        
        let currentBellTimes:Array = currentSchedule.bellTimes
        
        for bellTime in currentBellTimes {
            if bellTime.timeInterval <= currentTimeAsInterval {
                beginInterval = bellTime.timeInterval
            }
        }
        
        for bellTime in currentBellTimes {
            if bellTime.timeInterval > currentTimeAsInterval {
                endInterval = bellTime.timeInterval
                break
            }
        }
        
        if (endInterval == 0.0){ //if the current time is greater than any of the period start times the interval will still be 0
            return endTime.timeIntervalSince(baseTime)-beginInterval
        }
        
        return endInterval-beginInterval
    }
    
    private func getScheduleFor(scheduleType: String) -> Schedule {
        var resultSchedule:Schedule?
        for currentSchedule in allSchedules! {
            if currentSchedule.scheduleType == scheduleType {
                resultSchedule = currentSchedule
            }
        }
        return resultSchedule! //FIX: Throws for Modified Block
    }
    
    public func stringFromTimeInterval(interval: TimeInterval, is12Hour: Bool, useSeconds: Bool) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        var hours = (interval / 3600)
        if (is12Hour && hours > 12 && hours != 0){
            hours = hours - 12
        } else if (is12Hour && hours == 0){
            hours = 12
        }
        if (!useSeconds){
            return String(format:"%02d:%02d", hours, minutes)
        }
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    public func getWholeScheduleForDay() -> Array<String> {
        var schedulesArray:Array<String> = []
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date())
        
        let currentBellTimes:Array = currentSchedule.bellTimes
        if (currentSchedule.bellTimes.count > 1){
            for bellSchedule in currentBellTimes {
                schedulesArray += ["\(bellSchedule.desc) - " + "\(stringFromTimeInterval(interval: bellSchedule.timeInterval, is12Hour: true, useSeconds: false))"]
            }
        } else if (currentSchedule.bellTimes.count <= 1){
            if (specialDayDescIfApplicable(date: Date()) != ""){
                schedulesArray = [specialDayDescIfApplicable(date: Date())]
                return schedulesArray
            }
            schedulesArray = [currentSchedule.scheduleType]
        }
        return schedulesArray
    }
    
    
    func isDateWithininSpecialDay (specialDay: SpecialDay, dateInput: Date) -> Bool {
        var now = Date() //Create date set to midnight on the current date
        now = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: dateInput)!
        var beginDate:Date  = specialDay.beginDate
        beginDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: beginDate)!
        var endDate: Date? = specialDay.endDate
        if endDate != nil {
            endDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: endDate!)!
        }
        var inRange:Bool = false
        
        if now == beginDate {
            inRange = true
        }
        
        if endDate != nil {
            if now == endDate {
                inRange = true
            } else if now > beginDate && now < endDate! {
                inRange = true
            }
        }
        
        return inRange
    }
}
