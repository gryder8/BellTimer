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
class InterfaceController: WKInterfaceController {
    
    //MARK: Properties
    @IBOutlet weak var progressRing: WKInterfaceImage!
    @IBOutlet weak var timeRemaining: WKInterfaceLabel!
    @IBOutlet weak var currentPeriodDesc: WKInterfaceLabel!
    @IBOutlet weak var nextPeriodDesc: WKInterfaceLabel!
    
    private var ring:EMTLoadingIndicator?
    
    private let master: ScheduleMaster = ScheduleMaster.shared
    
    private var timeRemainingAsInt:Int = 0
    
    private var refreshTimer:Timer!
    
    private var isActive:Bool = true;
    
    public func colorForTime () -> UIColor {
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
            let progressPercent:Float = Float((master.getTimeIntervalUntilNextEvent()/master.getCurrentPeriodLengthAsTimeInterval())*100) //replace master calls
            ring?.showProgress(startPercentage: progressPercent)
        }
    }
    
    private func generateNextPeriodDesc(){
        if (isActive){
            nextPeriodDesc.setText("Next: "+master.getNextBellTimeDescription(date: Date()))
//            print("Next: "+myMaster.getNextBellTimeDescription(date: Date()))
//            print("Called with Date: ", Date())
        }
    }
    
    private func generateTimeRemaining(){
//        if (myMaster.getTimeIntervalUntilNextEvent() < 60){
//            timeRemaining.setText("> 1 minute");
//        }
        timeRemaining.setText(master.stringFromTimeInterval(interval: master.getTimeIntervalUntilNextEvent(), is12Hour: false, useSeconds: false))
    }
    
    private func generatePeriodDesc(){
        currentPeriodDesc.setText(master.getCurrentBellTimeDescription())
        currentPeriodDesc.setTextColor(colorForTime())
    }
    
    
    
    override func awake(withContext context: Any?) {
        setState(active: true)
        refreshInterface()
        super.awake(withContext: context)
        // Configure interface objects here.
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

}
