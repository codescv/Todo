//
//  TodoCategoryListViewController.swift
//  Todo
//
//  Created by Chi Zhang on 12/19/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit
import CoreData

class TodoCategoryListViewController: UIViewController {
    let session = DataManager.instance.session
    let selectCategorySegueIdentifier = "SelectCategoryIdentifier"
    var selectedCellRect = CGRectZero
    
    enum CellType: String {
        case Category = "CategoryCellIdentifier"
        case Add = "CategoryAddCellIdentifier"
        case Remove = "CategoryRemoveCellIdentifier"
        
        func identifier() -> String {
            return self.rawValue
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        return self.session.query(TodoItemCategory).fetchedResultsController()
    }()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        try! fetchedResultsController.performFetch()
        transitioningDelegate = self
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == selectCategorySegueIdentifier {
            let todoListVC = segue.destinationViewController as! TodoListViewController
            if let cell = sender as? CategoryCell {
                selectedCellRect = collectionView.convertRect(cell.frame, toView: view)
                let indexPath = collectionView.indexPathForCell(cell)!
                let category = fetchedResultsController.objectAtIndexPath(indexPath) as! TodoItemCategory
                todoListVC.categoryId = category.objectID
            }
        }
    }
    
    func cellRectForCategoryId(categoryId: NSManagedObjectID) -> CGRect {
        let category = self.session.defaultContext.dq_objectWithID(categoryId)
        let indexPath = fetchedResultsController.indexPathForObject(category)
        let cell = collectionView(collectionView, cellForItemAtIndexPath: indexPath!)
        return collectionView.convertRect(cell.frame, toView: view)
    }
}

extension TodoCategoryListViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func cellTypeForItemAtIndexPath(indexPath: NSIndexPath) -> CellType {
        let (row, section) = (indexPath.row, indexPath.section)
        let count = fetchedResultsController.sections![section].numberOfObjects
        if row < count {
            return CellType.Category
        } else if row == count {
            return CellType.Add
        } else {
            return CellType.Remove
        }
    }
    
    func reusableCellForType(cellType: CellType, indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier(cellType.identifier(), forIndexPath: indexPath)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellType = self.cellTypeForItemAtIndexPath(indexPath)
        if cellType == CellType.Category {
            let cell: CategoryCell = self.reusableCellForType(cellType, indexPath: indexPath) as! CategoryCell
            let category = fetchedResultsController.objectAtIndexPath(indexPath)
            cell.categoryNameLabel.text = category.name
            return cell
        } else {
            let cell: CategoryCell = self.reusableCellForType(cellType, indexPath: indexPath) as! CategoryCell
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = fetchedResultsController.sections![section].numberOfObjects
        return count + 2
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    }
}

extension TodoCategoryListViewController: UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return RectZoomAnimator(direction: .ZoomOut, rect: selectedCellRect)
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let todoListVC = source as? TodoListViewController {
            let categoryId = todoListVC.categoryId
            let rect = cellRectForCategoryId(categoryId)
            return RectZoomAnimator(direction: .ZoomIn, rect: rect)
        }
        
        return nil
    }
}

//extension TodoCategoryListViewController: UINavigationControllerDelegate {
//    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return RectZoomAnimator(presenting: operation == .Push, rect: selectedCellRect)
//    }
//}

