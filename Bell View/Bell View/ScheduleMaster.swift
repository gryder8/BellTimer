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
     -TODO: Comment code
     -
*/
    
    
    private var loadStatesDict: [URL:Bool] = Dictionary(minimumCapacity: 3) //init empty dict of capacity 3
    
    private var defaultScheduleForToday:String = ""
    private var defaultScheduleForNextDay:String = ""
    
	//MARK: Server URLs!
    private final let SCHEDULES_URL: URL = URL(string: "https://rydermegastore.synology.me:8999/Schedules.plist")!
    private final let SPECIAL_DAYS_URL: URL = URL(string:"https://rydermegastore.synology.me:8999/specialDays.plist")!
    private final let DEFAULT_DAYS_URL: URL = URL(string:"https://rydermegastore.synology.me:8999/defaultSchedule.plist")!
    
	
    func setDefaultSchedule(){
        let today = Calendar.current.component(.weekday, from:Date())
        let nextDayDateHolder = calendar.date(byAdding: .day, value: 1, to: Date())! //hold the next day (used to get the weekday from
        let nextDay = Calendar.current.component(.weekday, from:nextDayDateHolder) //get the next day
        for defaultDay in allDefaultDays! {
            if defaultDay.dayOfWeek.rawValue == today { //if the day of the week of the default day is the same as today, assign the default schedule for today to be the one contained by defaultDay
                defaultScheduleForToday = defaultDay.scheduleType //schedule type defines schedule to get
            }
            if defaultDay.dayOfWeek.rawValue == nextDay { //if the day of the week of the default day is the same as the next day, assign the default schedule of the next day to be the current schedule of the next day
                defaultScheduleForNextDay = defaultDay.scheduleType //schedule type defines schedule to get
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
    
    typealias AllSpecialDays = [SpecialDay] //provide an alias to reference the array of objects from
    
    var allSpecialDays: AllSpecialDays?
    
    typealias BellSchedules = [Schedule]  //provide an alias to reference the array of objects from
    
    var allSchedules: BellSchedules?
    
    typealias AllDefaultDays = [DefaultDay]  //provide an alias to reference the array of objects from
    
    var allDefaultDays: AllDefaultDays?
    
    var isConnected:Bool = false
    
    var readyToContinueTimer:Timer = Timer()
    
    public var doneLoading:Bool = false
        
    
    let fileManager:FileManager = FileManager()
    
    //Struct that holds all the belltimes
    struct Schedule: Decodable {
        var scheduleType: String
        let bellTimes: [BellTime]
    }
    
    func canContinue() -> Bool {
        for val in loadStatesDict.values {
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
    
    //method that's called by the timer to check load completion
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
    
    func initDict() { //initialize all URLs as unloaded
        let plistSpecialDaysURL: URL = SPECIAL_DAYS_URL
        let pListBellSchedulesURL: URL = SCHEDULES_URL
        let plistDefaultDaysURL: URL = DEFAULT_DAYS_URL

        loadStatesDict.updateValue(false, forKey: plistSpecialDaysURL)
        loadStatesDict.updateValue(false, forKey: pListBellSchedulesURL)
        loadStatesDict.updateValue(false, forKey: plistDefaultDaysURL)
        
    }
    
	//MARK: Etag config methods
    func readEtagFromPrefs(urlAbsString: String) -> String {
        let defaults = UserDefaults.standard
        
        if (defaults.string(forKey: urlAbsString) != nil) {
            
            //print("E-tag returned:" + defaults.string(forKey: urlAbsString)!)
            return defaults.string(forKey: urlAbsString)!
        }
        return "no-etag-exists"
    }
    
    func clearEtags(){ //clears the etags by removing values from the dictionary with the specified URLs
        let defaults = UserDefaults.standard
        let plistSpecialDaysURL: URL = SPECIAL_DAYS_URL
        let pListBellSchedulesURL: URL = SCHEDULES_URL
        let plistDefaultDaysURL: URL = DEFAULT_DAYS_URL
        
        defaults.removeObject(forKey: plistSpecialDaysURL.absoluteString)
        defaults.removeObject(forKey: pListBellSchedulesURL.absoluteString)
        defaults.removeObject(forKey: plistDefaultDaysURL.absoluteString)
    }
    
    func clearEtagsIfNeeded(){ //determine if the e-tags need to be cleared
        let defaults = UserDefaults.standard
        let expirationDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) //24 hours local expiraton date
        if (defaults.object(forKey: "expirationDate") == nil){ //no expiration date found in saved data
            self.clearEtags()
            defaults.set(expirationDate, forKey: "expirationDate") //nothing found, add expiration date
            print("Found no expiration date")
            
        } else if (Date() > defaults.object(forKey: "expirationDate") as! Date){ //if the current date is past the expiration date written in the saved data
            self.clearEtags()
            defaults.set(expirationDate, forKey: "expirationDate")
            print("Passed expiration date")
        } else { //check to see if the files exsist and if not then clear the etags in preparaation to fetch the files from the server
			if (fileManager.fileExists(atPath: getCacheURLToFile(fileName: "Schedules").path) == false) {
				self.clearEtags()
				print("Schedules file didn't exist")
			} else if (fileManager.fileExists(atPath: getCacheURLToFile(fileName: "specialDays").path) == false) {
            self.clearEtags()
            print("specialDays file didn't exist")
			} else if (fileManager.fileExists(atPath: getCacheURLToFile(fileName: "defaultSchedule").path) == false) {
				self.clearEtags()
				print("defaultSchedule file didn't exist")
			}
    }
}
    
    
	//MARK: Data loader methods
    func startLoad(urlToLoad: URL){ //load from server
        isConnected = isConnectedToNetwork()

        var request = URLRequest(url: urlToLoad)
        
        //print(urlToLoad.absoluteString)
        
        let etagOfObjOnServer:String = readEtagFromPrefs(urlAbsString: urlToLoad.absoluteString)
        
        //print("E-tag returned:" + etagOfObjOnServer)

        request.setValue(etagOfObjOnServer, forHTTPHeaderField: "If-None-Match")
        
        //print("Request value:", request.value(forHTTPHeaderField: "If-None-Match"))
        
        //print("*********************************************")
        let myURLSessionConfig = URLSessionConfiguration.ephemeral //config the session
        myURLSessionConfig.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData //do not use cached data from the URL to satisfy the request
        let myURLSession = URLSession.init(configuration: myURLSessionConfig)
        
        let task = myURLSession.dataTask(with: request) { data, response, error in //create a task to handle fetching data and take an error in
            
            if error != nil { //if no error occurs
                
                DispatchQueue.main.async { //runs async
                    self.isConnected = false
                    self.loadDataFor(url: urlToLoad)
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                }
                return
            }
            
            let httpResponse = response as! HTTPURLResponse //get the status and use to determine whether data should be loaded
            let status = httpResponse.statusCode
            
            
            //print ("HTTP Status Code From Server:\(status)")
            
            if (200...299).contains(status) { //range contains status
                
                
                //print ("Downloaded Data With Status:\(status)")
                DispatchQueue.main.async { //runs async
                    self.finishLoad(data: data!, urlForParse: urlToLoad, Etag: httpResponse.serverEtag)
					self.loadStatesDict.updateValue(true, forKey: urlToLoad)
                }
            }
            
            if status == 304 { //no changes
                //print ("Got 304 - Not Modified")
                DispatchQueue.main.async { //run async
                    self.loadDataFor(url: urlToLoad) //load data for the current url
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad) //set the current url as loaded in the dict

                }
                return
            }
            
            if (400...499).contains(status) || (500...599).contains(status) {
                
                DispatchQueue.main.async { //run async
                    self.isConnected = false;
                    self.loadDataFor(url: urlToLoad)
                    self.loadStatesDict.updateValue(true, forKey: urlToLoad)

                }
                return
            }
            
            //print ("The e-Tag is:\(httpResponse.serverEtag!)")
            print("*********************************************")
        }
        task.resume()
        //print ("Task Executing...")
    }
    
    func finishLoad(data: Data, urlForParse: URL, Etag:String?){ //writes data to cache after getting new data from the server
        let defaults = UserDefaults.standard

        let fileNamePlain:String = urlForParse.deletingPathExtension().lastPathComponent //get the file name by getting the last componenent and pulling the file extension off it
		
        var filePath = getCachesDirectory().appendingPathComponent(fileNamePlain) //generate the file name by getting the caches and appending the file name as the directory in which data will be cached [STANDARDIZED]
        filePath = filePath.appendingPathExtension("plist") //add the plist extension

        
        let decoder = PropertyListDecoder() //init decoder to decode data from plists
        switch (fileNamePlain){ //assign each file name to correct structures
        case "specialDays": allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
            break
            
        case "defaultSchedule": allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
                setDefaultSchedule()
            break
            
        default : allSchedules = try! decoder.decode(BellSchedules.self, from:data)
            break
        }
        
        if (Etag != nil){ //if the etag exists, update the most recent etag recorded for the url being loaded
            defaults.set(Etag, forKey: urlForParse.absoluteString)
        }
        fileManager.createFile(atPath: filePath.path, contents: data) //put the data into a file in the cache
    }
    
    
    func readLocalDataFor (plistURL: URL, fileNameFromURL:String) { //read the data out of the cache (NOT THE BUNDLE!)
        if let data = try? Data(contentsOf: plistURL) {
            let decoder = PropertyListDecoder() //init decoder
            switch (fileNameFromURL){ //assign each file name to correct structures when decoding from the cache
            case "specialDays": self.allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data)
                break
                
            case "defaultSchedule": self.allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data)
            self.setDefaultSchedule()
                break //BREAK HERE
                
            default : self.allSchedules = try! decoder.decode(BellSchedules.self, from:data) //final case
                break
            }
        }
    }
    

    
    //************************************************************************************************************
    //************************************************************************************************************
    //************************************************************************************************************
    
    func loadAllData(){ //load all data for the 3 URLs
        let plistSpecialDaysURL: URL = SPECIAL_DAYS_URL
        let pListBellSchedulesURL: URL = SCHEDULES_URL
        let plistDefaultDaysURL: URL = DEFAULT_DAYS_URL
        
        loadDataFor(url: plistSpecialDaysURL)
        loadDataFor(url: pListBellSchedulesURL)
        loadDataFor(url: plistDefaultDaysURL)
        
        doneLoading = true
}
    
    func loadDataFor(url:URL){ //loads data for a specified URL, first trying to load it from the cache then reverting to the local bundle if no data ia found in the cache
        let mainBundle = Bundle.main
        
        //************************************************************************************************************************
        
		
		//decodes data from the cache (NOTE: if this fails because the cache is empty, data is loaded from the local bundle files provided with the app)
        let fileNameFromURL:String = url.deletingPathExtension().lastPathComponent //grab the last part of the path and remove the extemnsion; use this as the file name
        let pathToFileInCache:URL = self.getCacheURLToFile(fileName: fileNameFromURL) //get the fully qualified path
        
        if let data = try? Data(contentsOf: pathToFileInCache) { //try to decode from the data in the cache (use Data to look for data at the location in the cache)
            let decoder = PropertyListDecoder()
            switch (fileNameFromURL){ //assign each file name to correct structures
			case "specialDays": allSpecialDays = try! decoder.decode(AllSpecialDays.self, from:data) //decode from local data
                break
                
            case "defaultSchedule": allDefaultDays = try! decoder.decode(AllDefaultDays.self, from: data) //decode from local data
                self.setDefaultSchedule()
                break
                
            default : allSchedules = try! decoder.decode(BellSchedules.self, from:data) //fall out and decode locally
                break
            }
            
            return
        }
        
        let localURL: URL = mainBundle.url(forResource:fileNameFromURL, withExtension:"plist")! //find the local url for a given file name to pull data from the local files in the bundle
        
		//decode data from the plists installed with the app (emergency fallback)
        if let data = try? Data(contentsOf: localURL) {
            let decoder = PropertyListDecoder()
            switch (fileNameFromURL){ //assign each file name to correct structures
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
    
    //********************************************************************************************************************************************************
    //********************************************************************************************************************************************************
    //********************************************************************************************************************************************************
    //********************************************************************************************************************************************************
    //********************************************************************************************************************************************************

    
    public func isConnectedToNetwork() -> Bool { //uses SystemConfiguration which is only loaded when on iOS
		//courtesy StackOverflow
        
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
        
		//configures the referencee date
        var Y2K:Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        Y2K = Calendar.current.date(bySetting: .month, value: 1, of: Y2K)!
        Y2K = Calendar.current.date(bySetting: .day, value: 1, of: Y2K)!
        var component = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Y2K)
        component.year = 2000
        Y2K = Calendar.current.date(from: component)!
        return Y2K;
    }
    
    
    private func getCachesDirectory() -> URL { //return the cache directory
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask) //get the caches from the file manager
        //print (paths[0]) //DEBUG TO GET PATHS
        return paths[0] //choose the first (and only?) path
    }
    
    private func getCacheURLToFile (fileName:String) -> URL {
		var targetFileURL:URL = self.getCachesDirectory() //set up to be the path of all the directories
        targetFileURL.appendPathComponent(fileName) //append the file name (specify path)
        targetFileURL.appendPathExtension("plist") //all files are plist so append that
        
        return targetFileURL //return the fully qualified URL
    }
    
    
    //MARK: Schedule setup
    public func getScheduleType(dateInput:Date) -> String {
        let startOfCurrentDay = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())! //reset the hours min and sec of the date so it can be accurately compared
		var inputDate = dateInput
        inputDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: dateInput)! //reset the hours min and sec of the date so it can be accurately compared
        var theSpecialDay: SpecialDay? //null var to hold day if found
        for canidateSpecialDay in allSpecialDays!{ //look through array to see if the date is in range of a special day
            if self.isDateWithininSpecialDay(specialDay: canidateSpecialDay, dateInput: dateInput) {
                theSpecialDay = canidateSpecialDay
            }
        }
        
        if (theSpecialDay == nil){ //no special day found
            if (startOfCurrentDay == inputDate) {
                return defaultScheduleForToday
            } else {
                return defaultScheduleForNextDay
            }
        }
        
        return (theSpecialDay?.scheduleType)!
        
    }
    
    
    public func getFirstBellDescriptionForNextDay() -> String { //get the next bell description by using a forwarded date and passing it to the appropriate methods
        let calendar = Calendar.current
        var forwardedDate:Date = calendar.date(byAdding: .day, value: 1, to: Date())!
        forwardedDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: forwardedDate)!
        if (specialDayDescIfApplicable(date: forwardedDate) != ""){ //check for it being a special day
            return specialDayDescIfApplicable(date: forwardedDate)
        }
        
        return getNextBellTimeDescription(date: forwardedDate)
    }
    
    //private let dateTester = Calendar.current.date(bySettingHour: 16, minute: 00, second: 0, of: Date())!
    
    private func specialDayDescIfApplicable(date:Date) -> String {
        for canidateSpecialDay in allSpecialDays! {
            if self.isDateWithininSpecialDay(specialDay: canidateSpecialDay, dateInput: date) {
                if canidateSpecialDay.desc != nil { //make sure it exsists before returning it; if it doesn't, an empty string is returned
                    return canidateSpecialDay.desc!
				}
            }
        }
        return "" //no description found
    }
    
    public func getCurrentPeriodStartTimeInterval() -> TimeInterval {
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let currentTimeAsInterval:TimeInterval = Date().timeIntervalSince(baseTime)
        
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date()) //get the current schedule
        let currentBellTimes:Array = currentSchedule.bellTimes //setup the current times
        var currentBellTime:BellTime? //init holder variable
        for bellTime in currentBellTimes {
            if bellTime.timeInterval <= currentTimeAsInterval { //walk up the array until this is false, then drop out and return the time interval associated with the last bell time that met this condition
                currentBellTime = bellTime
            }
        }
		
        return (currentBellTime?.timeInterval)! //pull out the time interval from the bell time the loop got to
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
		let currentScheduleType:String = self.getScheduleType(dateInput: dateInput)
        
        let currentSchedule:Schedule = self.getScheduleFor(scheduleType: currentScheduleType) //pass into method to get the current schedule
        return currentSchedule //return it
    }
    
    public func getCurrentPeriodLengthAsTimeInterval() -> TimeInterval {
        var beginInterval:TimeInterval = 0.0
        var endInterval:TimeInterval = 0.0
        let baseTime  = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let endTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())! //last second of the current day
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
            if bellTime.timeInterval > currentTimeAsInterval { //find the first bellTime that has a timeInterval which lies after the current TimeInterval
                endInterval = bellTime.timeInterval //set the end interval to the interval that lies after
                break
            }
        }
        
        if (endInterval == 0.0){ //if the current time is greater than any of the period start times the interval will still be 0
            return endTime.timeIntervalSince(baseTime)-beginInterval //effectively returns the length of the full 24h day
		} else {
			return endInterval-beginInterval //return the difference of the starting and ending intervals that were found (which is the length of the period)
		}
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
    
    public func stringFromTimeInterval(interval: TimeInterval, is12Hour: Bool, useSeconds: Bool) -> String { //converts a given time interval into a nice string, modifying the string given some flags.
		//This method is used to generate the time remaining text in the ring as well as converting times in the schedule table view
        let interval = Int(interval) //convert to int
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        var hours = (interval / 3600)
        if (is12Hour && hours > 12 && hours != 0){
            hours = hours - 12 //convert to 12 hour time if the current interval lies after noon (ex: 1300 would be converted to 1 PM)
        } else if (is12Hour && hours == 0){ //handle midnight (in 24 HR time midnight is 0000 while its 12 AM in 12 hour time)
            hours = 12
        }
		
        if (!useSeconds){
            return String(format:"%02d:%02d", hours, minutes) //don't include the seconds parameter
        }
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds) //include the seconds parameter
    }
    
    public func getWholeScheduleForDay() -> Array<String> { //gathers data to feed into table cells
        var schedulesArray:Array<String> = [] //init array
        let currentSchedule:Schedule = self.getBellScheduleFor(dateInput: Date()) //init current schedule
        
        let currentBellTimes:Array = currentSchedule.bellTimes //init
        if (currentSchedule.bellTimes.count > 1){
            for bellSchedule in currentBellTimes {
                schedulesArray += ["\(bellSchedule.desc) - " + "\(stringFromTimeInterval(interval: bellSchedule.timeInterval, is12Hour: true, useSeconds: false))"] //build the string array for the table cell view to get cell data from
            }
        } else if (currentSchedule.bellTimes.count <= 1){ //if only 1 schedule or less, check the special days then just return the array as it only has one description
            if (specialDayDescIfApplicable(date: Date()) != ""){
                schedulesArray = [specialDayDescIfApplicable(date: Date())]
                return schedulesArray
            }
            schedulesArray = [currentSchedule.scheduleType]
        }
        return schedulesArray
    }
    
    
    func isDateWithininSpecialDay (specialDay: SpecialDay, dateInput: Date) -> Bool { //check if a given date falls on or within a special day
        var now = Date() //Create date set to midnight on the current date
        now = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: dateInput)!
        var beginDate:Date  = specialDay.beginDate //guaranteed
        beginDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: beginDate)! //set the begin date to be the very start of the day it represents
        var endDate: Date? = specialDay.endDate //try this
        if endDate != nil { //if the special day has an end date, set it to the beginnng of the day it represents
            endDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: endDate!)!
        }
        var inRange:Bool = false //init
        
        if now == beginDate { //if the dates match, the current day is a special day
            inRange = true
        }
        
        if endDate != nil { //if end date exists for the current special day...
            if now == endDate {
                inRange = true
            } else if (now > beginDate && now < endDate!) { //check if the current date falls in range of the two range end points we know (force unwrap is safe here because of null check)
                inRange = true
            }
        }
        
        return inRange //return the result of the checks
    }
}
