//
//  AppSettings.swift
//  Todo
//
//  Created by Chi Zhang on 2/2/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import Foundation

let GlobalAppSettings = AppSettings.sharedSettings

class AppSettings {
    static let sharedSettings = AppSettings()
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    var isFirstStart: Bool {
        get {
            return defaults.objectForKey("isFirstStart")?.boolValue != false
        }
        
        set {
            defaults.setBool(newValue, forKey: "isFirstStart")
        }
    }
}