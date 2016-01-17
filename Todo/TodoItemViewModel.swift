//
//  TodoItemViewModel.swift
//  Todo
//
//  Created by 陳小晶 on 16/1/14.
//  Copyright © 2016年 chi zhang. All rights reserved.
//

import Foundation
import CoreData

class TodoItemViewModel {
    var title: String = ""
    var categoryName: String?
    var isExpanded: Bool = false
    var objId: NSManagedObjectID?
    
    var hasReminder = false
    var reminderDate = NSDate()
    var isRepeated = false
    var repeatType = 0
    var repeatValue: AnyObject?
}