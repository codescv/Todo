//
//  NewTodoItemController.swift
//  Todo
//
//  Created by Chi Zhang on 12/17/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit

class NewTodoItemController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    
    let maxTextViewHeight: CGFloat = 100
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: self.view.window)
        self.textView.delegate = self
        self.textView.returnKeyType = .Done
        self.textView.text = ""
        fitTextViewSize()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapped:"))
    }
    
    func tapped(tap: UITapGestureRecognizer!) {
        if tap.state == .Ended {
            textView.resignFirstResponder()
            self.performSegueWithIdentifier("cancelNewTodoItem", sender: self)
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardSize = notification.userInfo![UIKeyboardFrameBeginUserInfoKey]!.CGRectValue.size
        self.textViewBottomConstraint.constant = keyboardSize.height
        self.view.layoutIfNeeded()
    }
    
    override func viewWillAppear(animated: Bool) {
        textView.becomeFirstResponder()
    }
    
    func fitTextViewSize() {
        let newHeight = textView.sizeThatFits(textView.frame.size).height
        if newHeight < maxTextViewHeight {
            self.textViewHeightConstraint.constant = newHeight
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        fitTextViewSize()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let resultRange = text.rangeOfCharacterFromSet(NSCharacterSet.newlineCharacterSet(), options: .BackwardsSearch)
        if text.characters.count == 1 && resultRange != nil {
            textView.resignFirstResponder()
            self.performSegueWithIdentifier("saveNewTodoItem", sender: self)
            return false
        }
        return true
    }
}
