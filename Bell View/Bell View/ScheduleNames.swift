//
//  ScheduleNames.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/19/20.
//  Copyright © 2020 Gavin Ryder. All rights reserved.
//

import Foundation

class ScheduleNames {
    
    //MARK: - Local vars
    var periodNames = Array(repeating: String(), count: 8) //empty array of 8 strings
    let PERIOD_NAME_LOCATION_KEY:String = "PERIODNAMES"
    let defaults = UserDefaults.standard
    static let shared = ScheduleNames()
    
    //MARK: - Initialization
    public init() { //INITIALIZER
        loadFromCache()
    }
    
    //MARK: - Data loading and updating
    private func loadFromCache() -> Void {
        //defaults.removeObject(forKey: PERIOD_NAME_LOCATION_KEY)
        if (defaults.array(forKey: PERIOD_NAME_LOCATION_KEY) != nil){ //&& defaults.array(forKey: PERIOD_NAME_LOCATION_KEY)[7] != "[Data]" //data is found in the local cache
            periodNames = defaults.array(forKey: PERIOD_NAME_LOCATION_KEY) as! [String]
            print("Assigned value of periodNames based on cache data")
        } else { //array is not stored in the cache, write defaults
            periodNames = ["Period 0", "Period 1", "Period 2", "Period 3", "Period 4", "Period 5", "Period 6", "Period 7"]
            defaults.set(periodNames, forKey: PERIOD_NAME_LOCATION_KEY)
            print("Added default array of period names to cache")
        }
        
    }
    
    public func reset() {
        periodNames = ["Period 0", "Period 1", "Period 2", "Period 3", "Period 4", "Period 5", "Period 6", "Period 7"]
        defaults.set(periodNames, forKey: PERIOD_NAME_LOCATION_KEY)
        print("Reset period names to default")
    }
    
    public func updateIndex (indexToModify: Int, newData: String) -> Void {
        periodNames[indexToModify] = newData
        defaults.set(periodNames, forKey: PERIOD_NAME_LOCATION_KEY) //update cached data
        
    }
    
    public func getPeriodNames() -> [String] {
        return self.periodNames
    }
    
    public func customizePeriodName(stringWithDefaultPeriodName: String) -> String {
        switch stringWithDefaultPeriodName {
            //cases
        case "Period 0": return periodNames[0]
        case "Period 1": return periodNames[1]
        case "Period 2": return periodNames[2]
        case "Period 3": return periodNames[3]
        case "Period 4": return periodNames[4]
        case "Period 5": return periodNames[5]
        case "Period 6": return periodNames[6]
        case "Period 7": return periodNames[7]
            //default
        default: return stringWithDefaultPeriodName //don't modify
            
        }
    }
}
