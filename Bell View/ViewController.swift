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
    
    let transform:CGAffineTransform = CGAffineTransform(scaleX: 1.0, y: 5.0);
    
    var timeRemainingAsInt:Int = 0
    

    //MARK: Properties
    @IBOutlet weak var currentDate: UITextField!
    @IBOutlet weak var timeRemaining: UITextField!
    @IBOutlet weak var currentPeriodDescription: UITextField!
    @IBOutlet weak var scheduleType: UITextField!
    @IBOutlet weak var nextPeriodDescription: UITextField!
    @IBOutlet weak var progressBar: UIProgressView!
    
    
    
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
        timeRemainingAsInt = Int(String(hours)+String(minutes)+String(seconds))!
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func setTimeRemaining(){
        timeRemaining.text = self.stringFromTimeInterval(interval: myMaster.getTimeIntervalUntilNextEvent())
        
        if timeRemainingAsInt > 1500 { //set the color of the background based on time remaining
            timeRemaining.backgroundColor = UIColor.green
        } else if timeRemainingAsInt > 1000 {
            timeRemaining.backgroundColor = UIColor.yellow
        } else if timeRemainingAsInt > 500 {
            timeRemaining.backgroundColor = UIColor.orange
        } else {
            timeRemaining.backgroundColor = UIColor.red
        }
    }
    
    private func setupProgressBar () {
        progressBar.transform = transform
        let progressPercent:Double = 1-(myMaster.getTimeIntervalUntilNextEvent()/myMaster.getCurrentPeriodLengthAsTimeInterval())
        //print (progressPercent)
        progressBar.setProgress(Float(progressPercent), animated: true)
        if (progressPercent > 0.5){ //ORANGE
           progressBar.progressTintColor = UIColor.orange
        } else if (progressPercent > 0.75){ //YELLOW
            progressBar.progressTintColor = UIColor.yellow
        } else if (progressPercent > 0.9) { //GREEN
            progressBar.progressTintColor = UIColor.green
        } else { //RED
            progressBar.progressTintColor = UIColor.red
        }
    }
    
    
    override func viewDidLoad() {
//        print(self.stringFromTimeInterval(interval: myMaster.getTimeIntervalUntilNextEvent()))
        super.viewDidLoad()
        self.setTimeRemaining() //TODO: Continually update
        self.setUpCurrentDate()
        self.setUpCurrentPeriodDescription()
        self.setUpNextPeriodDescription()
        self.setUpScheduleType()
        self.setupProgressBar()
//        self.setupProgressBar()
    }
}

