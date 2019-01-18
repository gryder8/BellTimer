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
        
        for defaultDay in allDefaultDays! {
            if defaultDay.dayOfWeek.rawValue == today {
                defaultScheduleForToday = defaultDay.scheduleType
            }
        }

    }
    
    //************************************************************************************************************
    //************************************************************************************************************
    //************************************************************************************************************
    
    public func getScheduleType() -> String {
        var theSpecialDay: SpecialDay?
        for canidateSpecialDay in allSpecialDays!{
            if self.isDateWithininSpecialDay(specialDay: canidateSpecialDay) {
                theSpecialDay = canidateSpecialDay
            }
        }

        if (theSpecialDay == nil){
            //print(defaultScheduleForToday)
            return defaultScheduleForToday
        }
        
        return (theSpecialDay?.scheduleType)!
        
    }

    
//    public func getFirstBellDescriptionForNextDay() -> String {
//        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
//        let calendar = Calendar.current
//        var date:Date = calendar.date(byAdding: .day, value: 1, to: Date())!
//        date = calendar.date(bySettingHour: 1, minute: 00, second: 0, of: date)!
//        return ""
//    }
    
    private let dateTester = Calendar.current.date(bySettingHour: 11, minute: 30, second: 0, of: Date())!
    
    public func getCurrentBellTimeDescription() -> String {
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
//        let currentTimeAsInterval:TimeInterval = dateTester.timeIntervalSince(baseTime)

        
        let currentSchedule:Schedule = self.getCurrentBellSchedule() 
        
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
    
    public func getNextBellTimeDescription() -> String {
        let calendar = Calendar.current
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
//        let currentTimeAsInterval:TimeInterval = dateTester.timeIntervalSince(baseTime)

        
        let currentSchedule:Schedule = self.getCurrentBellSchedule()
        
        let currentBellTimes:Array = currentSchedule.bellTimes
        
        for bellTime in currentBellTimes {
            if bellTime.timeInterval > currentTimeAsInterval {
                return bellTime.desc
            }
        }
        
        if (calendar.component(.day, from: Date())>=7 && calendar.component(.month, from: Date()) == 6 || calendar.component(.month, from: Date()) > 6) { //7th day of 6th month (June)
            return "Summer!"
        } else if (calendar.component(.weekday, from: Date()) == 6){
            return "Weekend"
        }
        return "Before School"
    }
    
    public func getTimeIntervalUntilNextEvent() -> TimeInterval {
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let endTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
//        let currentTimeAsInterval:TimeInterval = dateTester.timeIntervalSince(baseTime)

        
        let currentSchedule:Schedule = self.getCurrentBellSchedule()
        
        let currentBellTimes:Array = currentSchedule.bellTimes
        
        for bellTime in currentBellTimes {
            if bellTime.timeInterval > currentTimeAsInterval {
                return bellTime.timeInterval - currentTimeAsInterval
            }
        }
        return endTime.timeIntervalSince(Date()) //time until end of the day
    }
    
    
    private func getCurrentBellSchedule() -> Schedule {
        let currentScheduleType:String = self.getScheduleType()
        
        let currentSchedule:Schedule = self.getScheduleFor(scheduleType: currentScheduleType)
        return currentSchedule
    }
    
    public func getCurrentPeriodLengthAsTimeInterval() -> TimeInterval { ///TODO: TEST/REWRITE
        var beginInterval:TimeInterval = 0.0
        var endInterval:TimeInterval = 0.0
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let endTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
//        let currentTimeAsInterval:TimeInterval = dateTester.timeIntervalSince(baseTime)

        
        let currentSchedule:Schedule = self.getCurrentBellSchedule()
        
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
        
//        print("End",endInterval)
//        print("Begin",beginInterval)
        
        return endInterval-beginInterval
    }
    
    private func getScheduleFor(scheduleType: String) -> Schedule {
        var resultSchedule:Schedule?
        for currentSchedule in allSchedules! {
            if currentSchedule.scheduleType.lowercased() == scheduleType.lowercased() {
                resultSchedule = currentSchedule
            }
        }
        return resultSchedule!
    }
    
    
    func isDateWithininSpecialDay (specialDay: SpecialDay) -> Bool {
        var now = Date() //Create date set to midnight on this date
        now = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
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
