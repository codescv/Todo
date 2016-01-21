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
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var actionsView: UIStackView!
    @IBOutlet weak var reminderInfoLabel: UILabel!
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var reminderButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
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
        case Edit
        case ShowDetail
        case MoveToCategory
        case EditReminder
        case Noop
    }
    
    // action button callback
    var actionTriggered: ((TodoItemCell, Action) -> ())?
    var isTableViewDragging: (()->Bool)?
    
    @IBAction func markAsDoneAction(sender: AnyObject) {
        self.actionTriggered?(self, .MarkAsDone)
    }
    
    @IBAction func addReminderAction(sender: AnyObject) {
        self.actionTriggered?(self, .EditReminder)
    }
    
    @IBAction func showDetailAction(sender: AnyObject) {
        self.actionTriggered?(self, .ShowDetail)
    }
    
    @IBAction func editAction(sender: AnyObject) {
        self.actionTriggered?(self, .Edit)
    }
    
    @IBAction func moveToCategoryAction(sender: AnyObject) {
        self.actionTriggered?(self, .MoveToCategory)
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        self.actionTriggered?(self, .Delete)
    }
    
    var model: TodoItemCellModel? {
        didSet {
            if let vm = model {
                self.titleLabel.text = vm.title
                if vm.isExpanded {
                    self.expandActionsAnimated(false)
                } else {
                    self.hideActionsAnimated(false)
                }
                
                if let categoryName = vm.categoryName {
                    self.categoryLabel.hidden = false
                    self.categoryLabel.text = categoryName
                } else {
                    self.categoryLabel.hidden = true
                }
                
                if vm.hasReminder {
                    self.reminderInfoLabel.hidden = false
                    self.reminderInfoLabel.text = "\(vm.reminderDate.shortString())"
                } else {
                    self.reminderInfoLabel.hidden = true
                }
            } else {
                self.reminderInfoLabel.hidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        // set contentmode of icons so the animation will work correctly
        self.doneButton.imageView?.contentMode = .ScaleAspectFit
        self.deleteButton.imageView?.contentMode = .ScaleAspectFit
        self.editButton.imageView?.contentMode = .ScaleAspectFit
        self.categoryButton.imageView?.contentMode = .ScaleAspectFit
        self.reminderButton.imageView?.contentMode = .ScaleAspectFit
        
        // set background colors so the cell background can show
        //self.backgroundColor = UIColor.clearColor()
        //self.contentView.backgroundColor = UIColor.clearColor()
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
        if gestureRecognizer.state == .Changed {
            return false
        }
        return true
    }
    
    var panStartPos: CGPoint?
    var panDistance: CGFloat = 0
    
    func pan(gesture: UIPanGestureRecognizer) {
        let maxDistance: CGFloat = 200
        let minEffectiveDistance: CGFloat = 50
        switch (gesture.state) {
        case .Began:
            if self.isTableViewDragging?() == true {
                gesture.enabled = false
                return
            }
            panStartPos = gesture.locationInView(self.contentView)
        case .Changed:
            if self.isTableViewDragging?() == true {
                gesture.enabled = false
                return
            }
            let pos = gesture.locationInView(self.contentView)
            self.panDistance = min(pos.x - panStartPos!.x, maxDistance)
            if self.panDistance > 0 {
                self.doneLabelWidthConstraint.constant = self.panDistance
                if self.panDistance > minEffectiveDistance {
                    self.doneLabel.backgroundColor = UIColor.greenColor()
                } else {
                    self.doneLabel.backgroundColor = UIColor.grayColor()
                }
            }
        default:
            if self.panDistance > minEffectiveDistance {
                self.doneLabelWidthConstraint.constant = 0
                self.actionTriggered?(self, .MarkAsDone)
            } else {
                UIView.animateWithDuration(0.2, delay: 0,
                    options: [],
                    animations: {
                        self.doneLabelWidthConstraint.constant = 0
                        self.contentView.layoutIfNeeded()
                    },
                    completion: { _ in })
            }
            self.panDistance = 0
            panStartPos = nil
            gesture.enabled = true
        }
    }
    
    func expandActionsAnimated(animated: Bool = true) {
        self.titleLabel.numberOfLines = 6
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
        self.titleLabel.numberOfLines = 1
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