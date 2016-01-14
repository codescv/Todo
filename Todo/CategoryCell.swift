//
//  CategoryCell.swift
//  Todo
//
//  Created by Chi Zhang on 12/19/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit

class CategoryCell: UICollectionViewCell {

    @IBOutlet weak var categoryNameTextField: UITextField!
    
    override func awakeFromNib() {
        self.layer.borderColor = UIColor.grayColor().CGColor
        self.layer.borderWidth = 1
    }
}
