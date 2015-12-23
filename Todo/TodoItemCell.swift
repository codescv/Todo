//
//  TodoItemCell.swift
//  Todo
//
//  Created by Chi Zhang on 12/18/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import Foundation
import UIKit


class TodoItemCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var actionView: UIStackView!
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var actionViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        self.actionView.hidden = true
    }
    
    var showActions: Bool? {
        didSet {
            if oldValue == nil && showActions == false {
                return
            }
            
            if showActions! {
                self.actionView.hidden = false
                let translate = CGAffineTransformMakeTranslation(0, -self.button.frame.height/2)
                let trans = CGAffineTransformScale(translate, 0.3, 0.3)
                self.button.transform = trans
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.button.transform = CGAffineTransformIdentity
                })
                
            } else {
                self.actionView.hidden = true
            }
            
        }
    }
}