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
    
    private var ring:EMTLoadingIndicator?
    
    private let myMaster: ScheduleMaster = ScheduleMaster(mainBundle: Bundle.main) //load the resource so we can attach getter outputs to outlets
    
    private var timeRemainingAsInt:Int = 0
    
    private var refreshTimer:Timer!
    
    private var isActive:Bool = true;
    
    public func setState(active:Bool){
        self.isActive = active
    }
    
    private func setupRing(){
        ring = EMTLoadingIndicator.init(interfaceController: self, interfaceImage: progressRing, width: 100, height: 100, style: .line)
        ring?.showProgress(startPercentage: 0)
        EMTLoadingIndicator.progressLineColorOuter = UIColor.blue
        EMTLoadingIndicator.progressLineColorInner = UIColor.gray
        ring?.prepareImagesForProgress()
        let startPercentage:Float = Float((myMaster.getTimeIntervalUntilNextEvent()/myMaster.getCurrentPeriodLengthAsTimeInterval())*100)
        ring?.showProgress(startPercentage: startPercentage)
    }
    
    

    

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func didAppear() {
        setupRing()
    }

}
