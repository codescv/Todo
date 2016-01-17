//
//  TodoItem+CoreDataProperties.swift
//  Todo
//
//  Created by 陳小晶 on 16/1/17.
//  Copyright © 2016年 chi zhang. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TodoItem {

    @NSManaged var comment: String?
    @NSManaged var displayOrder: NSNumber?
    @NSManaged var doneDate: NSDate?
    @NSManaged var dueDate: NSDate?
    @NSManaged var hasReminder: NSNumber?
    @NSManaged var isDone: NSNumber?
    @NSManaged var reminderDate: NSDate?
    @NSManaged var repeatType: NSNumber?
    @NSManaged var title: String?
    @NSManaged var repeatValue: NSData?
    @NSManaged var isRepeated: NSNumber?
    @NSManaged var category: TodoItemCategory?

}
