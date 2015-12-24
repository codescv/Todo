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
    
    let animationDuration = 0.2
    
    func expandActionsAnimated(animated: Bool = true) {
        self.button.hidden = false
        
        if animated {
            let translate = CGAffineTransformMakeTranslation(0, -self.button.frame.height/2)
            let scale = CGAffineTransformMakeScale(0.01, 0.01)
            self.button.transform = CGAffineTransformConcat(scale, translate)
            UIView.animateWithDuration(animationDuration,
                animations: {
                self.button.transform = CGAffineTransformIdentity
                },
                completion: { (success) in
                self.button.hidden = false
            })
        }
    }
    
    func hideActionsAnimated(animated: Bool = true) {
        if animated {
            self.button.hidden = false
            self.button.transform = CGAffineTransformIdentity
            UIView.animateWithDuration(animationDuration,
                animations: {
                    let translate = CGAffineTransformMakeTranslation(0, -self.button.frame.height/2)
                    let scale = CGAffineTransformMakeScale(0.01, 0.01)
                    self.button.transform = CGAffineTransformConcat(scale, translate)
                },
                completion: { (success) in
                    self.button.hidden = true
                    self.button.transform = CGAffineTransformIdentity
            })
        } else {
            self.button.hidden = true
        }
    }
}