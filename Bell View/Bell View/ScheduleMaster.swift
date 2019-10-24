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

extension URLResponse {
    var serverEtag: String? {
        get {
            if let httpResp = self as? HTTPURLResponse, let etag = httpResp.allHeaderFields["Etag"] as? String {
                return etag
            }
            return nil
        }
    }
}

class ScheduleMaster {
    
/*
    ***ISSUES***
     -TODO: Testing
     -
*/
    
    
    private var loadStatesDict: [URL:Bool] = Dictionary(minimumCapacity: 3) //empty
    
    private var defaultScheduleForToday:String = ""
    private var defaultScheduleForNextDay:String = ""
    
    private final let SCHEDULES_URL: URL = URL(string: "https://bell-server.vapor.cloud/Schedules.plist")!
    private final let SPECIAL_DAYS_URL: URL = URL(string:"https://bell-server.vapor.cloud/specialDays.plist")!
    private final let DEFAULT_DAYS_URL: URL = URL(string:"https://bell-server.vapor.cloud/defaultSchedule.plist")!
    
    func setDefaultSchedule(){
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
    
    var isConnected:Bool = false
    
    var readyToContinueTimer:Timer = Timer()
    
    public var doneLoading:Bool = false
        
    
    let fileManager:FileManager  = FileManager()
    
    //Struct that holds all the belltimes
    struct Schedule: Decodable {
        var scheduleType: String
        let bellTimes: [BellTime]
    }
    
    func canContinue() -> Bool {
        for val in loadStatesDict.values{
            if (val == false) {
                return false;
            }
        }
        return true;
    }
    
    
    static let shared = ScheduleMaster() //SINGLETON
    
    private init () { //INITIALIZER
        clearEtagsIfNeeded()
        let plistSpecialDaysURL: URL = SPECIAL_DAYS_URL
        let plistBellSchedulesURL: URL = SCHEDULES_URL
        let plistDefaultDaysURL: URL = DEFAULT_DAYS_URL
        initDict()
        startLoad(urlToLoad: plistSpecialDaysURL)
        startLoad(urlToLoad: plistBellSchedulesURL)
        startLoad(urlToLoad: plistDefaultDaysURL)
        
        //****************************************************************************************************
        
        //Schedule Timer to check if the above network operations are done
        readyToContinueTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(readyToContinueTimerTriggered), userInfo: nil, repeats: true)
        
    }
    
    //New Method that's called by the timer to check load comnpletion
    @objc func readyToContinueTimerTriggered () {
        if (self.canContinue()) {
            self.readyToContinueTimer.invalidate()
            loadAllData()
        } else {
            return
        }
    }

    //************************************************************************************************************
    //************************************************************************************************************
    //************************************************************************************************************
    
    func initDict() {
        let plistSpecialDaysURL: URL = SPECIAL_DAYS_URL
        let pListBellSchedulesURL: URL = SCHEDULES_URL
        let plistDefaultDaysURL: URL = DEFAULT_DAYS_URL

        loadStatesDict.updateValue(false, forKey: plistSpecialDaysURL)
        loadStatesDict.updateValue(false, forKey: pListBellSchedulesURL)
        loadStatesDict.updateValue(false, forKey: plistDefaultDaysURL)
        
    }
    
    func readEtagFromPrefs(urlAbsString: String) -> String {
        let defaults = UserDefaults.standard
        
        if (defaults.string(forKey: urlAbsString) != nil) {
            
            //print("E-tag returned:" + defaults.string(forKey: urlAbsString)!)
            return defaults.string(forKey: urlAbsString)!
        }
        return "no-etag-exists"
    }
    
    func clearEtags(){
        let defaults = UserDefaults.standard
        let plistSpecialDaysURL: URL = SPECIAL_DAYS_URL
        let pListBellSchedulesURL: URL = SCHEDULES_URL
        let plistDefaultDaysURL: URL = DEFAULT_DAYS_URL
        
        defaults.removeObject(forKey: plistSpecialDaysURL.absoluteString)
        defaults.removeObject(forKey: pListBellSchedulesURL.absoluteString)
        defaults.removeObject(forKey: plistDefaultDaysURL.absoluteString)
    }
    
