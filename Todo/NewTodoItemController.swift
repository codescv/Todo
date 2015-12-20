//
//  NewTodoItemController.swift
//  Todo
//
//  Created by Chi Zhang on 12/17/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit

class NewTodoItemController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewWillAppear(animated: Bool) {
        textView.becomeFirstResponder()
    }
}
