//
//  TodoCategoryViewModel.swift
//  Todo
//
//  Created by Chi Zhang on 1/7/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import Foundation
import CoreData
import DQuery

class TodoCategoryViewModel {
    var categories = [NSManagedObjectID]()
    var categoryOrder = [NSManagedObjectID: Int]()
    
    init () {
        DQ.monitor(self, block: {_ in
            self.reloadDataFromDB()
        })
        print("init cat data controller")
    }
    
    func reloadDataFromDB(completion: (() -> ())? = nil) {
        DQ.query(TodoItemCategory.self).orderBy("displayOrder").execute { (context, objectIds) in
            // TODO fix DQuery to make completion run on main thread
            dispatch_async(dispatch_get_main_queue(), {
                self.categories = objectIds
                self.categoryOrder.removeAll()
                for (idx, id) in objectIds.enumerate() {
                    self.categoryOrder[id] = idx
                }
                completion?()
            })
        }
    }
    
    func orderForCategoryId(categoryId: NSManagedObjectID?) -> Int {
        if categoryId != nil {
            return self.categoryOrder[categoryId!]!
        }
        return -1
    }
}
