//
//  NewTodoItemCell.swift
//  Todo
//
//  Created by Chi Zhang on 1/4/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import UIKit

class EditTodoItemCell: UITableViewCell {
    
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func okTouched(sender: UIButton) {
        self.actionTriggered?(self, .OK)
    }
    
    @IBAction func cancelTouched(sender: UIButton) {
        self.actionTriggered?(self, .Cancel)
    }
    
    enum Action {
        case OK
        case Cancel
        case Unknown
    }
    
    var model: TodoItemViewModel? {
        didSet {
            self.textView.text = model?.title
        }
    }
    
    var actionTriggered: ((EditTodoItemCell, Action)->())?
}