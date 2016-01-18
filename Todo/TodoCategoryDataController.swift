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

class TodoCategoryDataController {
    private var categoryIds = [NSManagedObjectID]()
    private var categoryOrder = [NSManagedObjectID: Int]()
    private var totalItems = 0
    
    private var shouldAutoReload = false
    
    enum Change {
        case Delete(indexPaths: [NSIndexPath])
        case Insert(indexPaths: [NSIndexPath])
        case Update(indexPaths: [NSIndexPath])
    }
    
    var isChanging = false
    var onChange: (([Change])->())?
    
    init () {
        DQ.monitor(self) { [weak self] _ in
            if let myself = self {
                if !myself.isChanging {
                    myself.reloadDataFromDB {
                        if !myself.isChanging {
                            myself.onChange?([])
                        }
                    }
                }
            }
        }
    }
    
    deinit {
        print("deinit category data controller")
    }
    
    func reloadDataFromDB(completion: (() -> ())? = nil) {
        print("reload category data")
        
        DQ.query(TodoItemCategory.self).orderBy("displayOrder").execute { (context, objectIds) in
            // TODO fix DQuery to make completion run on main thread
            let count = DQ.query(TodoItem.self, context: context).count()
            dispatch_async(dispatch_get_main_queue(), {
                self.categoryIds = objectIds
                self.categoryOrder.removeAll()
                for (idx, id) in objectIds.enumerate() {
                    self.categoryOrder[id] = idx
                }
                self.totalItems = count
                completion?()
            })
        }
        
        // TODO let DQuery provide async count
//        DQ.query(TodoItem).execute {
//            let count = $1.count
//            dispatch_async(dispatch_get_main_queue(), {
//                self.totalItems = count
//            })
//        }
    }
    
    func orderForCategoryId(categoryId: NSManagedObjectID?) -> Int {
        if categoryId != nil {
            return self.categoryOrder[categoryId!]!
        }
        return -1
    }
    
    var numberOfCategories: Int {
        return self.categoryIds.count + 1
    }
    
    func categoryAtRow(row: Int) -> TodoCategoryViewModel {
        let objId: NSManagedObjectID? = (row == 0 ? nil : self.categoryIds[row-1])
        let vm = TodoCategoryViewModel()
        vm.objId = objId
        if let categoryId = objId {
            let category: TodoItemCategory = DQ.objectWithID(categoryId)
            vm.name = category.name ?? ""
            vm.numberOfItems = category.items?.count ?? 0
        } else {
            vm.name = "All"
            vm.numberOfItems = self.totalItems
        }
        return vm
    }
    
    func insertNewCategory(name: String, completion: (()->())? = nil) {
        self.isChanging = true
        DQ.insertObject(TodoItemCategory.self,
            block: { (context, category) in
                category.name = name
                category.displayOrder = TodoItemCategory.lastDisplayOrder(context)
            },
            completion: { categoryId in
                self.categoryIds.append(categoryId)
                self.onChange?([.Insert(indexPaths: [NSIndexPath(forRow: self.categoryIds.count, inSection: 0)])])
                completion?()
                self.isChanging = false
        })
    }
    
    func editCategory(item: TodoCategoryViewModel, newName: String, completion: (()->())? = nil) {
        DQ.write(
            { context in
                let item: TodoItemCategory = context.dq_objectWithID(item.objId!)
                item.name = newName
            },
            sync: false,
            completion:  {
                completion?()
        })
    }
    
    func deleteCategoryAtRow(row: Int, completion: (()->())? = nil) {
        let r = row - 1
        let categoryId = self.categoryIds[r]
        self.isChanging = true
        DQ.write(
            { context in
                let obj: TodoItemCategory = context.dq_objectWithID(categoryId)
                obj.dq_delete()
            },
            sync: false,
            completion: {
                completion?()
                self.categoryIds.removeAtIndex(r)
                self.onChange?([.Delete(indexPaths: [NSIndexPath(forRow: row, inSection: 0)])])
                self.isChanging = false
        })
    }
}
