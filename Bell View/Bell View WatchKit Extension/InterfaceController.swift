//
//  InterfaceController.swift
//  Bell View WatchKit Extension
//
//  Created by Gavin Ryder on 1/11/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

import WatchKit
import Foundation
import EMTLoadingIndicator
import WatchConnectivity


//https://developer.apple.com/documentation/watchconnectivity/using_watch_connectivity_to_communicate_between_your_apple_watch_app_and_iphone_app
//https://www.swiftdevcenter.com/sending-data-from-iphone-to-apple-watch-and-vice-versa-using-swift-5/


class InterfaceController: WKInterfaceController {
    
    private override init() {
        super.init() //configure from super, then customize
        if (!hasAllData()) {
            requestData()
        }
    }
    
    //MARK: - Properties
    let session = WCSession.default
    
    @IBOutlet weak var progressRing: WKInterfaceImage!
    @IBOutlet weak var timeRemaining: WKInterfaceLabel!
    @IBOutlet weak var currentPeriodDesc: WKInterfaceLabel!
    @IBOutlet weak var nextPeriodDesc: WKInterfaceLabel!
    
    private let currentDay = Calendar.current.component(.weekday, from: Date())
    
    private var ring:EMTLoadingIndicator?
    
    var periodNames = Array(repeating: String(), count: 8)
    
    var periodNamesConfigured:Bool = false
    
