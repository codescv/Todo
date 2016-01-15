//
//  DoneItemCell.swift
//  Todo
//
//  Created by Chi Zhang on 1/5/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import UIKit

class DoneItemCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var cardBackgroundView: UIView!
    
    @IBAction func deleteAction(sender: AnyObject) {
        self.actionTriggered?(self, .Delete)
    }
    
    @IBOutlet weak var undoLabelWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var undoLabel: UILabel!
    
    enum Action {
        case Delete
        case Undo
    }
    
    var actionTriggered: ((DoneItemCell, Action)->())?
    var isTableViewDragging: (()->Bool)?
    
    var model: DoneItemViewModel? {
        didSet {
            if model != nil {
                let attributes = [
                    NSStrikethroughStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
                    NSForegroundColorAttributeName: UIColor.grayColor(),
                ]
                self.titleLabel.attributedText = NSAttributedString(string: model!.title, attributes: attributes)
            } else {
                self.titleLabel.text = ""
            }
        }
    }
    
    override func awakeFromNib() {
        // set background colors so the cell background can show
        self.backgroundColor = UIColor.clearColor()
        self.contentView.backgroundColor = UIColor.clearColor()
        self.cardBackgroundView.layer.cornerRadius = 5.0
        // to let sliding label to have rounded corner
        self.cardBackgroundView.clipsToBounds = true
        self.undoLabelWidthConstraint.constant = 0
        
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
            self.panDistance = min(panStartPos!.x - pos.x, maxDistance)
            if self.panDistance > 0 {
                self.undoLabelWidthConstraint.constant = self.panDistance
                if self.panDistance > minEffectiveDistance {
                    self.undoLabel.backgroundColor = UIColor.greenColor()
                } else {
                    self.undoLabel.backgroundColor = UIColor.grayColor()
                }
            }
        default:
            if self.panDistance > minEffectiveDistance {
                self.undoLabelWidthConstraint.constant = 0
                self.actionTriggered?(self, .Undo)
            } else {
                UIView.animateWithDuration(0.2, delay: 0,
                    options: [],
                    animations: {
                        self.undoLabelWidthConstraint.constant = 0
                        self.contentView.layoutIfNeeded()
                    },
                    completion: { _ in })
            }
            self.panDistance = 0
            panStartPos = nil
            gesture.enabled = true
        }
    }
}
