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
    var readonly = false
    var onSelectCategory: ((TodoCategoryViewModel)->())?
    @IBOutlet weak var newCategoryButton: UIButton!
    
    override func viewDidLoad() {
        self.navigationController?.delegate = self
        if self.readonly {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
            self.newCategoryButton.hidden = true
        } else {
            self.navigationItem.rightBarButtonItem = self.editButtonItem()
        }
    }
    
    func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion:{})
    }
    
    @IBAction func newCategory(sender: AnyObject) {
        self.innerCollectionViewController?.startEditingNewCategory()
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        if self.innerCollectionViewController?.editingIndexPath != nil {
            return
        }
        super.setEditing(editing, animated: animated)
        self.innerCollectionViewController?.setEditing(editing, animated: animated)
    }
    
    func endEditingMode() {
        super.setEditing(false, animated: true)
        self.innerCollectionViewController?.setEditing(editing, animated: true)
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView!.reloadData()
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if let parentVC = parent as? TodoCategoryListViewController {
            parentVC.innerCollectionViewController = self
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: false)
        self.collectionView?.reloadData()
    }
    
    func endEditingMode() {
        if self.editing {
            if let parent = self.parentViewController as? TodoCategoryListViewController {
                parent.endEditingMode()
            }
        }
    }
    
    func endEditing() {
        endEditingMode()
        self.isEditingNewCategory = false
        self.editingIndexPath = nil
        self.collectionView?.reloadData()
    }
    
    func startEditingNewCategory() {
        self.endEditingMode()
        self.isEditingNewCategory = true
        self.collectionView?.reloadData()
    }
    
    func endEditingForCell(cell: EditCategoryCell, saved: Bool) {
        let name = cell.categoryNameTextField.text!
        
        if self.isEditingNewCategory {
            if saved {
                self.categoryDataController.insertNewCategory(name) {
                    self.endEditing()
                }
            } else {
                self.endEditing()
            }
        } else {
            if saved {
                self.categoryDataController.editCategory(cell.model!, newName:name) {
                    self.endEditing()
                }
            } else {
                self.endEditing()
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
            category.showsEditingControls = self.editing
            cell.model = category
            cell.actionTriggered = { [unowned self] (cell, action) in
                switch action {
                case .Delete:
                    self.deleteCategoryForCell(cell)
                case .Edit:
                    self.editCategoryForCell(cell)
                }
            }
            return cell
        } else if cellType == CellType.Edit {
            let cell = self.reusableCellForType(cellType, indexPath: indexPath) as! EditCategoryCell
            if isEditingNewCategory {
                cell.model = nil
            } else {
                let model = self.categoryDataController.categoryAtRow(indexPath.row)
                cell.model = model
            }
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
        if let parent = self.parentViewController as? TodoCategoryListViewController {
            let item = self.categoryDataController.categoryAtRow(indexPath.row)
            parent.onSelectCategory?(item)
        }
    }
    
    func deleteCategoryForCell(cell: CategoryCell) {
        if let indexPath = self.collectionView?.indexPathForCell(cell) {
            self.categoryDataController.deleteCategoryAtRow(indexPath.row) {
                self.collectionView?.deleteItemsAtIndexPaths([indexPath])
            }
        }
    }
    
    func editCategoryForCell(cell: CategoryCell) {
        if let indexPath = self.collectionView?.indexPathForCell(cell) {
            self.isEditingNewCategory = false
            self.editingIndexPath = indexPath
            self.collectionView?.reloadData()
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if let parent = self.parentViewController as? TodoCategoryListViewController {
            if parent.onSelectCategory != nil {
                return false
            }
        }
        
        if self.editing || self.isEditingNewCategory {
            if let editingIndexPath = self.editingIndexPath {
                if let cell = self.collectionView?.cellForItemAtIndexPath(editingIndexPath) as? EditCategoryCell {
                    self.endEditingForCell(cell, saved: false)
                }
            }
            return false
        }
        return true
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
