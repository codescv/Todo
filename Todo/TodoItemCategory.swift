//
//  TodoItemCategory.swift
//  Todo
//
//  Created by Chi Zhang on 12/19/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import Foundation
import CoreData
import DQuery


class TodoItemCategory: NSManagedObject {
    
//    class func categoryNamed(name: String, context: NSManagedObjectContext = session.defaultContext) -> TodoItemCategory {
//        let query = DQ.query(TodoItemCategory.self).filter("name = %@", name)
//        var categoryId: NSManagedObjectID!
//        if query.count() > 0 {
//            categoryId = query.first()!.objectID
//        } else {
//            DQ.write({ (context) in
//                let category = TodoItemCategory.dq_insertInContext(context)
//                category.name = name
//                categoryId = category.objectID
//            }, sync: true)
//        }
//        return context.dq_objectWithID(categoryId)
//    }
    
//    class func defaultCategory(context: NSManagedObjectContext = session.defaultContext) -> TodoItemCategory {
//        return categoryNamed("default")
//    }
}
