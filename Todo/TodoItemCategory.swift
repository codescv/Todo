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
    
    class func lastDisplayOrder(context: NSManagedObjectContext) -> Int {
        if let item = DQ.query(self, context: context).max("displayOrder").first() {
            if let order = item.displayOrder?.integerValue {
                return order + 1
            }
        }
        return 0
    }

}
