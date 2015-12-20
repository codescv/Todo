//
//  TodoItem+CoreDataProperties.swift
//  Todo
//
//  Created by Chi Zhang on 12/19/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TodoItem {

    @NSManaged var comment: String?
    @NSManaged var expireDate: NSDate?
    @NSManaged var hasNotification: NSNumber?
    @NSManaged var isRepeated: NSNumber?
    @NSManaged var notifyDate: NSDate?
    @NSManaged var startDate: NSDate?
    @NSManaged var title: String?
    @NSManaged var isDone: NSNumber?
    @NSManaged var category: TodoItemCategory?

}
