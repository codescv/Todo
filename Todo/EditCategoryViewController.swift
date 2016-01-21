//
//  EditCategoryViewController.swift
//  Todo
//
//  Created by 陳小晶 on 16/1/20.
//  Copyright © 2016年 chi zhang. All rights reserved.
//

import UIKit
import CoreData
import DQuery

class EditCategoryViewController: UITableViewController {
    @IBOutlet weak var categoryNameTextfield: UITextField!

    var categoryName: String {
        return self.categoryNameTextfield.text ?? ""
    }
    
    var categoryColor: UIColor {
        return UIColor.redColor()
    }
    
    var categoryId: NSManagedObjectID?
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "saveCategory" {
            return !(self.categoryNameTextfield.text?.isEmpty == true)
        }
        
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let categoryId = self.categoryId {
            let category: TodoItemCategory = DQ.objectWithID(categoryId)
            self.categoryNameTextfield.text = category.name
        }
    }
    
}
