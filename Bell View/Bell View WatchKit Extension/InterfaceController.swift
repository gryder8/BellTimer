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

}
