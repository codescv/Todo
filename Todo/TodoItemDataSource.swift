//
//  TodoItemCellModel.swift
//  Todo
//
//  Created by Chi Zhang on 1/3/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import Foundation
import CoreData
import DQuery

class TodoItemDataSource {
    private var items = [[TodoItemCellModel]]()
    
    private var categoryId: NSManagedObjectID?
    
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
    
    var numberOfSections: Int {
        return self.items.count
    }
    
    func numberOfItemsInSection(section: Int) -> Int {
        return self.items[section].count
    }
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> TodoItemCellModel {
        return self.items[indexPath.section][indexPath.row]
    }
    
    func itemForId(itemId: NSManagedObjectID, inContext context: NSManagedObjectContext? = nil) -> TodoItemCellModel {
        let item = (context == nil ? DQ.objectWithID(itemId) : context!.dq_objectWithID(itemId)) as! TodoItem
        let vm = TodoItemCellModel()
        vm.title = item.title ?? ""
        vm.objId = item.objectID
        vm.categoryName = item.category?.name ?? ""
        vm.categoryColor = item.category?.color
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
            let items = [todoItemIds.map { self.itemForId($0, inContext: context) }, doneItemIds.map { self.itemForId($0, inContext: context) }]
            print("reloaded items from DB")
            dispatch_async(dispatch_get_main_queue(), {
                self.items = items
                completion?()
            })
        }
    }
    
    func moveTodoItem(fromRow srcRow: Int, toRow destRow: Int) {
        if srcRow == destRow {
            return
        }
        
        var todoItems = self.items[0]
        DQ.write (
            { context in
                let exchangeWithBelow = { (row: Int) in
                    let item: TodoItem = context.dq_objectWithID(todoItems[row].objId!)
                    let nextItem: TodoItem = context.dq_objectWithID(todoItems[row+1].objId!)
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
            },
            sync: false,
            completion: {
                self.items[0] = todoItems
        })
    }
    
    func deleteItemAtIndexPath(indexPath: NSIndexPath) {
        let objId = self.itemAtIndexPath(indexPath).objId!
        self.isChanging = true
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.dq_delete()
            },
            sync: false,
            completion: {
                self.items[indexPath.section].removeAtIndex(indexPath.row)
                self.onChange?([.Delete(indexPaths: [indexPath])])
                self.isChanging = false
        })
    }
    
    func undoItemAtRow(row: Int) {
        let objId = self.items[1][row].objId!
        
        self.isChanging = true
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.displayOrder = TodoItem.topDisplayOrder(context)
                item.isDone = false
            },
            sync: false,
            completion: {
                let item = self.items[1][row]
                self.items[1].removeAtIndex(row)
                self.items[0].insert(item, atIndex: 0)
                let changes: [Change] = [
                    .Delete(indexPaths: [NSIndexPath(forRow: row, inSection: 1)]),
                    .Insert(indexPaths: [NSIndexPath(forRow: row, inSection: 0)])
                ]
                self.onChange?(changes)
                self.isChanging = false
        })
    }

    
    func markTodoItemAsDoneAtRow(row: Int) {
        let objId = self.items[0][row].objId!
        
        self.isChanging = true
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.isDone = true
                item.doneDate = NSDate()
            },
            sync: false,
            completion: {
                let item = self.items[0][row]
                self.items[0].removeAtIndex(row)
                self.items[1].insert(item, atIndex: 0)
                let changes: [Change] = [
                    .Delete(indexPaths: [NSIndexPath(forRow: row, inSection: 0)]),
                    .Insert(indexPaths: [NSIndexPath(forRow: 0, inSection: 1)])
                ]
                self.onChange?(changes)
                self.isChanging = false
        })
    }

    
    func insertTodoItem(title title: String) {
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
                // FIXME: fetch on main thread
                let item = self.itemForId(objId)
                self.items[0].insert(item, atIndex: 0)
                self.onChange?([.Insert(indexPaths:[NSIndexPath(forRow: 0, inSection: 0)])])
                self.isChanging = false
        })
    }
    
    func editTodoItem(model:TodoItemCellModel, title: String) {
        var index: Int = 0
        self.isChanging = true
        DQ.write(
            { context in
                let objId = model.objId!
                for (idx, item) in self.items[0].enumerate() {
                    if item.objId == objId {
                        index = idx
                    }
                }
                let item: TodoItem = context.dq_objectWithID(objId)
                item.title = title
            },
            sync: false,
            completion:  {
                self.onChange?([.Update(indexPaths:[NSIndexPath(forRow: index, inSection: 0)])])
                self.isChanging = false
        })
    }
    
    func changeCategory(model: TodoItemCellModel, categoryId: NSManagedObjectID?) {
        DQ.write(
            { context in
                let item: TodoItem = context.dq_objectWithID(model.objId!)
                if let objId = categoryId {
                    let categoryObj: TodoItemCategory = context.dq_objectWithID(objId)
                    item.category = categoryObj
                }else {
                    item.category = nil
                }
            },
            sync: false,
            completion: {
        })
    }
    
    func editReminder<T>(model: TodoItemCellModel, hasReminder: Bool, reminderDate: NSDate, isRepeated: Bool, repeatType: RepeatType?, repeatValue: T) {
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
        })
    }
}