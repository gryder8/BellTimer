//
//  ScheduleMaster.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/14/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

import UIKit
import Foundation
#if os(iOS)
import SystemConfiguration
#endif

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
    
    let fileManager:FileManager  = FileManager()
    
    //Struct that holds all the belltimes
    struct Schedule: Decodable {
        var scheduleType: String
        let bellTimes: [BellTime]
    }
    
    
    init (mainBundle: Bundle) {
     loadData()
    }
    
    //************************************************************************************************************
    //************************************************************************************************************
    //************************************************************************************************************
 
    
    func loadData(){
        let mainBundle = Bundle.main
        
        //*** SETUP ***
        
        //print(isConnectedToNetwork())
        let expirationDate = Calendar.current.date(byAdding: .hour, value: 12, to: Date())
        //let expirationDate = Calendar.current.date(byAdding: .second, value: 5, to: Date()) //DEBUG USE
        
        let refDate:Date = referenceDate() //Y2K
        let timeDiff: TimeInterval = expirationDate!.timeIntervalSince(refDate)
        
        //************************************************************************************************************************
        
        
        //Parser for Special Days
        
        if (isConnectedToNetwork()) {
            //print(Date().timeIntervalSince(referenceDate()))
            let specialDaysFileName: String = "specialDays#\(timeDiff)" //adds a specified file with a time interval for checking expiration
            let specialDaysFilePath = getCachesDirectory().appendingPathComponent(specialDaysFileName)
            deleteExpiredFiles()
            
            
            if (searchForFileFromCache(fileName: "specialDays") == nil) {
                do {
                    let plistSpecialDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/specialDays.plist")!
                    if let data = try? Data(contentsOf: plistSpecialDaysURL) {
                        let decoder = PropertyListDecoder()
                        allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
                    }
                    try fileManager.createFile(atPath: specialDaysFilePath.path, contents: Data(contentsOf: plistSpecialDaysURL))
                } catch {
                    print("Fatal file writing error!!")
                }
                
            } else {
                let plistURLSpecialDays: URL = searchForFileFromCache(fileName: "specialDays")!
                if let data = try? Data(contentsOf: plistURLSpecialDays) {
                    let decoder = PropertyListDecoder()
                    allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
                }
            }
            
            //no connection, so check the cache and then write from the local data if no cached file exists
        } else {
            if (searchForFileFromCache(fileName: "specialDays") == nil){
                let plistURLSpecialDays: URL = mainBundle.url(forResource:"specialDays", withExtension:"plist")!
                if let data = try? Data(contentsOf: plistURLSpecialDays) {
                    let decoder = PropertyListDecoder()
                    allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
                }
            } else {
                let plistURLSpecialDays: URL = searchForFileFromCache(fileName: "specialDays")!
                if let data = try? Data(contentsOf: plistURLSpecialDays) {
                    let decoder = PropertyListDecoder()
                    allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
                }
            }
        }
        
        //*****************************************************
        //*****************************************************
        //*****************************************************
        
        //Bell Schedule Parser
        if (isConnectedToNetwork()) {
            
            
            let bellScheduleFileName: String = "Schedules#\(timeDiff)" //adds a specified file with a time interval for checking expiration
            let bellScheduleFilePath = getCachesDirectory().appendingPathComponent(bellScheduleFileName)
            deleteExpiredFiles()
            
            
            if (searchForFileFromCache(fileName: "Schedules") == nil) {
                do {
                    let pListBellSchedulesURL: URL = URL(string: "https://hello-swryder-staging.vapor.cloud/Schedules.plist")!
                    if let data = try? Data(contentsOf: pListBellSchedulesURL) {
                        let decoder = PropertyListDecoder()
                        allSchedules = try! decoder.decode(BellSchedules.self, from:data)
                    }
                    try fileManager.createFile(atPath: bellScheduleFilePath.path, contents: Data(contentsOf: pListBellSchedulesURL))
                } catch {
                    print("Fatal file writing error!!")
                }
            } else {
                let pListBellSchedulesURL: URL = searchForFileFromCache(fileName: "Schedules")!
                if let data = try? Data(contentsOf: pListBellSchedulesURL) {
                    let decoder = PropertyListDecoder()
                    allSchedules = try! decoder.decode(BellSchedules.self, from:data)
                }
            }
            
            //no connection, so check the cache and then write from the local data if no cached file exists
        } else {
            if (searchForFileFromCache(fileName: "Schedules") == nil){
                let pListBellSchedulesURL: URL = mainBundle.url(forResource:"Schedules", withExtension:"plist")!
                if let data = try? Data(contentsOf: pListBellSchedulesURL) {
                    let decoder = PropertyListDecoder()
                    allSchedules = try! decoder.decode(BellSchedules.self, from:data)
                }
            } else {
                let pListBellSchedulesURL: URL = searchForFileFromCache(fileName: "Schedules")!
                if let data = try? Data(contentsOf: pListBellSchedulesURL) {
                    let decoder = PropertyListDecoder()
                    allSchedules = try! decoder.decode(BellSchedules.self, from:data)
                }
            }
        }
        
        
        //******************************************************
        //******************************************************
        //******************************************************
        
        //Default Schedule Parser
        if (isConnectedToNetwork()){
            
            
            let defaultScheduleFileName: String = "defaultSchedule#\(timeDiff)" //adds a specified file with a time interval for checking expiration
            let defaultFilePath = getCachesDirectory().appendingPathComponent(defaultScheduleFileName)
            deleteExpiredFiles()
            
            if (searchForFileFromCache(fileName: "defaultSchedule") == nil) {
                do {
                    let plistDefaultDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/defaultSchedule.plist")! //TODO: Handle no internet
                    if let data = try? Data(contentsOf: plistDefaultDaysURL) {
                        let decoder = PropertyListDecoder()
                        allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
                    }
                    try fileManager.createFile(atPath: defaultFilePath.path, contents: Data(contentsOf: plistDefaultDaysURL))
                } catch {
                    print("Fatal file writing error!!")
                }
                
            } else {
                let plistURLDefaultDays: URL = searchForFileFromCache(fileName: "defaultSchedule")!
                if let data = try? Data(contentsOf: plistURLDefaultDays) {
                    let decoder = PropertyListDecoder()
                    allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
                }
            }
            
            //no connection, so check the cache and then write from the local data if no cached file exists
        } else {
            if (searchForFileFromCache(fileName: "defaultSchedule") == nil) {
                let plistURLDefaultDays: URL = mainBundle.url(forResource:"defaultSchedule", withExtension:"plist")!
                if let data = try? Data(contentsOf: plistURLDefaultDays) {
                    let decoder = PropertyListDecoder()
                    allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
                }
            } else {
                let plistURLDefaultDays: URL = searchForFileFromCache(fileName: "defaultSchedule")!
                if let data = try? Data(contentsOf: plistURLDefaultDays) {
                    let decoder = PropertyListDecoder()
                    allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
                }
            }
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
    
    //************************************************************************************************************************
    //************************************************************************************************************************
    //************************************************************************************************************************
    //************************************************************************************************************************
    //************************************************************************************************************************

    
    public func isConnectedToNetwork() -> Bool { //uses SystemConfiguration
        
        var ret:Bool = true
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        
        
        #if os(iOS)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        /* Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         
         return isReachable && !needsConnection
         */
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        ret = (isReachable && !needsConnection)
        #endif
        
        
        return ret
    }
    
    
    
    func referenceDate() -> Date { //uses Jan 1, 2000 at midnight (Y2K)
        
        var Y2K:Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        Y2K = Calendar.current.date(bySetting: .month, value: 1, of: Y2K)!
        Y2K = Calendar.current.date(bySetting: .day, value: 1, of: Y2K)!
        var component = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Y2K)
        component.year = 2000
        Y2K = Calendar.current.date(from: component)!
        return Y2K;
    }
    
    
    private func getCachesDirectory() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func searchForFileFromCache (fileName: String) -> URL? {
        let cacheDirectory:URL = getCachesDirectory()
        var contentsOfCache: [URL] = []
        do {
            contentsOfCache = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
        } catch {
            print("Cache directory listing failed!")
        }
        
        for currentURL in contentsOfCache {
            let nameInCache:String? = String(currentURL.lastPathComponent.split(separator: "#").first ?? "")
            if (nameInCache == ""){
                print ("Bad description value!")
            }
            if (fileName == nameInCache){
                return currentURL;
            }
        }
        return nil
    }
    
    func deleteExpiredFiles(){
        let cacheDirectory:URL = getCachesDirectory()
        var contentsOfCache: [URL] = []
        do {
            contentsOfCache = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants])
        } catch {
            print("Cache directory listing failed!")
        }
        
        for currentURL in contentsOfCache {
            let timeValue:String? = String(currentURL.lastPathComponent.split(separator: "#").last ?? "")
            let firstHalf: String? = String(timeValue!.split(separator: ".").first ?? "")
            if (CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: firstHalf!))) {
                let expireInterval: TimeInterval = Double(timeValue!)! //TODO: Brittle code!!!!
                let expireDate: Date  = Date(timeInterval: expireInterval, since: referenceDate())
                if (Date().timeIntervalSince(expireDate) > 0){
                    do {
                        try fileManager.removeItem(at: currentURL)
                    } catch {
                        print("File removal error!")
                    }
                }
            }
            if (timeValue == ""){
                print ("Bad time value!")
            }
            
        }
    }
    
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
            if bellTime.timeInterval > currentTimeAsInterval { //TODO: passing a sim Monday is returning "Free"
                return bellTime.desc
            }
        }
        
        return getFirstBellDescriptionForNextDay()
    }
    
    public func getTimeIntervalUntilNextEvent(isWeekend: Bool = false) -> TimeInterval { //isWeekend is a default parameter and is optionally passed
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
        return resultSchedule!
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
