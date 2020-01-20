//
//  ScheduleNames.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/19/20.
//  Copyright © 2020 Gavin Ryder. All rights reserved.
//

import Foundation

class ScheduleNames {
    var periodNames = Array(repeating: String(), count: 8)
    let PERIOD_NAME_LOCATION_KEY:String = "PERIODNAMES"
    let defaults = UserDefaults.standard
    
    public init() { //INITIALIZER
        loadFromCache()
    }
    
    private func loadFromCache() -> Void {
        
        if (defaults.array(forKey: PERIOD_NAME_LOCATION_KEY) != nil){ //data is found in the local cache
            periodNames = defaults.array(forKey: PERIOD_NAME_LOCATION_KEY) as! [String]
            print("Assigned value of periodNames based on cache data")
        } else { //array is not stored in the cache, write defaults
            periodNames = ["Period 0", "Period 1", "Period 2", "Period 3", "Period 4", "Period 5", "Period 6", "Period 7"]
            defaults.set(periodNames, forKey: PERIOD_NAME_LOCATION_KEY)
            print("Added default array of period names to cache")
        }
        
    }
    
    public func updateIndex (indexToModify: Int, newData: String) -> Void {
        periodNames[indexToModify] = newData
        defaults.set(periodNames, forKey: PERIOD_NAME_LOCATION_KEY) //update cached data
        
    }
    
    public func getPeriodNames() -> [String] {
        return self.periodNames
    }
}
