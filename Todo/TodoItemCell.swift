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
                print("return!")
                return
            }
            
            if showActions! {
                print("show actions")
                
                self.actionView.hidden = false
                let translate = CGAffineTransformMakeTranslation(0, -self.actionView.frame.height/2)
                let trans = CGAffineTransformScale(translate, 1.0, 0.1)
                self.actionView.transform = trans
                UIView.animateWithDuration(2.0, animations: { () -> Void in
                    self.actionView.transform = CGAffineTransformIdentity
                })
                
            } else {
                print("hide actions")
                self.actionView.hidden = true
                self.contentView.layoutIfNeeded()
//                UIView.animateWithDuration(0.5, animations: { () -> Void in
//                    self.actionView.hidden = true
//                    self.layoutIfNeeded()
//                })
            }
        }
    }
}