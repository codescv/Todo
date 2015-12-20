//
//  TodoItemCategory+CoreDataProperties.swift
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

extension TodoItemCategory {

    @NSManaged var name: String?
    @NSManaged var color: NSNumber?
    @NSManaged var priority: NSNumber?
    @NSManaged var items: NSSet?

}
