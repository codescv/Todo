//
//  EditCategoryCell.swift
//  Todo
//
//  Created by 陳小晶 on 16/1/15.
//  Copyright © 2016年 chi zhang. All rights reserved.
//

import UIKit

class EditCategoryCell: UICollectionViewCell {

    @IBOutlet weak var categoryNameTextField: UITextField!
    @IBAction func cancelEditing(sender: AnyObject) {
        self.categoryNameTextField.delegate = nil
        self.editFinished?(self, false)
    }
    
    var textIsValid: ((String?)->Bool)?
    var editFinished: ((EditCategoryCell, Bool)->())?
    
    var model: CategoryCellModel? {
        didSet {
            self.categoryNameTextField.text = model?.name
        }
    }
    
//    override func awakeFromNib() {
//        self.categoryNameTextField.delegate = self
//    }
    
    func startEditing() {
        dispatch_async(dispatch_get_main_queue(), {
            self.categoryNameTextField.becomeFirstResponder()
        })
        self.categoryNameTextField.delegate = self
    }

}

extension EditCategoryCell: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let shouldReturn = self.textIsValid?(textField.text) ?? false
        if shouldReturn {
            textField.endEditing(true)
        }
        return shouldReturn
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let shouldSave = self.textIsValid?(textField.text) ?? false
        self.categoryNameTextField.delegate = nil
        self.editFinished?(self, shouldSave)
    }
}
