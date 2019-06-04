//
//  ViewController.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/11/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

import UIKit
import UICircularProgressRing

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private let master: ScheduleMaster = ScheduleMaster.shared //load the resource so we can attach getter outputs to outlets
    
    private var timeRemainingAsInt:Int = 0
    
    private var refreshTimer:Timer!
    
    private var isActive:Bool = true
    
    private let currentDay = Calendar.current.component(.weekday, from: Date())
    
    private var isSaturday = false;
    
    
    static let shared = ViewController()
    
    
    //MARK: Properties
    @IBOutlet var swipeGesture: UISwipeGestureRecognizer!
    @IBOutlet weak var currentDate: UITextField!
    @IBOutlet weak var timeRemaining: UITextField!
    @IBOutlet weak var currentPeriodDescription: UITextField!
    @IBOutlet weak var scheduleType: UITextField!
    @IBOutlet weak var nextPeriodDescription: UITextField!
    @IBOutlet weak var progressRing: UICircularProgressRing!
    @IBOutlet weak var noConnection: UITextField!
    
    
    public func setState(active:Bool){
        self.isActive = active
    }
    
    
    @objc func refreshUI(){
        if (!master.doneLoading){
            swipeGesture.isEnabled = false
        } else {
            swipeGesture.isEnabled = true
        }
        if (isActive && master.canContinue()){
            self.setTimeRemaining()
            self.setUpCurrentDate()
            self.setUpCurrentPeriodDescription()
            self.setUpNextPeriodDescription()
            //print(master.getNextBellTimeDescription(date: dateTest!))
            self.setUpScheduleType()
            self.setupProgressBar()
        }
    }
    
    func updateConnectionStatus() {
        let connected = master.isConnected
        if (connected){
            noConnection.text = ""
        } else if (!connected){
            noConnection.text = "No connection. Data may be incorrect"
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
        currentPeriodDescription.text = master.getCurrentBellTimeDescription()
        currentPeriodDescription.backgroundColor = colorForTime()
    }
    
    private func setUpNextPeriodDescription(isSaturday: Bool = false){
        
        if (isSaturday == true){
            let calendar = Calendar.current
            var simulatedMonday = calendar.date(byAdding: .day, value: 2, to: Date())!
            simulatedMonday = Calendar.current.date(bySettingHour: 0, minute: 0, second: 5, of: simulatedMonday)!
            nextPeriodDescription.text = "Next: " + master.getNextBellTimeDescription(date:simulatedMonday)
            return
        }
        nextPeriodDescription.text = "Next: " + master.getNextBellTimeDescription(date:Date())
    }
    
    private func setUpScheduleType() {
        scheduleType.text = master.getScheduleType(myDate: Date())
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
    
    private func setupProgressBar () {
        var progressPercent: Double = 0.0
        
        progressPercent = (master.getTimeIntervalUntilNextEvent()/master.getCurrentPeriodLengthAsTimeInterval()) //Use 1-() to count the bar up
        
        let ringGradient = [UIColor.white, colorForTime()]
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
        return UIColor.red
    }
    
    
    override func viewDidLoad() {
        if (!master.doneLoading){
            swipeGesture.isEnabled = false
        } else {
            swipeGesture.isEnabled = true
        }
        super.viewDidLoad()
        self.navigationController!.navigationBar.isHidden = true
        
        refreshUI() //initialize
        
        progressRing.shouldShowValueText = false
        progressRing.minValue = 0
        progressRing.maxValue = 1
        progressRing.ringStyle = .gradient
        progressRing.outerCapStyle = .butt
        progressRing.innerCapStyle = .butt
        updateConnectionStatus()
        
        if (isActive){
            refreshTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refreshUI), userInfo: nil, repeats: true)
        }
        
    }
}

