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
    var categoryId: NSManagedObjectID?
    
    // data change callback
    var onChange: (()->())?
    var shouldAutoReloadOnDataChange = true
    
    init(categoryId: NSManagedObjectID? = nil) {
        self.categoryId = categoryId
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataChanged:", name: NSManagedObjectContextObjectsDidChangeNotification, object: session.defaultContext)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextObjectsDidChangeNotification, object: session.defaultContext)
    }
    
    @objc func dataChanged(notification: NSNotification) {
        //        print("changed: \(notification)")
        if shouldAutoReloadOnDataChange {
            self.reloadDataFromDB({
                self.onChange?()
            })
        }
    }
    
    func reloadDataFromDB(completion: (() -> ())? = nil) {
        var query = self.session.query(TodoItem).orderBy("displayOrder")
        if let categoryId = self.categoryId {
            // FIXME: does this work?
            query = query.filter("category = %@", categoryId)
        }
        query.execute({ (context, objectIds) -> Void in
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
            // TODO: sort done items by done time
            dispatch_async(dispatch_get_main_queue(), {
                self.todoItems = todoItems
                self.doneItems = doneItems
                print("reloaded todo items from db")
                completion?()
            })
        })
    }
    
    func moveTodoItem(fromRow srcRow: Int, toRow destRow: Int, completion: (()->())? = nil) {
        if srcRow == destRow {
            return
        }
        
        self.shouldAutoReloadOnDataChange = false

        var todoItems = self.todoItems
        self.session.write (
            { context in
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
    
    func deleteTodoItemAtRow(row: Int, completion: (()->())?) {
        let objId = self.todoItems[row]
        
        self.shouldAutoReloadOnDataChange = false
        self.session.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.dq_delete()
            },
            sync: false,
            completion: {
                self.todoItems.removeAtIndex(row)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }
    
    func markTodoItemAsDoneAtRow(row: Int, completion: (()->())?) {
        let objId = self.todoItems[row]
        
        self.shouldAutoReloadOnDataChange = false
        self.session.write(
            {context in
                // TODO: done time
                let item: TodoItem = context.dq_objectWithID(objId)
                item.isDone = true
            },
            sync: false,
            completion: {
                self.todoItems.removeAtIndex(row)
                self.doneItems.insert(objId, atIndex: 0)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }

    
    func insertTodoItem(title title: String, completion: (()->())?) {
        self.shouldAutoReloadOnDataChange = false
        self.session.write({ (context) in
            let item: TodoItem = TodoItem.dq_insertInContext(context)
            item.title = title
            item.dueDate = NSDate.today()
            item.displayOrder = TodoItem.topDisplayOrder(context)
            if let categoryId = self.categoryId {
                item.category = context.dq_objectWithID(categoryId) as TodoItemCategory
            }
            
            }, sync:false, completion: {
                //self.todoItems.insert(, atIndex: 0)
                self.reloadDataFromDB {
                    completion?()
                    self.shouldAutoReloadOnDataChange = true
                }
        })

    }
}