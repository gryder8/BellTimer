//
//  ViewController.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/11/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

import UIKit
import UICircularProgressRing
import WatchConnectivity

extension ViewController: WCSessionDelegate {
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("****Phone recieved message from Watch!****")
        DispatchQueue.main.async {
            // let data: [String:Any] = ["dataNeeded":"noDataAvailible"]
            if ((message["dataNeeded"] as? String) == "noDataAvailible") {
                self.sendDataToWatch(periodUpdate: false); //if the watch says it needs data, send it data
            }
        }
    }
}

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    //MARK: - Local vars
    
    private let master: ScheduleMaster = ScheduleMaster.shared //load the resource so we can attach getter outputs to outlets
    
    private var timeRemainingAsInt:Int = 0
    
    private var refreshTimer:Timer!
    
    private var isActive:Bool = true
    
    private let currentDay = Calendar.current.component(.weekday, from: Date())
    
    private var isSaturday = false;
    
    private var progressPercent: Double = 0.0
    
    private var isUISetup:Bool = false
    
    static let shared = ViewController() //WARNING: can cause abort if accessed too early by another class
    
    private let CustomPeriodNames: ScheduleNames = ScheduleNames.shared
    
    
    //MARK:  - Properties
    var watchSession: WCSession?
    
    @IBOutlet var swipeGesture: UISwipeGestureRecognizer!
    @IBOutlet weak var currentDate: UITextField!
    @IBOutlet weak var timeRemaining: UITextField!
    @IBOutlet weak var currentPeriodDescription: UITextField!
    @IBOutlet weak var scheduleType: UITextField!
    @IBOutlet weak var nextPeriodDescription: UITextField!
    @IBOutlet weak var progressRing: UICircularProgressRing!
    @IBOutlet weak var noConnection: UITextField!
    @IBOutlet weak var gradientView: GradientView!
    
    
    //MARK: - UI Refresh
    public func setState(active:Bool){
        self.isActive = active
    }
    
    
    @objc func refreshUI(){
        if (isActive && master.canContinue()){
            self.setTimeRemaining() //also on Watch
            self.setUpCurrentDate()
            self.setUpCurrentPeriodDescription() //also on Watch
            self.setUpNextPeriodDescription() //also on Watch
            self.setUpScheduleType()
            self.setupProgressBar() //also on Watch
            isUISetup = true
            //            if ((watchSession?.isReachable) != nil) {
            //                sendDataToWatch()
            //            }
        }
    }
    
    
    //MARK: - UI Setups
    func updateConnectionStatus() {
        let connected = master.isConnected
        if (connected){
            noConnection.text = ""
        } else if (!connected){
            noConnection.text = "No connection. Data may be incorrect."
        }
    }
    
    public func isWatchConnected() -> Bool {
        return watchSession?.isReachable ?? false
    }
    
    
    private func setUpCurrentDate(){
        
        let dayYearFormatter:DateFormatter = DateFormatter()
        dayYearFormatter.dateFormat = "dd, yyyy"
        let now = Date()
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "LLLL"
        let nameOfMonth = monthFormatter.string(from: now)
        
        let formattedCurrentDate = nameOfMonth + " " + dayYearFormatter.string(from: Date())
        
        currentDate.text = formattedCurrentDate
        
        if (!master.canContinue()){
            swipeGesture.isEnabled = false
        } else {
            swipeGesture.isEnabled = true
        }
    }
    
    private func setUpCurrentPeriodDescription(){
        currentPeriodDescription.text = master.getCurrentBellTimeDescription() //initialize the text
        if (currentPeriodDescription.text!.contains("Period")){
            let str  = currentPeriodDescription.text!
            let startIndex = str.index(str.endIndex, offsetBy: -1*("Period N".count)) //count backwards from the end of the string
            let periodSubstring = String(str[startIndex...])
            currentPeriodDescription.text!.replaceSubrange(startIndex..., with: CustomPeriodNames.customizePeriodName(stringWithDefaultPeriodName: periodSubstring))
        }
        currentPeriodDescription.backgroundColor = colorForTime()
    }
    
    private func setUpNextPeriodDescription(isSaturday: Bool = false){
        
        //SPECIAL CASE
        if (isSaturday == true){ //if it's Saturday, grab the desription for Monday instead of Sunday (which will be the same as Saturday)
            let calendar = Calendar.current
            var simulatedMonday = calendar.date(byAdding: .day, value: 2, to: Date())!
            simulatedMonday = Calendar.current.date(bySettingHour: 0, minute: 0, second: 5, of: simulatedMonday)!
            nextPeriodDescription.text = "Next: " + master.getNextBellTimeDescription(date:simulatedMonday)
            if (nextPeriodDescription.text!.contains("Period")){
                let str  = nextPeriodDescription.text!
                let startIndex = str.index(str.endIndex, offsetBy: -1*("Period N".count)) //count backwards from the end of the string
                let periodSubstring = String(str[startIndex...])
                nextPeriodDescription.text!.replaceSubrange(startIndex..., with: CustomPeriodNames.customizePeriodName(stringWithDefaultPeriodName: periodSubstring))
            }
            
            return //end execution as everything has been set up
            
        } else { //not Saturday
            nextPeriodDescription.text = "Next: " + master.getNextBellTimeDescription(date:Date())
            if (nextPeriodDescription.text!.contains("Period")){
                let str  = nextPeriodDescription.text!
                let startIndex = str.index(str.endIndex, offsetBy: -1*("Period N".count)) //count backwards from the end of the string
                let periodSubstring = String(str[startIndex...]) //substring is the start to the end
                nextPeriodDescription.text!.replaceSubrange(startIndex..., with: CustomPeriodNames.customizePeriodName(stringWithDefaultPeriodName: periodSubstring)) //replace the range (take advantage of the fact that the period name is always at the end of the description)
            }
        }
    }
    
    private func setUpScheduleType() {
        scheduleType.text = master.getScheduleType(dateInput: Date())
    }
    
    private func setTimeRemaining(){
        if (currentDay == 7){
            timeRemaining.text = master.stringFromTimeInterval(interval: master.getTimeIntervalUntilNextEvent(isWeekend: true), is12Hour: false, useSeconds: true)
            timeRemainingAsInt = Int(master.getTimeIntervalUntilNextEvent(isWeekend: true))
            setUpNextPeriodDescription(isSaturday: true)
        } else {
            timeRemaining.text = master.stringFromTimeInterval(interval: master.getTimeIntervalUntilNextEvent(), is12Hour: false, useSeconds: true)
            timeRemainingAsInt = Int(master.getTimeIntervalUntilNextEvent())
        }
    }
    
    private func setupProgressBar () { //use the period length and time remaining to generate a percent which sets up the progress bar
        
        progressPercent = (master.getTimeIntervalUntilNextEvent()/master.getCurrentPeriodLengthAsTimeInterval()) //Use 1-() to count the bar up
        
        let ringGradient = [UIColor.white, colorForTime()] //stores the gradient colors (can be more than 2)
        progressRing.gradientColors = ringGradient
        progressRing.startProgress(to: UICircularProgressRing.ProgressValue (progressPercent), duration: 0.3)
    }
    
    public func colorForTime () -> UIColor {
        //let percentRemaining  = (master.getTimeIntervalUntilNextEvent()/master.getCurrentPeriodLengthAsTimeInterval()) //percent as decimal
        let timeRemainingInterval = master.getTimeIntervalUntilNextEvent();
        if timeRemainingInterval > 900 {
            return UIColor.green
        } else if timeRemainingInterval >= 600 {
            return UIColor.yellow
        } else if timeRemainingInterval >= 300 {
            return UIColor.orange
        }
        return UIColor.red //fall out
    }
    
    
    //MARK: - App event handlers
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureWatchKitSession()
        if (self.traitCollection.userInterfaceStyle == .dark){
            gradientView.firstColor =   #colorLiteral(red: 0.01680417731, green: 0.3921568627, blue: 1, alpha: 1)
            gradientView.secondColor =  #colorLiteral(red: 0.1045082286, green: 0.4720277933, blue: 0.9899627566, alpha: 1)
        } else {
            gradientView.firstColor = #colorLiteral(red: 0.1045082286, green: 0.4720277933, blue: 0.9899627566, alpha: 1)
            gradientView.secondColor = #colorLiteral(red: 0.01680417731, green: 0.3921568627, blue: 1, alpha: 1)
        }
        
        self.navigationController!.navigationBar.isHidden = true
        refreshUI() //initialize
        
        progressRing.shouldShowValueText = false
        progressRing.minValue = 0
        progressRing.maxValue = 1
        progressRing.ringStyle = .gradient
        progressRing.outerCapStyle = .butt
        progressRing.innerCapStyle = .butt
        updateConnectionStatus()
        
        sendDataToWatch()
        
        if (isActive){
            refreshTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refreshUI), userInfo: nil, repeats: true)
        }
        
    }
    
    func configureWatchKitSession() {
        if WCSession.isSupported() {
            watchSession = WCSession.default
            watchSession?.delegate = self
            watchSession?.activate()
        }
    }
    
    func sendDataToWatch(periodUpdate: Bool = false) { //parameter is defaulted so its only passed when just the period names need to be updated
        if let validSession = self.watchSession, validSession.isReachable {
            if (periodUpdate){
                let data: [String:Any] = ["CustomPeriods":CustomPeriodNames.getPeriodNames()]
                validSession.sendMessage(data, replyHandler: nil, errorHandler: nil) //send the data
            } else {
                if (isUISetup && master.canContinue()) { //make sure everything is setup on this end before we send data
                    let data: [String: Any] = ["AllSpecialDays": master.allSpecialDays!,
                                               "BellSchedules": master.allSchedules!,
                                               "AllDefaultDays": master.allDefaultDays!,
                                               "CustomPeriods": CustomPeriodNames.getPeriodNames()]
                    validSession.sendMessage(data, replyHandler: nil, errorHandler: nil) //send the data
                    
                }
            }
        } else {
            let alert = UIAlertController(title: "No Valid Apple Watch Session Found", message: "Session was not reachable!", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            
            self.present(alert, animated: true)
        }
    }
    
}
