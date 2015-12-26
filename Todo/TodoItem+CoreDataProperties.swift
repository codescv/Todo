//
//  TodoItem+CoreDataProperties.swift
//  Todo
//
//  Created by Chi Zhang on 12/26/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TodoItem {

    @NSManaged var comment: String?
    @NSManaged var hasNotification: NSNumber?
    @NSManaged var isDone: NSNumber?
    @NSManaged var repeatType: NSNumber?
    @NSManaged var notifyDate: NSDate?
    @NSManaged var dueDate: NSDate?
    @NSManaged var title: String?
    @NSManaged var displayOrder: NSNumber?
    @NSManaged var category: TodoItemCategory?

}
