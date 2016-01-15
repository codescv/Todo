//
//  CategoryCell.swift
//  Todo
//
//  Created by Chi Zhang on 12/19/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit

class CategoryCell: UICollectionViewCell {

    @IBOutlet weak var categoryNameLabel: UILabel!
    @IBOutlet weak var categoryInfoLabel: UILabel!
    @IBOutlet weak var editingControls: UIStackView!
    
    @IBAction func editAction(sender: AnyObject) {
        self.actionTriggered?(self, .Edit)
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        self.actionTriggered?(self, .Delete)
    }
    
    enum Action {
        case Edit
        case Delete
    }
    
    var actionTriggered: ((CategoryCell, Action)->())?
    
    var model: TodoCategoryViewModel? {
        didSet {
            if model != nil {
                self.categoryNameLabel.text = model!.name
                self.categoryInfoLabel.text = "\(model!.numberOfItems) Items"
                if model!.objId == nil {
                    self.editingControls.hidden = true
                } else {
                    self.editingControls.hidden = !(model!.showsEditingControls)
                }
            } else {
                self.categoryNameLabel.text = ""
                self.categoryInfoLabel.text = "0 Items"
                self.editingControls.hidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        self.layer.borderColor = UIColor.grayColor().CGColor
        self.layer.borderWidth = 1
        self.editingControls.hidden = true
    }

}
