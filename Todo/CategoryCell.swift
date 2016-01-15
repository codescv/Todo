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
    
    override func awakeFromNib() {
        self.layer.borderColor = UIColor.grayColor().CGColor
        self.layer.borderWidth = 1
    }
    
    var model: TodoCategoryViewModel? {
        didSet {
            self.categoryNameLabel.text = model?.name
            self.categoryInfoLabel.text = "\(model?.numberOfItems ?? 0) Items"
        }
    }
}
