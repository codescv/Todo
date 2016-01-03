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
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var actionsView: UIStackView!
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var doneLabel: UILabel!
    @IBOutlet weak var doneLabelWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var cardBackgroundView: UIView!
    let animationDuration = 0.3
    
    override func awakeFromNib() {
        self.doneButton.imageView?.contentMode = .ScaleAspectFit
        self.doneLabelWidthConstraint.constant = 0
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: "pan:")
        self.contentView.addGestureRecognizer(gestureRecognizer)
        
        self.backgroundColor = UIColor.clearColor()
        self.contentView.backgroundColor = UIColor.clearColor()
        self.cardBackgroundView.layer.cornerRadius = 5.0
        self.cardBackgroundView.clipsToBounds = true
    }
    
    var panStartPos: CGPoint?
    
    func pan(gesture: UIPanGestureRecognizer) {
        let maxDistance: CGFloat = 100
        switch (gesture.state) {
        case .Began:
            panStartPos = gesture.locationInView(self.contentView)
        case .Changed:
            let pos = gesture.locationInView(self.contentView)
            let distance = pos.x - panStartPos!.x
            if distance > 0 && distance < maxDistance {
                self.doneLabelWidthConstraint.constant = distance
            }
        default:
            panStartPos = nil
            self.doneLabelWidthConstraint.constant = 0
        }
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