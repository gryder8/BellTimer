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
     -Unable to push to remote GitHub due to local instance being out of date
     -
*/
    
    
    private var loadStatesDict: [URL:Bool] = Dictionary(minimumCapacity: 3) //empty
    
    private var defaultScheduleForToday:String = ""
    private var defaultScheduleForNextDay:String = ""
    
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
    
    var doneLoading = false
    
    let fileManager:FileManager  = FileManager()
    
    //Struct that holds all the belltimes
    struct Schedule: Decodable {
        var scheduleType: String
        let bellTimes: [BellTime]
    }
    
    func canContinue() -> Bool {
        for val in loadStatesDict.values{
            if (val == false){
                return false;
            }
        }
        return true;
    }
    
    
    static let shared = ScheduleMaster() //SINGLETON
    
    private init () { //INITIALIZER
        loadFromServerIfNeeded()
        let plistSpecialDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/specialDays.plist")!
        let plistBellSchedulesURL: URL = URL(string: "https://hello-swryder-staging.vapor.cloud/Schedules.plist")!
        //let plistBellSchedulesURL: URL = URL(string: "http://192.168.7.43/Schedules.plist")!
        let plistDefaultDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/defaultSchedule.plist")!//
        initDict()
        startLoad(urlToLoad: plistSpecialDaysURL)
        startLoad(urlToLoad: plistBellSchedulesURL)
        startLoad(urlToLoad: plistDefaultDaysURL)
        
        //****************************************************************************************************
        
        //Schedule Timer to check if the above network operations are done
        readyToContinueTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(readyToContinueTimerTriggered), userInfo: nil, repeats: true)
        
    }
    
    
    //New Method that's called byh the timer (takes the timer as an argument passed into it)
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
        let plistSpecialDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/specialDays.plist")!
        let pListBellSchedulesURL: URL = URL(string: "https://hello-swryder-staging.vapor.cloud/Schedules.plist")!
        //let pListBellSchedulesURL: URL = URL(string: "http://192.168.7.43/Schedules.plist")!
        let plistDefaultDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/defaultSchedule.plist")!

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
        let plistSpecialDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/specialDays.plist")!
        let pListBellSchedulesURL: URL = URL(string: "https://hello-swryder-staging.vapor.cloud/Schedules.plist")!
        let plistDefaultDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/defaultSchedule.plist")!
        
        defaults.removeObject(forKey: plistSpecialDaysURL.absoluteString)
        defaults.removeObject(forKey: pListBellSchedulesURL.absoluteString)
        defaults.removeObject(forKey: plistDefaultDaysURL.absoluteString)
    }
    
    func loadFromServerIfNeeded(){
        let defaults = UserDefaults.standard
        let expirationDate = Calendar.current.date(byAdding: .hour, value: 12, to: Date())
        if (defaults.object(forKey: "expirationDate") == nil){
            clearEtags()
            defaults.set(expirationDate, forKey: "expirationDate")
            print("Found no expiration date")
            
        } else if (Date() > defaults.object(forKey: "expirationDate") as! Date){
            clearEtags()
            defaults.set(expirationDate, forKey: "expirationDate")
            print("Passed expiration date")
        } else {
        
        if (fileManager.fileExists(atPath: getCacheURLToFile(fileName: "Schedules").path) == false){
            
            self.clearEtags()
            //print(getCacheURLToFile(fileName: "Schedules"))
            print(getCacheURLToFile(fileName: "Schedules").path)
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
    
    
    func startLoad(urlToLoad: URL){ //FIX: 304 IS NEVER RETURNED
        // let fileNameFromLoadURL:String = urlToLoad.deletingPathExtension().lastPathComponent

        isConnected = isConnectedToNetwork()

        var request = URLRequest(url: urlToLoad)
        
        //print(urlToLoad.absoluteString)
        
        let etagOfObjOnServer:String = readEtagFromPrefs(urlAbsString: urlToLoad.absoluteString)
        
        //print("E-tag returned:" + etagOfObjOnServer)

        //request.setValue("dogisgreat", forHTTPHeaderField: "If-None-Match")
        request.setValue(etagOfObjOnServer, forHTTPHeaderField: "If-None-Match")
        
        //print("URL:", urlToLoad.absoluteString)
        //print("Request value:", request.value(forHTTPHeaderField: "If-None-Match"))
        
        print("*********************************************")
        let myURLSessionConfig = URLSessionConfiguration.ephemeral
        myURLSessionConfig.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        let myURLSession = URLSession.init(configuration: myURLSessionConfig)
        
        let task = myURLSession.dataTask(with: request) { data, response, error in
            
            //print ("...Task Executed")
            
            if error != nil {
                
                DispatchQueue.main.sync {
                    self.isConnected = false
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                    self.loadDataFor(url: urlToLoad)
                }
                return
            }
            
            let httpResponse = response as! HTTPURLResponse
            let status = httpResponse.statusCode
            
            //print(request.description)
            //print(request.allHTTPHeaderFields)
            
            print ("HTTP Status Code From Server:\(status)")
            
            //print("Length", httpResponse.contentLength)
            
            if (200...299).contains(status) {
                
                
                //print("Data from", urlToLoad.absoluteString)
                 print ("Downloaded Data With Status:\(status)")
                DispatchQueue.main.async {
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                    self.finishLoad(data: data!, urlForParse: urlToLoad, Etag: httpResponse.serverEtag)
                }
            }
            
            if status == 304 {
                print ("Got 304 - Not Modified")
                //let plistURL: URL = self.searchForFileFromCache(fileName: fileNameFromLoadURL)!
                DispatchQueue.main.sync {
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                    self.loadDataFor(url: urlToLoad)
                }
                //self.readLocalDataFor(plistURL: plistURL, fileNameFromURL: fileNameFromLoadURL)

                return
            }
            
            if (400...499).contains(status) || (500...599).contains(status) {
                
                DispatchQueue.main.sync {
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                    //self.isConnected = false;
                    self.loadDataFor(url: urlToLoad)
                }
                return
            }
            
            //print ("The e-Tag is:\(httpResponse.serverEtag!)")
            print("*********************************************")

            
//            DispatchQueue.main.async {
//                self.finishLoad(data: data!, urlForParse: urlToLoad, Etag: httpResponse.serverEtag)
//            }
        }
        task.resume()
        //print ("Task Executing...")
    }
    
    func finishLoad(data: Data, urlForParse: URL, Etag:String?){ //writes data to cache when getting new data
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
    
    
    func readLocalDataFor (plistURL: URL, fileNameFromURL:String){
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
        let plistSpecialDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/specialDays.plist")!
        let pListBellSchedulesURL: URL = URL(string: "https://hello-swryder-staging.vapor.cloud/Schedules.plist")!
        //let pListBellSchedulesURL: URL = URL(string: "http://192.168.7.43/Schedules.plist")!
        let plistDefaultDaysURL: URL = URL(string:"https://hello-swryder-staging.vapor.cloud/defaultSchedule.plist")!
        
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
                
            default : allSchedules = try! decoder.decode(BellSchedules.self, from:data)
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
            fatalError("Something VERY VERY bad happend and we were unable to load anything from cache or bundle")
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
        //print (paths[0]) //DEBUG TO GET PATHS
        return paths[0]
    }
    
    private func getCacheURLToFile (fileName:String) -> URL {
        var targetFile:URL = getCachesDirectory()
        targetFile.appendPathComponent(fileName)
        targetFile.appendPathExtension("plist")
        
        return targetFile
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
        //print("XXXX"+scheduleType)
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
