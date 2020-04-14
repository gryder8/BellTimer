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
    
    //MARK: Properties
     let session = WCSession.default
    
    @IBOutlet weak var progressRing: WKInterfaceImage!
    @IBOutlet weak var timeRemaining: WKInterfaceLabel!
    @IBOutlet weak var currentPeriodDesc: WKInterfaceLabel!
    @IBOutlet weak var nextPeriodDesc: WKInterfaceLabel!
    
    private var ring:EMTLoadingIndicator?
    
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
    
    func setUIFromDataRecieved(recievedData: [String: Any]) {
        
        //    "formattedTimeRemaining": timeRemainingAsFormattedString,
        //    "currentDesc": currentPeriod,
        //    "nextDesc": nextPeriod,
        //    "percentRemaining": progressPercent,
        //"timeUntilNext": timeRemainingAsInt]
            
        if let fTimeRem = recievedData["formattedTimeRemaining"] as? String {
            self.timeRemaining.setText(fTimeRem)
            self.formattedTimeRemaining = fTimeRem
        }
        
        if let currDesc = recievedData["currentDesc"] as? String {
            self.currentPeriodDesc.setText(currDesc)
            self.currentPeriodDescription = currDesc
        }
        
        if let nextDesc = recievedData["nextDesc"] as? String {
            self.nextPeriodDesc.setText(nextDesc)
            self.nextPeriodDescription = nextDesc
        }
        
        if let perRem = recievedData["percentRemaining"] as? Double { //recieves the value of the ring in the app view controller as a double, converts to Float and then sets it up
            let percent:Float = Float(perRem)
            self.progressPercent = percent
            if (isRingSetup == true) {
                ring?.showProgress(startPercentage: percent)
            }
        }
        
        if let timeIntervAsInt = recievedData["timeUntilNext"] as? Int {
            timeRemainingAsInt = timeIntervAsInt
        }
    }
    
    
    public func colorForTime() -> UIColor {
        let timeRemainingInterval = timeRemainingAsInt
        if timeRemainingInterval > 900 {
            return UIColor.green
        } else if timeRemainingInterval >= 600 {
            return UIColor.yellow
        } else if timeRemainingInterval >= 300 {
            return UIColor.orange
        }
        return UIColor.red
    }
    
    public func setState(active:Bool){
        self.isActive = active
    }
    
    @objc func refreshInterface(){
        if (isActive) {
            generateRing()
            generateTimeRemaining()
            generatePeriodDesc()
            generateNextPeriodDesc()
        }
    }
    
    private func generateRing(){
        if (isActive){
            ring = EMTLoadingIndicator.init(interfaceController: self, interfaceImage: progressRing, width: 80, height: 80, style: .line)
            EMTLoadingIndicator.progressLineWidthOuter = 3
            EMTLoadingIndicator.progressLineWidthInner = 8
            EMTLoadingIndicator.progressLineColorOuter = UIColor(red:0.68, green:0.68, blue:0.68, alpha:1.0)
            EMTLoadingIndicator.progressLineColorInner = UIColor(red:0.36, green:0.69, blue:1.00, alpha:1.0)
            ring?.prepareImagesForProgress()
            isRingSetup = true
            ring?.showProgress(startPercentage: self.progressPercent)
        }
    }
    
    private func generateNextPeriodDesc(){
        if (isActive){
            nextPeriodDesc.setText("Next:" + self.nextPeriodDescription)
//            print("Next: "+myMaster.getNextBellTimeDescription(date: Date()))
//            print("Called with Date: ", Date())
        }
    }
    
    private func generateTimeRemaining(){
//        if (myMaster.getTimeIntervalUntilNextEvent() < 60){
//            timeRemaining.setText("> 1 minute");
//        }
        timeRemaining.setText(self.formattedTimeRemaining)
    }
    
    private func generatePeriodDesc(){
        currentPeriodDesc.setText(self.currentPeriodDescription)
        currentPeriodDesc.setTextColor(colorForTime())
    }
    
    
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
        session.delegate = self
        session.activate()
        setState(active: true)
        refreshInterface()
    }
    
    override func willActivate() {
        setState(active: true)
        refreshInterface()
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        setState(active: false)
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func didAppear() {
        isActive = true;
        refreshInterface()
        if (isActive){
            refreshTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refreshInterface), userInfo: nil, repeats: true)
        }
    }
    
    func sendToPhone(){
        let data: [String:Any] = ["dataNeeded":"noDataAvailible"]
                                   
          session.sendMessage(data, replyHandler: nil, errorHandler: nil) //send the data
        }
    
    func hasAllData() -> Bool {
        return (allSpecialDays != nil && allDefaultDays != nil && allSchedules != nil) //make sure all data exists
    }
    
    
    
    }




extension InterfaceController: WCSessionDelegate {

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    public func session(_ session: WCSession, didReceiveMessage recievedData: [String : Any]) {
    
    print("****Received data: \(recievedData)"+"****")
    
        
    allSpecialDays = recievedData["AllSpecialDays"] as? [SpecialDay]
    allSchedules = recievedData["BellSchedules"] as? [Schedule]
    allSpecialDays = recievedData["AllSpecialDays"] as? [SpecialDay]
    
//    if let currDesc = recievedData["currentDesc"] as? String {
//        self.currentPeriodDesc.setText(currDesc)
//        self.currentPeriodDescription = currDesc
//    }
//
//    if let nextDesc = recievedData["nextDesc"] as? String {
//        self.nextPeriodDesc.setText(nextDesc)
//        self.nextPeriodDescription = nextDesc
//    }
//
//    if let perRem = recievedData["percentRemaining"] as? Double { //recieves the value of the ring in the app view controller as a double, converts to Float and then sets it up
//        let percent:Float = Float(perRem)
//        self.progressPercent = percent
//        if (isRingSetup == true) {
//            ring?.showProgress(startPercentage: percent)
//        }
//    }
    }
}

