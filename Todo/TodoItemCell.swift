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
    @IBOutlet weak var actionsView: UIStackView!
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var reminderButton: UIButton!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    
    @IBOutlet weak var doneLabel: UILabel!
    @IBOutlet weak var doneLabelWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var cardBackgroundView: UIView!
    let animationDuration = 0.3
    
    // MARK: action buttons
    enum Action {
        case Delete
        case MarkAsDone
        case ShowDetail
        case MoveToCategory
        case AddReminder
        case Noop
    }
    
    // action button callback
    var actionTriggered: ((TodoItemCell, Action) -> ())?
    
    @IBAction func markAsDoneAction(sender: AnyObject) {
        self.actionTriggered?(self, .MarkAsDone)
    }
    
    @IBAction func addReminderAction(sender: AnyObject) {
        self.actionTriggered?(self, .AddReminder)
    }
    
    @IBAction func showDetailAction(sender: AnyObject) {
        self.actionTriggered?(self, .ShowDetail)
    }
    
    @IBAction func moveToCategoryAction(sender: AnyObject) {
        self.actionTriggered?(self, .MoveToCategory)
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        self.actionTriggered?(self, .Delete)
    }
    
    override func awakeFromNib() {
        // set contentmode of icons so the animation will work correctly
        self.doneButton.imageView?.contentMode = .ScaleAspectFit
        self.deleteButton.imageView?.contentMode = .ScaleAspectFit
        self.detailButton.imageView?.contentMode = .ScaleAspectFit
        self.categoryButton.imageView?.contentMode = .ScaleAspectFit
        self.reminderButton.imageView?.contentMode = .ScaleAspectFit
        
        // set background colors so the cell background can show
        self.backgroundColor = UIColor.clearColor()
        self.contentView.backgroundColor = UIColor.clearColor()
        self.cardBackgroundView.layer.cornerRadius = 5.0
        // to let sliding label to have rounded corner
        self.cardBackgroundView.clipsToBounds = true
        
        // hide sliding done label initially
        self.doneLabelWidthConstraint.constant = 0
        
        // slide gesture
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: "pan:")
        gestureRecognizer.delegate = self
        self.contentView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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