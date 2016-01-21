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

class TodoCategoryDataSource {
    private var categoryList = [CategoryCellModel]()
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
            
            var categoryList: [CategoryCellModel] = objectIds.map { objId in
                let category: TodoItemCategory = context.dq_objectWithID(objId)
                let cat = CategoryCellModel()
                cat.name = category.name ?? ""
                cat.numberOfItems = category.items?.count ?? 0
                cat.objId = objId
                cat.editable = true
                return cat
            }
            
            // the "All" pseudo category
            let catAll = CategoryCellModel()
            catAll.name = "all"
            let totalItems = DQ.query(TodoItem.self, context: context).count()
            catAll.numberOfItems = totalItems
            catAll.editable = false
            categoryList.insert(catAll, atIndex: 0)
            
            // set indexPaths to view model
            for (idx, cat) in self.categoryList.enumerate() {
                cat.indexPath = NSIndexPath(forRow: idx, inSection: 0)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.categoryList = categoryList
                completion?()
            })
        }
        
    }
    
    var numberOfCategories: Int {
        return self.categoryList.count
    }
    
    func indexPathForCategoryId(categoryId: NSManagedObjectID?) -> NSIndexPath {
        for (idx, cat) in self.categoryList.enumerate() {
            if cat.objId == categoryId {
                return NSIndexPath(forRow: idx, inSection: 0)
            }
        }
        return NSIndexPath(forRow: 0, inSection: 0)
    }
    
    func categoryAtIndexPath(indexPath: NSIndexPath) -> CategoryCellModel {
        return self.categoryList[indexPath.row]
    }
    
    func insertNewCategory(name: String) {
        self.isChanging = true
        DQ.insertObject(TodoItemCategory.self,
            block: { (context, category) in
                category.name = name
                category.displayOrder = TodoItemCategory.lastDisplayOrder(context)
            },
            completion: { categoryId in
                let vm = CategoryCellModel()
                vm.name = name
                vm.numberOfItems = 0
                vm.editable = true
                self.categoryList.append(vm)
                let lastItem = self.categoryList.count-1
                self.onChange?([.Insert(indexPaths: [NSIndexPath(forRow: lastItem, inSection: 0)])])
                self.isChanging = false
        })
    }
    
    func editCategory(item: CategoryCellModel, newName: String) {
        self.editCategoryWithId(item.objId!, newName: newName)
    }
    
    func editCategoryWithId(categoryId: NSManagedObjectID, newName: String) {
        DQ.write(
            { context in
                let item: TodoItemCategory = context.dq_objectWithID(categoryId)
                item.name = newName
            },
            sync: false,
            completion:  {
        })
    }
    
    func deleteCategoryWithId(categoryId: NSManagedObjectID) {
        DQ.write(
            { context in
                let obj: TodoItemCategory = context.dq_objectWithID(categoryId)
                obj.dq_delete()
            },
            sync: false,
            completion: {
        })
    }
    
    func deleteCategory(item: CategoryCellModel) {
        let categoryId = item.objId!
        let row = item.indexPath?.row ?? 0
        self.isChanging = true
        DQ.write(
            { context in
                let obj: TodoItemCategory = context.dq_objectWithID(categoryId)
                obj.dq_delete()
            },
            sync: false,
            completion: {
                self.categoryList.removeAtIndex(row)
                self.onChange?([.Delete(indexPaths: [NSIndexPath(forRow: row, inSection: 0)])])
                self.isChanging = false
        })
    }
}
