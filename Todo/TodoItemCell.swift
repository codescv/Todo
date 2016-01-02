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
    
    @IBOutlet weak var actionsView: UIStackView!
    
    let animationDuration = 0.3
    
    override func awakeFromNib() {
        self.contentView.clipsToBounds = false
        self.clipsToBounds = false
    }
    
    func expandActionsAnimated(animated: Bool = true) {
        if animated {
            UIView.animateWithDuration(animationDuration, animations: {
                self.actionsView.hidden = false
                self.contentView.layoutIfNeeded()
            })
        } else {
            self.actionsView.hidden = false
        }
    }
    
    func hideActionsAnimated(animated: Bool = true) {
        if animated {
            UIView.animateWithDuration(animationDuration, animations: {
                self.actionsView.hidden = true
                self.contentView.layoutIfNeeded()
            })
        } else {
            self.actionsView.hidden = true
        }
    }
}