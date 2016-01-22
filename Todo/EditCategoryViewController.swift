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

    @IBOutlet weak var colorStackView: UIStackView!
    
    @IBAction func chooseColor(button: UIButton) {
        if let index = self.colorStackView.subviews.indexOf(button) {
            self.selectColorAtIndex(index)
        }
    }
    
    var categoryName: String {
        return self.categoryNameTextfield.text ?? ""
    }
    
    var categoryColor: Int = 0
    
    var categoryId: NSManagedObjectID?
    
    private let colors = CategoryColor.all()
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "saveCategory" {
            return !(self.categoryNameTextfield.text?.isEmpty == true)
        }
        
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupColors()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        var colorType = 0
        if let categoryId = self.categoryId {
            let category: TodoItemCategory = DQ.objectWithID(categoryId)
            self.categoryNameTextfield.text = category.name
            colorType = category.colorType?.integerValue ?? 0
        }
        
        self.selectColorAtIndex(colorType)
    }
    
    private func unselectAllColors() {
        for view in self.colorStackView.subviews {
            if let button = view as? UIButton {
                button.setTitle("", forState: .Normal)
            }
        }
    }
    
    private func selectColorAtIndex(index: Int) {
        unselectAllColors()
        if let button = self.colorStackView.subviews[index] as? UIButton {
            button.setTitle("✓", forState: .Normal)
            self.categoryColor = index
        }
    }
    
    private func setupColors() {
        for (idx, view) in self.colorStackView.subviews.enumerate() {
            if let button = view as? UIButton {
                button.backgroundColor = colors[idx].color()
            }
        }
    }
}
