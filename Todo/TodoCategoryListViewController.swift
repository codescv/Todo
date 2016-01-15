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


class TodoCategoryListViewController: UIViewController {
    var innerCollectionViewController: TodoCategoryCollectionViewController?
    
    override func viewDidLoad() {
        self.navigationController?.delegate = self
    }
    
    @IBAction func newCategory(sender: AnyObject) {
        self.innerCollectionViewController?.startEditingNewCategory()
    }
    
}

extension TodoCategoryListViewController: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .Push {
            if let todoListVC = toVC as? TodoListViewController {
                let categoryId = todoListVC.category?.objId
                return RectZoomAnimator(direction: .ZoomIn, rect: {self.innerCollectionViewController!.cellRectForCategoryId(categoryId)})
            }
        } else {
            if let todoListVC = fromVC as? TodoListViewController {
                let categoryId = todoListVC.category?.objId
                return RectZoomAnimator(direction: .ZoomOut, rect: {self.innerCollectionViewController!.cellRectForCategoryId(categoryId)})
            }
        }
        return nil
    }
}

class TodoCategoryCollectionViewController: UICollectionViewController {
    let selectCategorySegueIdentifier = "SelectCategoryIdentifier"
    let showTodoListSegueIdentifier = "showTodoListWithNoAnimation"
    
    let categoryDataController = TodoCategoryDataController()
    
    var selectedCellRect = CGRectZero
    var isEditingNewCategory: Bool = false {
        didSet {
            if isEditingNewCategory {
                let row = self.categoryDataController.numberOfCategories
                self.editingIndexPath = NSIndexPath(forRow: row, inSection: 0)
            }
        }
    }
    
    var editingIndexPath: NSIndexPath?
    
    enum CellType: String {
        case Category = "CategoryCellIdentifier"
        case Add = "CategoryAddCellIdentifier"
        case Remove = "CategoryRemoveCellIdentifier"
        case Edit = "CategoryEditCellIdentifier"
        
        func identifier() -> String {
            return self.rawValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.categoryDataController.reloadDataFromDB {
            self.collectionView!.reloadData()
        }
        self.collectionView!.backgroundColor = UIColor.whiteColor()
        
        let layout = self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSizeMake(self.view.frame.width/2, self.view.frame.width/2)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if let parentVC = parent as? TodoCategoryListViewController {
            parentVC.innerCollectionViewController = self
        }
    }
    
    func startEditingNewCategory() {
        self.isEditingNewCategory = true
        let indexPath = self.editingIndexPath!
        self.collectionView?.insertItemsAtIndexPaths([indexPath])
        self.collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
    }
    
    func endEditingForCell(cell: EditCategoryCell, saved: Bool) {
        let name = cell.categoryNameTextField.text!
        if let indexPath = self.editingIndexPath {
            if self.isEditingNewCategory {
                if saved {
                    self.categoryDataController.insertNewCategory(name) {
                        self.isEditingNewCategory = false
                        self.editingIndexPath = nil
                        self.collectionView?.reloadItemsAtIndexPaths([indexPath])
                    }
                } else {
                    self.isEditingNewCategory = false
                    self.editingIndexPath = nil
                    self.collectionView?.deleteItemsAtIndexPaths([indexPath])
                }
            } else {
                if saved {
                    self.categoryDataController.editCategory(cell.model!, newName:name) {
                        self.isEditingNewCategory = false
                        self.editingIndexPath = nil
                        self.collectionView?.reloadItemsAtIndexPaths([indexPath])
                    }
                } else {
                    self.isEditingNewCategory = false
                    self.editingIndexPath = nil
                    self.collectionView?.reloadItemsAtIndexPaths([indexPath])
                }
            }
        }
    }
    
    func cellRectForCategoryId(categoryId: NSManagedObjectID?) -> CGRect {
        // compute for category rect
        var indexPath = NSIndexPath(forRow: 0, inSection: 0)
        let order = self.categoryDataController.orderForCategoryId(categoryId)
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
                    todoListVC.category = self.categoryDataController.categoryAtRow(indexPath.row)
                }
            }
        }
    }
}

extension TodoCategoryCollectionViewController {

    func cellTypeForItemAtIndexPath(indexPath: NSIndexPath) -> CellType {
        if indexPath.isEqual(self.editingIndexPath) {
            return CellType.Edit
        }
        
        return CellType.Category
        
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
            let cell = self.reusableCellForType(cellType, indexPath: indexPath) as! CategoryCell
            let category = self.categoryDataController.categoryAtRow(indexPath.row)
            cell.model = category
            return cell
        } else if cellType == CellType.Edit {
            let cell = self.reusableCellForType(cellType, indexPath: indexPath) as! EditCategoryCell
            cell.textIsValid = { !($0?.isEmpty ?? true) }
            cell.editFinished = { (cell, saved) in
                self.endEditingForCell(cell, saved: saved)
            }
            cell.startEditing()
            
            return cell
        }
    
        let cell = self.reusableCellForType(cellType, indexPath: indexPath)
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.categoryDataController.numberOfCategories
        if self.isEditingNewCategory {
            return count + 1
        } else {
            return count
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
}

//extension TodoCategoryListViewController: UITextFieldDelegate {
//    func isCategoryNameValid(categoryName: String?) -> Bool {
//        return !(categoryName?.isEmpty ?? true)
//    }
//    
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        textField.endEditing(true)
//        return isCategoryNameValid(textField.text)
//    }
//    
//    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
//        return true
//    }
//    
//    func textFieldDidEndEditing(textField: UITextField) {
//        let categoryName = textField.text
//        if isCategoryNameValid(categoryName) {
//            DQ.insertObject(TodoItemCategory.self,
//                block: { (context, category) in
//                    category.name = categoryName
//                    category.displayOrder = TodoItemCategory.lastDisplayOrder(context)
//                },
//                completion: { categoryId in
//                    self.categoryDataController.reloadDataFromDB() {
//                        self.collectionView!.reloadData()
//                    }
//            })
//        }
//        self.editingIndexPath = nil
//    }
//}


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
