//
//  AppDelegate.swift
//  Todo
//
//  Created by Chi Zhang on 12/14/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit
import CoreData
import DQuery

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    override init() {
        // make sure Core Data context is initialized before any view controller
        DQ.config([.ModelName: "Todo", .StoreType: StoreType.SQLite])
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // load tutorial items if this is the first start
        GlobalTutorialItems.loadTutorialItemsIfFirstStart()
        
        let types: UIUserNotificationType = [.Badge, .Sound, .Alert]
        let settings = UIUserNotificationSettings(forTypes: types, categories: nil)
        application.registerUserNotificationSettings(settings)
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        for item in DQ.query(TodoItem).filter("hasReminder = true").filter("isDone = false").all() {
            
            var dates:Set<NSDate> = [item.reminderDate!]
            var interval: NSCalendarUnit = []
            let isRepeated = item.isRepeated?.boolValue == true
            if isRepeated {
                if let repeatTypeInt = item.repeatType?.integerValue {
                    if let repeatType = RepeatType(rawValue: repeatTypeInt) {
                        switch repeatType {
                        case .Daily:
                            interval = NSCalendarUnit.Day
                        case .Weekly:
                            interval = NSCalendarUnit.Weekday
                            
                            if let v = item.repeatValue {
                                if let weekdays = NSKeyedUnarchiver.unarchiveObjectWithData(v) as? Set<Int> {
                                    dates = Set<NSDate>(weekdays.map{ item.reminderDate!.nearestWeekday($0) })
                                }
                            }
                        case .Monthly:
                            interval = NSCalendarUnit.Month
                        case .Yearly:
                            interval = NSCalendarUnit.Year
                        }
                    }
                }
            }
            for date in dates {
                let notif = UILocalNotification()
                notif.alertTitle = "alert"
                notif.alertBody = item.title
                notif.fireDate = date
                if isRepeated {
                    notif.repeatInterval = interval
                }
                application.scheduleLocalNotification(notif)
            }
        }
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        application.cancelAllLocalNotifications()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

    
}

