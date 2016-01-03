//
//  TodoItemViewModel.swift
//  Todo
//
//  Created by Chi Zhang on 1/3/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import Foundation
import CoreData

class TodoItemViewModel {
    let session = DataManager.instance.session
    var todoItems = [NSManagedObjectID]()
    var doneItems = [NSManagedObjectID]()
    
    var onChange: (()->())?
    
    var shouldAutoReloadOnDataChange = true
    
    init(categoryId: NSManagedObjectID? = nil) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataChanged:", name: NSManagedObjectContextObjectsDidChangeNotification, object: session.defaultContext)
    }
    
    @objc func dataChanged(notification: NSNotification) {
//        print("changed: \(notification)")
        if shouldAutoReloadOnDataChange {
            self.reloadDataFromDB({
                self.onChange?()
            })
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextObjectsDidChangeNotification, object: session.defaultContext)
    }
    
    func reloadDataFromDB(completion: (() -> ())? = nil) {
        self.session.query(TodoItem).orderBy("displayOrder").execute({ (context, objectIds) -> Void in
            var todoItems = [NSManagedObjectID]()
            var doneItems = [NSManagedObjectID]()
            for objId in objectIds {
                let item: TodoItem = context.dq_objectWithID(objId)
                if item.isDone?.boolValue == true {
                    doneItems.append(objId)
                } else {
                    todoItems.append(objId)
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.todoItems = todoItems
                self.doneItems = doneItems
//                print("loaded from db")
                completion?()
            })
        })
    }
    
    func moveTodoItem(fromRow srcRow: Int, toRow destRow: Int, completion: (()->())? = nil) {
        if srcRow == destRow {
            return
        }
        
        self.shouldAutoReloadOnDataChange = false

        self.session.write (
            { context in
                var todoItems = self.todoItems
                
                let exchangeWithBelow = { (row: Int) in
                    let item: TodoItem = context.dq_objectWithID(todoItems[row])
                    let nextItem: TodoItem = context.dq_objectWithID(todoItems[row+1])
                    swap(&item.displayOrder, &nextItem.displayOrder)
                    swap(&todoItems[row], &todoItems[row+1])
                }
                
                if srcRow < destRow {
                    for row in srcRow..<destRow {
                        exchangeWithBelow(row)
                    }
                } else {
                    for row in (destRow..<srcRow).reverse() {
                        exchangeWithBelow(row)
                    }
                }
                
                dispatch_sync(dispatch_get_main_queue(), {
                    self.todoItems = todoItems
                })
            },
            sync: false,
            completion: {
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
        
    }
}