//
//  TodoItem.swift
//  Todo
//
//  Created by Chi Zhang on 12/14/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import Foundation
import CoreData
import DQuery


// reminder repeat type
enum RepeatType: Int {
    case Daily
    case Weekly
    case Monthly
    case Yearly
    
    func name() -> String {
        switch self {
        case .Daily:
            return "Daily"
        case .Weekly:
            return "Weekly"
        case .Monthly:
            return "Monthly"
        case .Yearly:
            return "Yearly"
        }
    }
}


class TodoItem: NSManagedObject {
    
    // get the displayOrder for a newly created item
    class func topDisplayOrder(context: NSManagedObjectContext) -> Int {
        if let item = DQ.query(self, context: context).min("displayOrder").first() {
            if let order = item.displayOrder?.integerValue {
                return order - 1
            }
        }
        return 0
    }
}
