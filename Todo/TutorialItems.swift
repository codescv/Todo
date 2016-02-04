//
//  TutorialItems.swift
//  Todo
//
//  Created by Chi Zhang on 2/2/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import Foundation
import DQuery
import CoreData

let GlobalTutorialItems = TutorialItems()

class TutorialItems {
    static let items = TutorialItems()
    
    func loadTutorialItemsIfFirstStart() {
        if GlobalAppSettings.isFirstStart {
            loadTutorialItemsIntoDB()
            GlobalAppSettings.isFirstStart = false
        }
    }
    
    let categories = [("Work", CategoryColor.Blue), ("Life", CategoryColor.Orange), ("Shopping", CategoryColor.Red)]
    let tutorials = ["Swipe right to mark as done.", "Tap to show more options.", "Long tap to reorder items.", "Press + to create a new item.", "Press top left icon to manage lists."]
    
    private func loadTutorialItemsIntoDB() {
        // create sample categories
        for (idx, (categoryName, categoryColor)) in self.categories.enumerate() {
            DQ.insertObject(TodoItemCategory.self, block: { (context, category) -> Void in
                category.name = categoryName
                category.colorType = categoryColor.rawValue
                category.displayOrder = idx
            }, completion:nil)
        }
        
        // tutorial category
        DQ.insertObject(TodoItemCategory.self,
            block: { (context, category) -> Void in
                category.name = "Tutorial"
                category.colorType = CategoryColor.Green.rawValue
                category.displayOrder = self.categories.count
            }, completion: { categoryId in
                DQ.write({ context in
                    let category: TodoItemCategory = context.dq_objectWithID(categoryId)
                    for text in self.tutorials.reverse() {
                        let tutorial = TodoItem.dq_insertInContext(context)
                        tutorial.title = text
                        tutorial.displayOrder = TodoItem.topDisplayOrder(context)
                        tutorial.isDone = false
                        tutorial.category = category
                    }
                    
                    let tutorial = TodoItem.dq_insertInContext(context)
                    tutorial.title = "Swipe left to undo."
                    tutorial.displayOrder = TodoItem.topDisplayOrder(context)
                    tutorial.isDone = true
                    tutorial.category = category
                })
        })
    }

}