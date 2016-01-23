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
    var onSelectCategory: ((NSManagedObjectID?)->())?
    
    @IBOutlet weak var newCategoryButton: UIButton!
    
    override func viewDidLoad() {
        self.navigationController?.delegate = self
        if self.readonly {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
            self.newCategoryButton.hidden = true
        }
        self.paddingLeftConstrant.constant = 4
        self.paddingRightConstraint.constant = 4
    }
    
    // cancel select category
    func cancel(sender: AnyObject) {
        self.performSegueWithIdentifier("cancelMoveToCategory", sender: nil)
    }
    
    // unwind from EditCategoryViewController
    @IBAction func cancelEditingCategory(segue: UIStoryboardSegue) {
    
    }
    
    @IBAction func saveCategory(segue: UIStoryboardSegue) {
        if let editCategoryVC = segue.sourceViewController as? EditCategoryViewController {
            let name = editCategoryVC.categoryName
            let color = editCategoryVC.categoryColor
            if let categoryId = editCategoryVC.categoryId {
                self.innerCollectionViewController?.categoryDataSource.editCategoryWithId(categoryId, newName: name, newColor: color)
            } else {
                self.innerCollectionViewController?.categoryDataSource.insertNewCategory(name, color: color)
            }
        }
    }
    
    @IBAction func deleteCategory(segue: UIStoryboardSegue) {
        if let editCategoryVC = segue.sourceViewController as? EditCategoryViewController {
            if let categoryId = editCategoryVC.categoryId {
                self.innerCollectionViewController?.categoryDataSource.deleteCategoryWithId(categoryId)
            }
        }
    }
    
    @IBOutlet weak var paddingLeftConstrant: NSLayoutConstraint!
    @IBOutlet weak var paddingRightConstraint: NSLayoutConstraint!
}

extension TodoCategoryListViewController: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .Push {
            if let todoListVC = toVC as? TodoListViewController {
                let categoryId = todoListVC.categoryId
                return RectZoomAnimator(direction: .ZoomIn, rect: {
                    self.innerCollectionViewController!.view.convertRect(self.innerCollectionViewController!.cellRectForCategoryId(categoryId), toView: self.view)
                })
            }
        } else {
            if let todoListVC = fromVC as? TodoListViewController {
                let categoryId = todoListVC.categoryId
                return RectZoomAnimator(direction: .ZoomOut, rect: {
                    self.innerCollectionViewController!.view.convertRect(self.innerCollectionViewController!.cellRectForCategoryId(categoryId), toView: self.view)
                })
            }
        }
        return nil
    }
}

class TodoCategoryCollectionViewController: UICollectionViewController {
    let selectCategorySegueIdentifier = "SelectCategoryIdentifier"
    let showTodoListSegueIdentifier = "showTodoListWithNoAnimation"
    let editCategorySegueIdentifier = "editCategory"
    
    let categoryDataSource = TodoCategoryDataSource()
    var selectedCellRect = CGRectZero
    
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
        self.categoryDataSource.reloadDataFromDB {
            self.collectionView!.reloadData()
        }
        self.categoryDataSource.onChange = { [weak self] changes in
            if let myself = self {
                if changes.count == 0 {
                    myself.collectionView!.reloadData()
                    return
                }
                for change in changes {
                    switch change {
                    case .Insert(indexPaths: let indexPaths):
                        myself.collectionView!.insertItemsAtIndexPaths(indexPaths)
                    case .Delete(indexPaths: let indexPaths):
                        myself.collectionView!.deleteItemsAtIndexPaths(indexPaths)
                    case .Update(indexPaths: let indexPaths):
                        myself.collectionView!.reloadItemsAtIndexPaths(indexPaths)
                    }
                }
            }
            
        }
        
        let layout = self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        let width = self.view.frame.width/2 - 6
        layout.itemSize = CGSizeMake(width, width)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 4
                
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

    func cellRectForCategoryId(categoryId: NSManagedObjectID?) -> CGRect {
        // compute for category rect
        let indexPath = self.categoryDataSource.indexPathForCategoryId(categoryId)
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
                    todoListVC.categoryId = self.categoryDataSource.categoryAtIndexPath(indexPath).objId
                }
            }
        }
        
        if segue.identifier == editCategorySegueIdentifier {
            if let navVC = segue.destinationViewController as? UINavigationController {
                if let editVC = navVC.topViewController as? EditCategoryViewController {
                    if let cell = sender as? CategoryCell {
                        editVC.categoryId = cell.model?.objId
                    }
                }
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == selectCategorySegueIdentifier {
            if let parent = self.parentViewController as? TodoCategoryListViewController {
                if parent.readonly {
                    return false
                }
            }
        }
        return true
    }
}

extension TodoCategoryCollectionViewController {

    func reusableCellForType(cellType: CellType, indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView!.dequeueReusableCellWithReuseIdentifier(cellType.identifier(), forIndexPath: indexPath)
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellType.Category.identifier(), forIndexPath: indexPath) as! CategoryCell
        let model = self.categoryDataSource.categoryAtIndexPath(indexPath)
        if let parent = self.parentViewController as? TodoCategoryListViewController {
            if parent.readonly {
                model.editable = false
            }
        }
        cell.model = model
        cell.actionTriggered = { (cell, action) in
            switch action {
            case .Delete:
                self.deleteCategoryForCell(cell)
            case .Edit:
                self.editCategoryForCell(cell)
            }
        }
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.categoryDataSource.numberOfCategories
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let parent = self.parentViewController as? TodoCategoryListViewController {
            let item = self.categoryDataSource.categoryAtIndexPath(indexPath)
            parent.onSelectCategory?(item.objId)
        }
    }
    
    func deleteCategoryForCell(cell: CategoryCell) {
        self.categoryDataSource.deleteCategory(cell.model!)
    }
    
    func editCategoryForCell(cell: CategoryCell) {
        self.performSegueWithIdentifier(editCategorySegueIdentifier, sender: cell)
    }
    
    
    
}