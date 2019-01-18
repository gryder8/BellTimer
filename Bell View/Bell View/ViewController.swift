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
    
    private let myMaster: ScheduleMaster = ScheduleMaster(mainBundle: Bundle.main) //load the resource so we can attach getter outputs to sockets
    
    private var timeRemainingAsInt:Int = 0
    
    private var refreshTimer:Timer!
    

    //MARK: Properties
    @IBOutlet weak var currentDate: UITextField!
    @IBOutlet weak var timeRemaining: UITextField!
    @IBOutlet weak var currentPeriodDescription: UITextField!
    @IBOutlet weak var scheduleType: UITextField!
    @IBOutlet weak var nextPeriodDescription: UITextField!
    @IBOutlet weak var progressRing: UICircularProgressRing!
    
    
//    self.setTimeRemaining()
//    self.setUpCurrentDate()
//    self.setUpCurrentPeriodDescription()
//    self.setUpNextPeriodDescription()
//    self.setUpScheduleType()
//    self.setupProgressBar()
    
    
    @objc func refreshUI(){
        //print("Refreshing...")
        self.setTimeRemaining()
        self.setUpCurrentDate()
        self.setUpCurrentPeriodDescription()
        self.setUpNextPeriodDescription()
        self.setUpScheduleType()
        self.setupProgressBar()
        //print("Done!")
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
        nextPeriodDescription.text = "Next: "+myMaster.getNextBellTimeDescription()
    }
    
    private func setUpScheduleType() {
        scheduleType.text = myMaster.getScheduleType()
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
        print(timeRemainingAsInt)
//        if timeRemainingAsInt > 900 {
//            timeRemaining.backgroundColor = UIColor.green
//        } else if timeRemainingAsInt > 600 {
//            timeRemaining.backgroundColor = UIColor.yellow
//        } else if timeRemainingAsInt > 300 {
//            timeRemaining.backgroundColor = UIColor.orange
//        } else {
//            timeRemaining.backgroundColor = UIColor.red
//        }
    }
    
    private func setupProgressBar () {
        var progressPercent:Double = 0.0

        progressPercent = (myMaster.getTimeIntervalUntilNextEvent()/myMaster.getCurrentPeriodLengthAsTimeInterval()) //Use 1-() to count the bar up

        
        progressRing.startProgress(to: UICircularProgressRing.ProgressValue (progressPercent),
                                   duration: 0.25)
        //progressRing.innerRingColor = timeRemaining.backgroundColor!
        
        
        
    }
    
    public func colorForTime () -> UIColor {
        if timeRemainingAsInt > 900 {
            return UIColor.green
        } else if timeRemainingAsInt > 600 {
            return UIColor.yellow
        } else if timeRemainingAsInt > 300 {
            return UIColor.orange
        }
        return UIColor.red
    }
    
    
    override func viewDidLoad() {
//        print(self.stringFromTimeInterval(interval: myMaster.getTimeIntervalUntilNextEvent()))
        refreshUI()
        
        progressRing.shouldShowValueText = false
        progressRing.minValue = 0
        progressRing.maxValue = 1
        progressRing.ringStyle = .gradient
        progressRing.outerCapStyle = .butt
        progressRing.innerCapStyle = .butt
        let ringGradient = [UIColor.white, colorForTime()]
        progressRing.gradientColors = ringGradient
        
        
        
        refreshTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refreshUI), userInfo: nil, repeats: true)
        
        
        super.viewDidLoad()

    }
}

