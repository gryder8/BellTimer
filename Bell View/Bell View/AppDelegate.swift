//
//  AppDelegate.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/11/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

//https://stackoverflow.com/questions/30426501/prevent-deploying-disable-watchkit-app-with-ios-iphone-app-in-xcode?noredirect=1&lq=1

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    //MARK: - Singletons
    var myMasterView: ViewController = ViewController.shared
    private let master: ScheduleMaster = ScheduleMaster.shared
    
    //MARK: - Application state handlers
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        myMasterView.setState(active: true)
        return true
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        myMasterView.setState(active: false)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        myMasterView.setState(active: false)
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if (master.isConnectedToNetwork()){
            master.clearEtagsIfNeeded()
        }
        myMasterView.setState(active: true)
        if (myMasterView.isWatchConnected()){
            myMasterView.sendDataToWatch()
        }
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        myMasterView.setState(active: true)
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        myMasterView.setState(active: false)
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

