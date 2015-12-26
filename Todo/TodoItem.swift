//
//  TodoItem.swift
//  Todo
//
//  Created by Chi Zhang on 12/14/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import Foundation
import CoreData


class TodoItem: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    class func topDisplayOrder(context: NSManagedObjectContext) -> Int {
        let session = DataManager.instance.session
        if let item = session.query(self, context: context).min("displayOrder").first() {
            if let order = item.displayOrder?.integerValue {
                return order - 1
            }
        }
        return 0
    }
}
