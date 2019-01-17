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
    
//    private var doesCurrentDayHaveSpecialSchedule:Bool = false
    
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
    
    
    //This is the Struct that holds all the belltimes
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
        
        for specialDay in allSpecialDays! {
            //print ("Found A Special Day on: \(specialDay.beginDate)")
            
            if specialDay.endDate != nil {
               // print ("+++End Date:\(specialDay.endDate!)")
            }
            if specialDay.desc != nil {
               // print ("---Description:\(specialDay.desc!)")
            }
        }
        //*****************************************************
        
        //Bell Schedule Parser
        
        let pListURLBellSchedules: URL = mainBundle.url(forResource:"Schedules", withExtension:"plist")!
        
        if let data = try? Data(contentsOf: pListURLBellSchedules) {
            let decoder = PropertyListDecoder()
            allSchedules = try! decoder.decode(BellSchedules.self, from:data)
        }
        
        for schedule in allSchedules! {
            //print ("I know a schedule with the type:\(schedule.scheduleType)")
        }
        
        
        let normalSchedule: Schedule = allSchedules![0]
        
        let ringTimeBase = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        
        
        //printer (can be removed when finished)
        for bellTime in normalSchedule.bellTimes {
            let periodDescription = bellTime.desc
            let ringAdjust: TimeInterval = bellTime.timeInterval
            let periodRingTime:Date = ringTimeBase + ringAdjust
            
            //print ("\(periodDescription) Rings at:\(periodRingTime)")
        }
        
        //******************************************************
        
        //Default Schedule Parser
        
        //let mainBundle: Bundle = Bundle.main
        let plistURLDefaultDays: URL = mainBundle.url(forResource:"defaultSchedule", withExtension:"plist")!
        
        if let data = try? Data(contentsOf: plistURLDefaultDays) {
            let decoder = PropertyListDecoder()
            allDefaultDays = try! decoder.decode(AllDefaultDays.self, from:data)
        }
        
        let today = Calendar.current.component(.weekday, from:Date())
        
        for defaultDay in allDefaultDays! {
            if defaultDay.dayOfWeek.rawValue == today {
                defaultScheduleForToday = defaultDay.scheduleType
                //print ("Today's Schedule Type Is: \(defaultDay.scheduleType)")
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
        
        //print((theSpecialDay?.scheduleType)!)
        return (theSpecialDay?.scheduleType)!
        
    }

    
//    public func getFirstBellDescriptionForNextDay() -> String {
//        let calendar = Calendar.current
//        var date:Date = calendar.date(byAdding: .day, value: 1, to: Date())!
//        date = calendar.date(bySettingHour: 0, minute: 00, second: 0, of: date)!
//        return ""
//
//    }
    
    private let dateTester = Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
    
    public func getCurrentBellTimeDescription() -> String {
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        //let dateTester = Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
        
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
        //let dateTester = Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
        
        let currentSchedule:Schedule = self.getCurrentBellSchedule()
        
        let currentBellTimes:Array = currentSchedule.bellTimes
        
//        var currentBellTime:BellTime?
        for bellTime in currentBellTimes {
            if bellTime.timeInterval > currentTimeAsInterval {
                //print (bellTime.desc)
                return bellTime.desc
                //currentBellTime = bellTime
            }
        }
        
        if (calendar.component(.day, from: Date())>=7 && calendar.component(.month, from: Date()) == 6 || calendar.component(.month, from: Date()) > 6) { //7th day of 6th month (June)
            return "Summer!"
        } else if (calendar.component(.weekday, from: Date()) == 6){
            return "Weekend"
        }
        return "Free"
    }
    
    public func getTimeIntervalUntilNextEvent() -> TimeInterval {
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let endTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        //let dateTester = Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
        
        let currentSchedule:Schedule = self.getCurrentBellSchedule()
        
        let currentBellTimes:Array = currentSchedule.bellTimes
        
        for bellTime in currentBellTimes {
//            print("Current",currentTimeAsInterval)
//            print("Bell Time Interval",bellTime.timeInterval)
            if bellTime.timeInterval > currentTimeAsInterval {
                return bellTime.timeInterval - currentTimeAsInterval
            }
        }
        return endTime.timeIntervalSince(Date()) //time until end of the day
    }
    

    
    public func timerUntilNextEvent() -> Timer {
        let timeInterval:TimeInterval = getTimeIntervalUntilNextEvent()
        let eventTimer:Timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false)  {eventTimer in print("Timer fired!")}
        return eventTimer
    }
    
    //*************************************
    
    private func getCurrentBellSchedule() -> Schedule {
        let currentScheduleType:String = self.getScheduleType()
        
        let currentSchedule:Schedule = self.getScheduleFor(scheduleType: currentScheduleType)
        return currentSchedule
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
    //TODO: IMPLEMENT THESE IF NEEDED
    
//    private func getNextBellTime() -> BellTime { //given the current time and schedule type, return the next bell time object
//
//    }
//
    
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
