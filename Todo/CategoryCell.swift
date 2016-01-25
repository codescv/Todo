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
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var bgCardView: UIView!
    
    @IBOutlet weak var summaryStackView: UIStackView!
    
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
    
    var model: CategoryCellModel? {
        didSet {
            if let md = model {
                self.categoryNameLabel.text = "\(md.name)(\(md.numberOfItems))"
                self.editButton.hidden = !md.editable
                self.topBar.backgroundColor = md.color
                let summaryCount = md.summaryItems?.count ?? 0
                for (idx, view) in self.summaryStackView.subviews.enumerate() {
                    if let label = view as? UILabel {
                        if idx < summaryCount {
                            label.text = md.summaryItems![idx]
                            //label.hidden = false
                        } else {
                            label.text = ""
                            //label.hidden = true
                        }
                    }
                }
            }
        }
    }
    
    override func awakeFromNib() {
//        self.bgCardView.layer.shadowColor = UIColor.grayColor().CGColor
//        self.bgCardView.layer.shadowOffset = CGSizeMake(1, 1)
//        self.bgCardView.layer.shadowOpacity = 1.0
        self.bgCardView.layer.cornerRadius = 10.0
        self.bgCardView.clipsToBounds = true
    }

}
