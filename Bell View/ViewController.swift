//
//  ViewController.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/11/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

import UIKit
import WebKit
class ViewController: UIViewController, WKUIDelegate {
    
    let myMaster: ScheduleMaster = ScheduleMaster(mainBundle: Bundle.main) //load the resource so we can attach getter outputs to sockets
    

    //MARK: Properties
    @IBOutlet weak var currentDate: UITextField!
    @IBOutlet weak var timeRemaining: UITextField!
    @IBOutlet weak var currentPeriodDescription: UITextField!
    @IBOutlet weak var scheduleType: UITextField!
    @IBOutlet weak var nextPeriodDescription: UITextField!
    
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
    }
    
    private func setUpNextPeriodDescription(){
        nextPeriodDescription.text = myMaster.getNextBellTimeDescription()
    }
    
    private func setUpScheduleType() {
        scheduleType.text = myMaster.getScheduleType()
    }
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func setTimeRemaining(){
        timeRemaining.text = self.stringFromTimeInterval(interval: myMaster.getTimeIntervalUntilNextEvent())
    }
    
    override func viewDidLoad() {
//        print(self.stringFromTimeInterval(interval: myMaster.getTimeIntervalUntilNextEvent()))
        super.viewDidLoad()
        self.setUpCurrentDate()
        self.setUpCurrentPeriodDescription()
        self.setUpNextPeriodDescription()
        self.setUpScheduleType()
        self.setTimeRemaining()
    }
}

