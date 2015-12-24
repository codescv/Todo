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
        self.button.hidden = true
    }
    
    func expandActions() {
    
    }
    
    func hideActions() {
        
    }
    
    var showActions: Bool? {
        didSet {
            if oldValue == nil && showActions == false {
                return
            }
            
            if showActions! {
                let translate = CGAffineTransformMakeTranslation(0, -self.button.frame.height/2)
                let trans = CGAffineTransformScale(translate, 0.01, 0.01)
                self.button.transform = trans
                self.button.hidden = false
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.button.transform = CGAffineTransformIdentity
                    }, completion: { (success) in
                })
                
            } else {
                if self.button.hidden == true {
                    return
                }
                
                self.button.transform = CGAffineTransformIdentity
                let translate = CGAffineTransformMakeTranslation(0, -self.button.frame.height/2)
                let trans = CGAffineTransformScale(translate, 0.01, 0.01)
                self.button.hidden = false
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.button.transform = trans
                    }, completion: { (success) in
                        self.button.hidden = true
                })
            }
            
        }
    }
}