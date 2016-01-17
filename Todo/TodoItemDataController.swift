//
//  TodoItemViewModel.swift
//  Todo
//
//  Created by Chi Zhang on 1/3/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import Foundation
import CoreData
import DQuery

class TodoItemDataController {
    private var todoItemIds = [NSManagedObjectID]()
    private var doneItemIds = [NSManagedObjectID]()
    var categoryId: NSManagedObjectID?
    
    // data change callback
    var onChange: (()->())?
    var shouldAutoReloadOnDataChange = true
    
    init(categoryId: NSManagedObjectID? = nil) {
        self.categoryId = categoryId
        DQ.monitor(self) {[weak self] _ in
            if self?.shouldAutoReloadOnDataChange == true {
                self?.reloadDataFromDB()
            }
        }
    }
    
    deinit {
        print("deinit todo item data controller")
    }
    
    var todoItemsCount: Int {
        return self.todoItemIds.count
    }
    
    var doneItemsCount: Int {
        return self.doneItemIds.count
    }
    
    func todoItemAtRow(row: Int) -> TodoItemViewModel {
        let itemId = self.todoItemIds[row]
        let item: TodoItem = DQ.objectWithID(itemId)
        let vm = TodoItemViewModel()
        vm.title = item.title ?? ""
        vm.objId = item.objectID
        vm.categoryName = item.category?.name ?? ""
        vm.hasReminder = item.hasReminder == true ? true: false
        vm.reminderDate = item.reminderDate ?? NSDate()
        vm.repeatType = item.repeatType?.integerValue ?? 0
        return vm
    }
    
    func doneItemAtRow(row: Int) -> DoneItemViewModel {
        let itemId = self.doneItemIds[row]
        let item: TodoItem = DQ.objectWithID(itemId)
        let vm = DoneItemViewModel()
        vm.title = item.title ?? ""
        return vm
    }

    func reloadDataFromDB(completion: (() -> ())? = nil) {
        var query = DQ.query(TodoItem).orderBy("displayOrder")
        if let categoryId = self.categoryId {
            query = query.filter("category = %@", categoryId)
        }
        query.execute { (context, objectIds) -> Void in
            var todoItemIds = [NSManagedObjectID]()
            var doneItemIds = [NSManagedObjectID]()
            for objId in objectIds {
                let item: TodoItem = context.dq_objectWithID(objId)
                if item.isDone?.boolValue == true {
                    doneItemIds.append(objId)
                } else {
                    todoItemIds.append(objId)
                }
                doneItemIds.sortInPlace {(id1, id2) in
                    let item1: TodoItem = context.dq_objectWithID(id1)
                    let item2: TodoItem = context.dq_objectWithID(id2)
                    return item1.doneDate!.compare(item2.doneDate!) == .OrderedDescending
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.todoItemIds = todoItemIds
                self.doneItemIds = doneItemIds
                completion?()
            })
        }
    }
    
    func moveTodoItem(fromRow srcRow: Int, toRow destRow: Int, completion: (()->())? = nil) {
        if srcRow == destRow {
            return
        }
        
        self.shouldAutoReloadOnDataChange = false

        var todoItemIds = self.todoItemIds
        DQ.write (
            { context in
                let exchangeWithBelow = { (row: Int) in
                    let item: TodoItem = context.dq_objectWithID(todoItemIds[row])
                    let nextItem: TodoItem = context.dq_objectWithID(todoItemIds[row+1])
                    swap(&item.displayOrder, &nextItem.displayOrder)
                    swap(&todoItemIds[row], &todoItemIds[row+1])
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
            },
            sync: false,
            completion: {
                self.todoItemIds = todoItemIds
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
        
    }
    
    func deleteTodoItemAtRow(row: Int, completion: (()->())?) {
        let objId = self.todoItemIds[row]
        
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.dq_delete()
            },
            sync: false,
            completion: {
                self.todoItemIds.removeAtIndex(row)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }
    
    func deleteDoneItemAtRow(row: Int, completion: (()->())?) {
        let objId = self.doneItemIds[row]
        
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.dq_delete()
            },
            sync: false,
            completion: {
                self.doneItemIds.removeAtIndex(row)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }
    
    func undoItemAtRow(row: Int, completion: (()->())?) {
        let objId = self.doneItemIds[row]
        
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.isDone = false
            },
            sync: false,
            completion: {
                self.doneItemIds.removeAtIndex(row)
                self.todoItemIds.insert(objId, atIndex: 0)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }

    
    func markTodoItemAsDoneAtRow(row: Int, completion: (()->())?) {
        let objId = self.todoItemIds[row]
        
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.isDone = true
                item.doneDate = NSDate()
            },
            sync: false,
            completion: {
                self.todoItemIds.removeAtIndex(row)
                self.doneItemIds.insert(objId, atIndex: 0)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }

    
    func insertTodoItem(title title: String, completion: (()->())?) {
        self.shouldAutoReloadOnDataChange = false
        DQ.insertObject(TodoItem.self,
            block: {context, item in
                item.title = title
                item.dueDate = NSDate.today()
                item.displayOrder = TodoItem.topDisplayOrder(context)
                if let categoryId = self.categoryId {
                    item.category = context.dq_objectWithID(categoryId) as TodoItemCategory
                }
            },
            sync: false,
            completion: { objId in
                self.todoItemIds.insert(objId, atIndex: 0)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }
    
    func editTodoItem(model:TodoItemViewModel, title: String, completion: (()->())?) {
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            { context in
                let item: TodoItem = context.dq_objectWithID(model.objId!)
                item.title = title
            },
            sync: false,
            completion:  {
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }
    
    func changeCategory(model: TodoItemViewModel, category: TodoCategoryViewModel, completion: (()->())?) {
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            { context in
                let item: TodoItem = context.dq_objectWithID(model.objId!)
                if let objId = category.objId {
                    let categoryObj: TodoItemCategory = context.dq_objectWithID(objId)
                    item.category = categoryObj
                }else {
                    item.category = nil
                }
            },
            sync: false,
            completion: {
                self.reloadDataFromDB() {
                    completion?()
                    self.shouldAutoReloadOnDataChange = true
                }
        })
    }
    
    func editReminder<T:NSCoding>(model: TodoItemViewModel, hasReminder: Bool, reminderDate: NSDate, isRepeated: Bool, repeatType: Int, repeatValue: T, completion: (()->())?) {
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            { context in
                let item: TodoItem = context.dq_objectWithID(model.objId!)
                item.hasReminder = hasReminder
                item.reminderDate = reminderDate
                item.isRepeated = isRepeated
                item.repeatType = repeatType
                item.repeatValue = NSKeyedArchiver.archivedDataWithRootObject(repeatValue)
            },
            sync: false,
            completion: {
                self.reloadDataFromDB() {
                    completion?()
                    self.shouldAutoReloadOnDataChange = true
                }
        })
    }
}