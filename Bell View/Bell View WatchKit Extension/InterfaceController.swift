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

class InterfaceController: WKInterfaceController {
    
    //MARK: Properties
    @IBOutlet weak var progressRing: WKInterfaceImage!
    @IBOutlet weak var timeRemaining: WKInterfaceLabel!
    @IBOutlet weak var currentPeriodDesc: WKInterfaceLabel!
    
    private var ring:EMTLoadingIndicator?
    
    private let myMaster: ScheduleMaster = ScheduleMaster(mainBundle: Bundle.main) //load the resource so we can attach getter outputs to outlets
    
    private var timeRemainingAsInt:Int = 0
    
    private var refreshTimer:Timer!
    
    private var isActive:Bool = true;
    
    public func colorForTime () -> UIColor {
        let percentRemaining  = (myMaster.getTimeIntervalUntilNextEvent()/myMaster.getCurrentPeriodLengthAsTimeInterval()) //percent as decimal
        if percentRemaining > 0.25 {
            return UIColor.green
        } else if percentRemaining > 0.20 {
            return UIColor.yellow
        } else if percentRemaining > 0.10 {
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
        }
    }
    
    private func generateRing(){
        if (isActive){
        ring = EMTLoadingIndicator.init(interfaceController: self, interfaceImage: progressRing, width: 110, height: 110, style: .line)
        EMTLoadingIndicator.progressLineWidthOuter = 3
        EMTLoadingIndicator.progressLineWidthInner = 8
        print(EMTLoadingIndicator.progressLineWidthInner)
        EMTLoadingIndicator.progressLineColorOuter = UIColor(red:0.68, green:0.68, blue:0.68, alpha:1.0)
        EMTLoadingIndicator.progressLineColorInner = colorForTime()
        ring?.prepareImagesForProgress()
        let progressPercent:Float = Float((myMaster.getTimeIntervalUntilNextEvent()/myMaster.getCurrentPeriodLengthAsTimeInterval())*100)
        ring?.showProgress(startPercentage: progressPercent)
        }
    }
    
    private func generateTimeRemaining(){
        timeRemaining.setText(myMaster.stringFromTimeInterval(interval: myMaster.getTimeIntervalUntilNextEvent(), is12Hour: false, useSeconds: false))
    }
    
    private func generatePeriodDesc(){
        currentPeriodDesc.setText(myMaster.getCurrentBellTimeDescription())
        currentPeriodDesc.setTextColor(colorForTime())
    }
    
    
    
    override func awake(withContext context: Any?) {
        setState(active: true)
        super.awake(withContext: context)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        setState(active: true)
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        setState(active: false)
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func didAppear() {
        refreshInterface()
        if (isActive){
            refreshTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(refreshInterface), userInfo: nil, repeats: true)
        }
    }

}