    enum weekDay: Int, Decodable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }
    
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
    
    //Struct that holds all the belltimes
    struct Schedule: Decodable {
        var scheduleType: String
        let bellTimes: [BellTime]
    }
    
    typealias AllSpecialDays = [SpecialDay] //provide an alias to reference the array of objects from
    
    var allSpecialDays: AllSpecialDays?
    
    typealias BellSchedules = [Schedule]  //provide an alias to reference the array of objects from
    
    var allSchedules: BellSchedules?
    
    typealias AllDefaultDays = [DefaultDay] //provide an alias to reference the array of objects from
    
    var allDefaultDays: AllDefaultDays?
    
    //private let master: ScheduleMaster = ScheduleMaster.shared
    
    private var timeRemainingAsInt:Int = 0
    
    private var refreshTimer:Timer!
    
    private var isRingSetup:Bool = false
    
    private var nextPeriodDescription:String = "Loading..."
    private var currentPeriodDescription:String = "Loading..."
    private var progressPercent:Float = 0.0
    private var formattedTimeRemaining:String = "Loading..."
    
    
    private var isActive:Bool = true;
    
    
    public func colorForTime() -> UIColor {
        let timeRemainingInterval = self.getTimeIntervalUntilNextEvent() //TODO: make sure this isn't too expensive
        if timeRemainingInterval > 900 {
            return UIColor.green
        } else if timeRemainingInterval >= 600 {
            return UIColor.yellow
        } else if timeRemainingInterval >= 300 {
            return UIColor.orange
        }
        return UIColor.red
    }
    
    public func setActive(newState:Bool){
        self.isActive = newState
    }
    
    @objc func refreshWatchUI(){
        if (isActive) {
            self.setTimeRemaining()
            self.setUpCurrentPeriodDescription()
            self.setUpNextPeriodDescription()
            self.generateRing()
        }
    }
    
    private func generateRing(){
        progressPercent = Float(getTimeIntervalUntilNextEvent() / getCurrentPeriodLengthAsTimeInterval())
        if (!isRingSetup){
            ring = EMTLoadingIndicator.init(interfaceController: self, interfaceImage: progressRing, width: 80, height: 80, style: .line)
            EMTLoadingIndicator.progressLineWidthOuter = 3
            EMTLoadingIndicator.progressLineWidthInner = 8
            EMTLoadingIndicator.progressLineColorOuter = UIColor(red:0.68, green:0.68, blue:0.68, alpha:1.0)
            EMTLoadingIndicator.progressLineColorInner = colorForTime() //make sure color for time has needed data availible
            ring?.prepareImagesForProgress()
            ring?.showProgress(startPercentage: self.progressPercent)
            isRingSetup = true
        } else {
            EMTLoadingIndicator.progressLineColorInner = colorForTime()
            ring?.prepareImagesForProgress()
            ring?.showProgress(startPercentage: self.progressPercent)
        }
    }
    
    
    private func setUpNextPeriodDescription(isSaturday: Bool = false){ //TODO: may be too complex for Watch
        
        //SPECIAL CASE
        if (isSaturday == true){ //if it's Saturday, grab the desription for Monday instead of Sunday (which will be the same as Saturday)
            let calendar = Calendar.current
            var simulatedMonday = calendar.date(byAdding: .day, value: 2, to: Date())!
            simulatedMonday = Calendar.current.date(bySettingHour: 0, minute: 0, second: 5, of: simulatedMonday)!
            nextPeriodDescription = "Next: " + getNextBellTimeDescription(date:simulatedMonday)
            nextPeriodDesc.setText(nextPeriodDescription)
            if (nextPeriodDescription.contains("Period")){
                let str  = nextPeriodDescription
                let startIndex = str.index(str.endIndex, offsetBy: -1*("Period N".count)) //count backwards from the end of the string
                let periodSubstring = String(str[startIndex...])
                nextPeriodDescription.replaceSubrange(startIndex..., with: customizePeriodName(stringWithDefaultPeriodName: periodSubstring)) //FIXME: import custom period names array
                nextPeriodDesc.setText(nextPeriodDescription) //set once modified
            }
            
            return //end execution as everything has been set up
            
        } else { //not Saturday
            nextPeriodDescription = "Next: " + getNextBellTimeDescription(date:Date())
            if (nextPeriodDescription.contains("Period")){
                let str  = nextPeriodDescription
                let startIndex = str.index(str.endIndex, offsetBy: -1*("Period N".count)) //count backwards from the end of the string
                let periodSubstring = String(str[startIndex...]) //substring is the start to the end
                nextPeriodDescription.replaceSubrange(startIndex..., with: customizePeriodName(stringWithDefaultPeriodName: periodSubstring)) //replace the range (take advantage of the fact that the period name is always at the end of the description)
                nextPeriodDesc.setText(nextPeriodDescription) //set once modified
            }
        }
    }
    
    private func setTimeRemaining(){
        if (currentDay == 7){
            timeRemaining.setText(stringFromTimeInterval(interval: getTimeIntervalUntilNextEvent(isWeekend: true), is12Hour: false, useSeconds: true))
            timeRemainingAsInt = Int(getTimeIntervalUntilNextEvent(isWeekend: true))
            setUpNextPeriodDescription(isSaturday: true)
        } else {
            timeRemaining.setText(stringFromTimeInterval(interval: getTimeIntervalUntilNextEvent(), is12Hour: false, useSeconds: true))
            timeRemainingAsInt = Int(getTimeIntervalUntilNextEvent())
        }
    }
    
    private func setUpCurrentPeriodDescription(){
        currentPeriodDescription = self.getCurrentBellTimeDescription() //initialize the text
        if (currentPeriodDescription.contains("Period")){
            let str  = currentPeriodDescription
            let startIndex = str.index(str.endIndex, offsetBy: -1*("Period N".count)) //count backwards from the end of the string
            let periodSubstring = String(str[startIndex...])
            currentPeriodDescription.replaceSubrange(startIndex..., with: self.customizePeriodName(stringWithDefaultPeriodName: periodSubstring))
            currentPeriodDesc.setText(currentPeriodDescription)
        }
        currentPeriodDesc.setTextColor(colorForTime())
    }
    
    public func customizePeriodName(stringWithDefaultPeriodName: String) -> String {
        if (periodNamesConfigured) {
        switch stringWithDefaultPeriodName {
        //cases
        case "Period 0": return periodNames[0]
        case "Period 1": return periodNames[1]
        case "Period 2": return periodNames[2]
        case "Period 3": return periodNames[3]
        case "Period 4": return periodNames[4]
        case "Period 5": return periodNames[5]
        case "Period 6": return periodNames[6]
        case "Period 7": return periodNames[7]
        //default
        default: return stringWithDefaultPeriodName //don't modify
            
            }
        } else {
            return stringWithDefaultPeriodName
        }
    }
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
        session.delegate = self
        session.activate()
        setActive(newState: true)
        refreshWatchUI()
    }
    
    override func willActivate() {
        setActive(newState: true)
        if (hasAllData()) {
            refreshWatchUI()
        } else {
            requestData()
            refreshWatchUI()
        }
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        setActive(newState: false)
        //TODO: Wipe local data?
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func didAppear() {
        isActive = true
        if (!hasAllData()) {
            requestData()
        }
        refreshWatchUI()
        if (isActive && hasAllData()){
            refreshTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(refreshWatchUI), userInfo: nil, repeats: true) //TODO: Tweak interval
        }
    }
    
    func requestData(){
        let data: [String:Any] = ["dataNeeded":"noDataAvailible"]
        
        session.sendMessage(data, replyHandler: nil, errorHandler: nil) //send the data
    }
    
    func hasAllData() -> Bool {
        return (allSpecialDays != nil && allDefaultDays != nil && allSchedules != nil && periodNamesConfigured) //make sure all data exists
    }
    
    //******************************************************************************************************************************************
    //******************************************************************************************************************************************
    //******************************************************************************************************************************************
    //******************************************************************************************************************************************
    //******************************************************************************************************************************************
    //******************************************************************************************************************************************
    
    //*************** Schedule Setup ***************
    //MARK: - Schedule Setup
    private var defaultScheduleForToday:String = ""
    private var defaultScheduleForNextDay:String = ""
    
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




extension InterfaceController: WCSessionDelegate {
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    public func session(_ session: WCSession, didReceiveMessage recievedData: [String : Any]) {
        
        print("****Watch received data from iPhone!****")
        if (recievedData.count == 1){ //test if this works for distinguishing cases
            periodNames = recievedData["CustomPeriods"] as! [String]
            periodNamesConfigured = (periodNames != Array(repeating: String(), count: 8))
        } else {
            periodNames = recievedData["CustomPeriods"] as! [String]
            periodNamesConfigured = (periodNames != Array(repeating: String(), count: 8))
            allSpecialDays = recievedData["AllSpecialDays"] as? [SpecialDay]
            allSchedules = recievedData["BellSchedules"] as? [Schedule]
            allSpecialDays = recievedData["AllSpecialDays"] as? [SpecialDay]
            
        }
    }
}

