//
//  ViewController.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/11/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

import UIKit
import WebKit
import UICircularProgressRing

class ViewController: UIViewController, WKUIDelegate {
    
    private let myMaster: ScheduleMaster = ScheduleMaster(mainBundle: Bundle.main) //load the resource so we can attach getter outputs to outlets
    
    private var timeRemainingAsInt:Int = 0
    
    private var refreshTimer:Timer!
    
    private var isActive:Bool = true;
    

    //MARK: Properties
    @IBOutlet weak var currentDate: UITextField!
    @IBOutlet weak var timeRemaining: UITextField!
    @IBOutlet weak var currentPeriodDescription: UITextField!
    @IBOutlet weak var scheduleType: UITextField!
    @IBOutlet weak var nextPeriodDescription: UITextField!
    @IBOutlet weak var progressRing: UICircularProgressRing!
    
    //***SETUP***
//    self.setTimeRemaining()
//    self.setUpCurrentDate()
//    self.setUpCurrentPeriodDescription()
//    self.setUpNextPeriodDescription()
//    self.setUpScheduleType()
//    self.setupProgressBar()
    
    public func setState(active:Bool){
        self.isActive = active
    }
    
    
    @objc func refreshUI(){
        if (isActive){
        self.setTimeRemaining()
        self.setUpCurrentDate()
        self.setUpCurrentPeriodDescription()
        self.setUpNextPeriodDescription()
        self.setUpScheduleType()
        self.setupProgressBar()
        }
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
    }
    
    private func setUpCurrentPeriodDescription(){
        currentPeriodDescription.text = myMaster.getCurrentBellTimeDescription()
        currentPeriodDescription.backgroundColor = colorForTime()
    }
    
    private func setUpNextPeriodDescription(){
        nextPeriodDescription.text = "Next: "+myMaster.getNextBellTimeDescription(date:Date())
    }
    
    private func setUpScheduleType() {
        scheduleType.text = myMaster.getScheduleType(myDate: Date())
    }
    

    private func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func setTimeRemaining(){
        timeRemaining.text = self.stringFromTimeInterval(interval: myMaster.getTimeIntervalUntilNextEvent())
        timeRemainingAsInt = Int(myMaster.getTimeIntervalUntilNextEvent())
        //print(timeRemainingAsInt)
    }
    
    private func setupProgressBar () {
        var progressPercent: Double = 0.0

        progressPercent = (myMaster.getTimeIntervalUntilNextEvent()/myMaster.getCurrentPeriodLengthAsTimeInterval()) //Use 1-() to count the bar up

        let ringGradient = [UIColor.white, colorForTime()]
        progressRing.gradientColors = ringGradient
        progressRing.startProgress(to: UICircularProgressRing.ProgressValue (progressPercent), duration: 0.3)
    }
    
    public func colorForTime () -> UIColor {
        let percentRemaining  = (myMaster.getTimeIntervalUntilNextEvent()/myMaster.getCurrentPeriodLengthAsTimeInterval()) //percent as decimal
        //print (percentRemaining)
        if percentRemaining > 0.25 {
            return UIColor.green
        } else if percentRemaining > 0.20 {
            return UIColor.yellow
        } else if percentRemaining > 0.125 {
            return UIColor.orange
        }
        return UIColor.red
    }
    
    
    override func viewDidLoad() {
        refreshUI() //initialize
        
        progressRing.shouldShowValueText = false
        progressRing.minValue = 0
        progressRing.maxValue = 1
        progressRing.ringStyle = .gradient
        progressRing.outerCapStyle = .butt
        progressRing.innerCapStyle = .butt

        if (isActive){
            refreshTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refreshUI), userInfo: nil, repeats: true)
        }
        
        super.viewDidLoad()

    }
}