    func clearEtagsIfNeeded(){
        let defaults = UserDefaults.standard
        let expirationDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) //24 hours local expiraton date
        if (defaults.object(forKey: "expirationDate") == nil){
            self.clearEtags()
            defaults.set(expirationDate, forKey: "expirationDate") //nothing found, add expiration date
            print("Found no expiration date")
            
        } else if (Date() > defaults.object(forKey: "expirationDate") as! Date){
            self.clearEtags()
            defaults.set(expirationDate, forKey: "expirationDate")
            print("Passed expiration date")
        } else {
        
        if (fileManager.fileExists(atPath: getCacheURLToFile(fileName: "Schedules").path) == false){
            self.clearEtags()
            print("Schedules file didn't exist")
        }
        else if (fileManager.fileExists(atPath: getCacheURLToFile(fileName: "specialDays").path) == false){
            self.clearEtags()
            print("specialDays file didn't exist")
        }
        else if (fileManager.fileExists(atPath: getCacheURLToFile(fileName: "defaultSchedule").path) == false){
            self.clearEtags()
            print("defaultSchedule file didn't exist")
        }
    }
}
    
    
    func startLoad(urlToLoad: URL){
        isConnected = isConnectedToNetwork()

        var request = URLRequest(url: urlToLoad)
        
        //print(urlToLoad.absoluteString)
        
        let etagOfObjOnServer:String = readEtagFromPrefs(urlAbsString: urlToLoad.absoluteString)
        
        //print("E-tag returned:" + etagOfObjOnServer)

        request.setValue(etagOfObjOnServer, forHTTPHeaderField: "If-None-Match")
        
        //print("Request value:", request.value(forHTTPHeaderField: "If-None-Match"))
        
        print("*********************************************")
        let myURLSessionConfig = URLSessionConfiguration.ephemeral
        myURLSessionConfig.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        let myURLSession = URLSession.init(configuration: myURLSessionConfig)
        
        let task = myURLSession.dataTask(with: request) { data, response, error in
            
            if error != nil {
                
                DispatchQueue.main.async { //runs async
                    self.isConnected = false
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                    self.loadDataFor(url: urlToLoad)
                }
                return
            }
            
            let httpResponse = response as! HTTPURLResponse
            let status = httpResponse.statusCode
            
            
            print ("HTTP Status Code From Server:\(status)")
            
            if (200...299).contains(status) {
                
                
                print ("Downloaded Data With Status:\(status)")
                DispatchQueue.main.async { //runs async
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                    self.finishLoad(data: data!, urlForParse: urlToLoad, Etag: httpResponse.serverEtag)
                }
            }
            
            if status == 304 {
                print ("Got 304 - Not Modified")
                DispatchQueue.main.async { //run async
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                    self.loadDataFor(url: urlToLoad)
                }
                return
            }
            
            if (400...499).contains(status) || (500...599).contains(status) {
                
                DispatchQueue.main.async { //run async
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                    //self.isConnected = false;
                    self.loadDataFor(url: urlToLoad)
                }
                return
            }
            
            //print ("The e-Tag is:\(httpResponse.serverEtag!)")
            print("*********************************************")
        }
        task.resume()
        //print ("Task Executing...")
    }
    
    func finishLoad(data: Data, urlForParse: URL, Etag:String?){ //writes data to cache after getting new data
        let defaults = UserDefaults.standard

        let fileNamePlain:String = urlForParse.deletingPathExtension().lastPathComponent
        var filePath = getCachesDirectory().appendingPathComponent(fileNamePlain)
        filePath = filePath.appendingPathExtension("plist")

        
        let decoder = PropertyListDecoder()
        switch (fileNamePlain){ //assign each file name to correct structures
        case "specialDays": allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
            break
            
        case "defaultSchedule": allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
                setDefaultSchedule()
            break
            
        default : allSchedules = try! decoder.decode(BellSchedules.self, from:data)
            break
        }
        
        if (Etag != nil){
            defaults.set(Etag, forKey: urlForParse.absoluteString)
        }
        fileManager.createFile(atPath: filePath.path, contents: data)
    }
    
    
    func readLocalDataFor (plistURL: URL, fileNameFromURL:String) { //read the data out of the cache
        if let data = try? Data(contentsOf: plistURL) {
            let decoder = PropertyListDecoder()
            switch (fileNameFromURL){ //assign each file name to correct structures
            case "specialDays": self.allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
                break
                
            case "defaultSchedule": self.allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
            self.setDefaultSchedule()
                break //BREAK HERE
                
            default : self.allSchedules = try! decoder.decode(BellSchedules.self, from:data)
                break
            }
        }
    }
    

    
    //************************************************************************************************************
    //************************************************************************************************************
    //************************************************************************************************************
    
    func loadAllData(){
        let plistSpecialDaysURL: URL = SPECIAL_DAYS_URL
        let pListBellSchedulesURL: URL = SCHEDULES_URL
        let plistDefaultDaysURL: URL = DEFAULT_DAYS_URL
        
        loadDataFor(url: plistSpecialDaysURL)
        loadDataFor(url: pListBellSchedulesURL)
        loadDataFor(url: plistDefaultDaysURL)
        
        doneLoading = true
}
    
    func loadDataFor(url:URL){
        let mainBundle = Bundle.main
        
        //************************************************************************************************************************
        
        let fileNameFromKey:String = url.deletingPathExtension().lastPathComponent
        let pathToFileInCache:URL = self.getCacheURLToFile(fileName: fileNameFromKey)
        
        if let data = try? Data(contentsOf: pathToFileInCache) {
            let decoder = PropertyListDecoder()
            switch (fileNameFromKey){ //assign each file name to correct structures
            case "specialDays": allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
                break
                
            case "defaultSchedule": allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
                self.setDefaultSchedule()
                break
                
            default : allSchedules = try! decoder.decode(BellSchedules.self, from:data) //fall out and decode locally
                break
            }
            
            return
        }
        
        let localURL: URL = mainBundle.url(forResource:fileNameFromKey, withExtension:"plist")!
        
        if let data = try? Data(contentsOf: localURL) {
            let decoder = PropertyListDecoder()
            switch (fileNameFromKey){ //assign each file name to correct structures
            case "specialDays": allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
                break
                
            case "defaultSchedule": allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
                self.setDefaultSchedule()
                break
                
            default : allSchedules = try! decoder.decode(BellSchedules.self, from:data)
                break
            }
        } else {
            fatalError("Something VERY VERY bad happened and we were unable to load anything from cache or local bundle")
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
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        ret = (isReachable && !needsConnection)
        #endif
        
        
        return ret
    }
    
    
    
    func referenceDate() -> Date { //uses Jan 1, 2000 at midnight
        
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
        //print (paths[0]) //DEBUG TO GET PATHS
        return paths[0]
    }
    
    private func getCacheURLToFile (fileName:String) -> URL {
		var targetFileURL:URL = self.getCachesDirectory() //set up to be the path of all the directories
        targetFileURL.appendPathComponent(fileName) //append the file name (specify path)
        targetFileURL.appendPathExtension("plist") //all files are plist so append that
        
        return targetFileURL //return the fully qualified URL
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
                return defaultScheduleForNextDay
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
        

        if (specialDayDescIfApplicable(date: Date()) != ""){  //if the desc exsists
            return specialDayDescIfApplicable(date: Date()) //return the non-empty desc
        }
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())! //midnight of current date
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime) //convert to interval
        
        
        
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date()) //set Schedule object to current bell schedule
        
        let currentBellTimes:Array = currentSchedule.bellTimes //pull the associated bell times for the bellTimes
        
        var currentBellTime:BellTime?
        for bellTime in currentBellTimes { //loop through the bell times and find which one the current time is within
            if bellTime.timeInterval <= currentTimeAsInterval {
                currentBellTime = bellTime
            }
        }
        let description:String = (currentBellTime?.desc)! // set up the description from the found bell time and return it
        return description
    }
    
    
    public func getNextBellTimeDescription(date:Date) -> String {
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)! //midnight of current time
        let currentTimeAsInterval:TimeInterval = date.timeIntervalSince(baseTime) //convert to interval
        //        let currentTimeAsInterval:TimeInterval = dateTester.timeIntervalSince(baseTime) /***KEEP FOR TESTING***
        
        
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: date) //get the current schedule
        let currentBellTimes:Array = currentSchedule.bellTimes //make an array from that schedule
        
        
        for bellTime in currentBellTimes {
            if bellTime.timeInterval > currentTimeAsInterval { //loop until you find where the current time is, then return its description
                return bellTime.desc
            }
        }
        
        return getFirstBellDescriptionForNextDay() //otherwise, return the description for the next day
    }
    
    public func getTimeIntervalUntilNextEvent(isWeekend: Bool = false) -> TimeInterval { //isWeekend is a default parameter and is optionally passed
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())! //beginning of current day
        let endTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())! //end of current day
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
        //        let currentTimeAsInterval:TimeInterval = dateTester.timeIntervalSince(baseTime) //***KEEP FOR TESTING***
        
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date()) //get the current schedule
        
        let currentBellTimes:Array = currentSchedule.bellTimes //get the corresponding bell times
        
        for bellTime in currentBellTimes {
            if bellTime.timeInterval > currentTimeAsInterval {
                return bellTime.timeInterval - currentTimeAsInterval
            }
        }
        return endTime.timeIntervalSince(Date()) //time until end of the day
    }
    
    
    private func getBellScheduleFor(dateInput:Date) -> Schedule {
        let currentScheduleType:String = self.getScheduleType(myDate: dateInput)
        
        let currentSchedule:Schedule = self.getScheduleFor(scheduleType: currentScheduleType) //pass into method to get the current schedule
        return currentSchedule //return it
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
                beginInterval = bellTime.timeInterval //set the start interval that lies before
            }
        }
        
        for bellTime in currentBellTimes {
            if bellTime.timeInterval > currentTimeAsInterval {
                endInterval = bellTime.timeInterval //set the endc interval to the interval that lies after
                break
            }
        }
        
        if (endInterval == 0.0){ //if the current time is greater than any of the period start times the interval will still be 0
            return endTime.timeIntervalSince(baseTime)-beginInterval
        }
        
        return endInterval-beginInterval //return the difference which is the length of the period
    }
    
    private func getScheduleFor(scheduleType: String) -> Schedule {
        //print("XXXX"+scheduleType)
        var resultSchedule:Schedule?
        for currentSchedule in allSchedules! { //iterate through the schedules to find
            if currentSchedule.scheduleType == scheduleType { //if the found during iteration equals the type, set the result and return it
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
        var schedulesArray:Array<String> = [] //init array
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date()) //init current schedule
        
        let currentBellTimes:Array = currentSchedule.bellTimes //init
        if (currentSchedule.bellTimes.count > 1){
            for bellSchedule in currentBellTimes {
                schedulesArray += ["\(bellSchedule.desc) - " + "\(stringFromTimeInterval(interval: bellSchedule.timeInterval, is12Hour: true, useSeconds: false))"] //build the sting for the table cell view
            }
        } else if (currentSchedule.bellTimes.count <= 1){
            if (specialDayDescIfApplicable(date: Date()) != ""){ //if only 1 schedule or less, check the special days then just return the array as it only has one description
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
        var beginDate:Date  = specialDay.beginDate //guaranteed
        beginDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: beginDate)!
        var endDate: Date? = specialDay.endDate //try this
        if endDate != nil { //if the special day has no end date, set it to the beginnng of the day
            endDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: endDate!)!
        }
        var inRange:Bool = false //init
        
        if now == beginDate {
            inRange = true
        }
        
        if endDate != nil { //if end date exists for the current date...
            if now == endDate {
                inRange = true
            } else if now > beginDate && now < endDate! {
                inRange = true
            } //see if the current Date is in range
        }
        
        return inRange
    }
}
