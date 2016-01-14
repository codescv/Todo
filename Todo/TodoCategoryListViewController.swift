//
//  TodoCategoryListViewController.swift
//  Todo
//
//  Created by Chi Zhang on 12/19/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit
import CoreData
import DQuery

class TodoCategoryListViewController: UICollectionViewController {
    let selectCategorySegueIdentifier = "SelectCategoryIdentifier"
    let showTodoListSegueIdentifier = "showTodoListWithNoAnimation"
    
    let categoryViewModel = TodoCategoryViewModel()
    
    var selectedCellRect = CGRectZero
    var isComposingNewCategory: Bool {
        return self.editingIndexPath != nil
    }
    var editingIndexPath: NSIndexPath? {
        didSet {
            if editingIndexPath != oldValue {
                self.collectionView!.reloadData()
            }
        }
    }
    
    enum CellType: String {
        case Category = "CategoryCellIdentifier"
        case Add = "CategoryAddCellIdentifier"
        case Remove = "CategoryRemoveCellIdentifier"
        case New = "CategoryNewCellIdentifier"
        
        func identifier() -> String {
            return self.rawValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.categoryViewModel.reloadDataFromDB {
            self.collectionView!.reloadData()
        }
        self.collectionView!.backgroundColor = UIColor.whiteColor()
        
        let layout = self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSizeMake(self.view.frame.width/2, self.view.frame.width/2)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        navigationController?.delegate = self
    }
    
    
    func cellRectForCategoryId(categoryId: NSManagedObjectID?) -> CGRect {
        // compute for category rect
        var indexPath = NSIndexPath(forRow: 0, inSection: 0)
        let order = self.categoryViewModel.orderForCategoryId(categoryId)
        if order >= 0 {
            indexPath = NSIndexPath(forRow: order+1, inSection: 0)
        }
        let cell = collectionView(collectionView!, cellForItemAtIndexPath:indexPath)
        let cellFrame = cell.frame
        let result = collectionView!.convertRect(cellFrame, toView: view)
        return result
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == selectCategorySegueIdentifier {
            if let todoListVC = segue.destinationViewController as? TodoListViewController,
               let cell = sender as? CategoryCell {
                if let indexPath = self.collectionView?.indexPathForCell(cell) {
                    if indexPath.row == 0 {
                        // all items
                        todoListVC.title = "All"
                    } else {
                        todoListVC.categoryId = self.categoryViewModel.categories[indexPath.row-1]
                    }
                }
            }
        }
    }
}

extension TodoCategoryListViewController {

    func cellTypeForItemAtIndexPath(indexPath: NSIndexPath) -> CellType {
        let row = indexPath.row
        let count = self.categoryViewModel.categories.count + 1
        
        if row < count {
            return CellType.Category
        } else {
            var functionCells = [CellType.Add, CellType.Remove]
            if self.isComposingNewCategory {
                functionCells = [CellType.New, CellType.Add, CellType.Remove]
            }
            
            return functionCells[row - count]
        }
    }
    
    func reusableCellForType(cellType: CellType, indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView!.dequeueReusableCellWithReuseIdentifier(cellType.identifier(), forIndexPath: indexPath)
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellType = self.cellTypeForItemAtIndexPath(indexPath)
        if cellType == CellType.Category {
            let cell: CategoryCell = self.reusableCellForType(cellType, indexPath: indexPath) as! CategoryCell
            let row = indexPath.row - 1
            if row == -1 {
                cell.categoryNameTextField.text = "All"
            } else {
                let category: TodoItemCategory = DQ.objectWithID(self.categoryViewModel.categories[row])
                cell.categoryNameTextField.text = category.name
            }
        
            if indexPath.isEqual(self.editingIndexPath) {
                cell.categoryNameTextField.enabled = true
                dispatch_async(dispatch_get_main_queue(), {
                    cell.categoryNameTextField.becomeFirstResponder()
                })
                cell.categoryNameTextField.delegate = self
            } else {
                cell.categoryNameTextField.enabled = false
                cell.categoryNameTextField.delegate = nil
            }
            return cell
        } else if cellType == CellType.New {
            let cell: CategoryCell = self.reusableCellForType(cellType, indexPath: indexPath) as! CategoryCell
            cell.categoryNameTextField.placeholder = "List Name"
            cell.categoryNameTextField.text = ""
            cell.categoryNameTextField.enabled = true
            dispatch_async(dispatch_get_main_queue(), {
                cell.categoryNameTextField.becomeFirstResponder()
            })
            cell.categoryNameTextField.delegate = self
            return cell
        }
    
        let cell = self.reusableCellForType(cellType, indexPath: indexPath)
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.categoryViewModel.categories.count
        if self.isComposingNewCategory {
            return count + 4
        } else {
            return count + 3
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cellType = self.cellTypeForItemAtIndexPath(indexPath)
        
        if cellType == CellType.Add {
            self.editingIndexPath = indexPath
        }
    }
    
    
}

extension TodoCategoryListViewController: UITextFieldDelegate {
    func isCategoryNameValid(categoryName: String?) -> Bool {
        return !(categoryName?.isEmpty ?? true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.endEditing(true)
        return isCategoryNameValid(textField.text)
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let categoryName = textField.text
        if isCategoryNameValid(categoryName) {
            DQ.insertObject(TodoItemCategory.self,
                block: { (context, category) in
                    category.name = categoryName
                    category.displayOrder = TodoItemCategory.lastDisplayOrder(context)
                },
                completion: { categoryId in
                    self.categoryViewModel.reloadDataFromDB() {
                        self.collectionView!.reloadData()
                    }
            })
        }
        self.editingIndexPath = nil
    }
}

extension TodoCategoryListViewController: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .Push {
            if let todoListVC = toVC as? TodoListViewController {
                let categoryId = todoListVC.categoryId
                return RectZoomAnimator(direction: .ZoomIn, rect: {self.cellRectForCategoryId(categoryId)})
            }
        } else {
            if let todoListVC = fromVC as? TodoListViewController {
                let categoryId = todoListVC.categoryId
                return RectZoomAnimator(direction: .ZoomOut, rect: {self.cellRectForCategoryId(categoryId)})
            }
        }
        return nil
    }
}

//extension TodoCategoryListViewController: UIViewControllerTransitioningDelegate {
//    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return RectZoomAnimator(direction: .ZoomOut, rect: {self.selectedCellRect})
//    }
//    
//    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        if let todoListVC = source as? TodoListViewController {
//            let categoryId = todoListVC.categoryId
//            return RectZoomAnimator(direction: .ZoomIn, rect: {self.cellRectForCategoryId(categoryId)})
//        }
//        
//        return nil
//    }
//}
