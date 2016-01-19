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
    
    enum Change {
        case Delete(indexPaths: [NSIndexPath])
        case Insert(indexPaths: [NSIndexPath])
        case Update(indexPaths: [NSIndexPath])
        case Move(fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath)
    }
    
    // data change callback
    var onChange: (([Change])->())?
    
    // is the controller changing the data
    var isChanging = false
    
    init(categoryId: NSManagedObjectID? = nil) {
        self.categoryId = categoryId
        DQ.monitor(self) {[weak self] notification in
            if let myself = self {
                if !myself.isChanging {
                    myself.reloadDataFromDB() {
                        if !myself.isChanging {
                            myself.onChange?([])
                        }
                    }
                }
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
        vm.hasReminder = item.hasReminder == true
        vm.reminderDate = item.reminderDate ?? NSDate()
        vm.isRepeated = item.isRepeated == true
        if let repeatTypeInt = item.repeatType?.integerValue {
            vm.repeatType = RepeatType(rawValue: repeatTypeInt)
        }
        
        if let repeatValue = item.repeatValue {
            if let repeatValueSet =  NSKeyedUnarchiver.unarchiveObjectWithData(repeatValue) as? Set<Int> {
                vm.repeatValue = repeatValueSet
            }
        }
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
            print("reloaded items from DB")
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
        })
    }
    
    func deleteTodoItemAtRow(row: Int, completion: (()->())? = nil) {
        let objId = self.todoItemIds[row]
        
        self.isChanging = true
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.dq_delete()
            },
            sync: false,
            completion: {
                self.todoItemIds.removeAtIndex(row)
                self.onChange?([.Delete(indexPaths: [NSIndexPath(forRow: row, inSection: 0)])])
                completion?()
                self.isChanging = false
        })
    }
    
    func deleteDoneItemAtRow(row: Int, completion: (()->())? = nil) {
        let objId = self.doneItemIds[row]
        
        self.isChanging = true
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.dq_delete()
            },
            sync: false,
            completion: {
                self.doneItemIds.removeAtIndex(row)
                self.onChange?([.Delete(indexPaths: [NSIndexPath(forRow: row, inSection: 1)])])
                completion?()
                self.isChanging = false
        })
    }
    
    func undoItemAtRow(row: Int, completion: (()->())? = nil) {
        let objId = self.doneItemIds[row]
        
        self.isChanging = true
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.isDone = false
            },
            sync: false,
            completion: {
                self.doneItemIds.removeAtIndex(row)
                self.todoItemIds.insert(objId, atIndex: 0)
                let changes: [Change] = [
                    .Delete(indexPaths: [NSIndexPath(forRow: row, inSection: 1)]),
                    .Insert(indexPaths: [NSIndexPath(forRow: row, inSection: 0)])
                ]
                self.onChange?(changes)
                completion?()
                self.isChanging = false
        })
    }

    
    func markTodoItemAsDoneAtRow(row: Int, completion: (()->())? = nil) {
        let objId = self.todoItemIds[row]
        
        self.isChanging = true
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
                let changes: [Change] = [
                    .Delete(indexPaths: [NSIndexPath(forRow: row, inSection: 0)]),
                    .Insert(indexPaths: [NSIndexPath(forRow: 0, inSection: 1)])
                ]
                self.onChange?(changes)
                completion?()
                self.isChanging = false
        })
    }

    
    func insertTodoItem(title title: String, completion: (()->())? = nil) {
        self.isChanging = true
        DQ.insertObject(TodoItem.self,
            block: {context, item in
                item.title = title
                item.dueDate = NSDate.today()
                item.isDone = false
                item.displayOrder = TodoItem.topDisplayOrder(context)
                if let categoryId = self.categoryId {
                    item.category = context.dq_objectWithID(categoryId) as TodoItemCategory
                }
            },
            sync: false,
            completion: { objId in
                self.todoItemIds.insert(objId, atIndex: 0)
                self.onChange?([.Insert(indexPaths:[NSIndexPath(forRow: 0, inSection: 0)])])
                completion?()
                self.isChanging = false
        })
    }
    
    func editTodoItem(model:TodoItemViewModel, title: String, completion: (()->())? = nil) {
        var index: Int = 0
        self.isChanging = true
        DQ.write(
            { context in
                let objId = model.objId!
                index = self.todoItemIds.indexOf(objId)!
                let item: TodoItem = context.dq_objectWithID(objId)
                item.title = title
            },
            sync: false,
            completion:  {
                self.onChange?([.Update(indexPaths:[NSIndexPath(forRow: index, inSection: 0)])])
                completion?()
                self.isChanging = false
        })
    }
    
    func changeCategory(model: TodoItemViewModel, category: TodoCategoryViewModel, completion: (()->())? = nil) {
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
                completion?()
        })
    }
    
    func editReminder<T>(model: TodoItemViewModel, hasReminder: Bool, reminderDate: NSDate, isRepeated: Bool, repeatType: RepeatType?, repeatValue: T, completion: (()->())? = nil) {
        DQ.write(
            { context in
                let item: TodoItem = context.dq_objectWithID(model.objId!)
                item.hasReminder = hasReminder
                item.reminderDate = reminderDate
                item.isRepeated = isRepeated
                item.repeatType = repeatType?.rawValue
                if let repeatValueSet = repeatValue as? NSSet {
                    item.repeatValue = NSKeyedArchiver.archivedDataWithRootObject(repeatValueSet)
                }
            },
            sync: false,
            completion: {
                completion?()
        })
    }
}