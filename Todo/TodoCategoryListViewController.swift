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
    let showTodoListSegueIdentifier = "showTodoListWithNoAnimation"
    
    let categoryViewModel = TodoCategoryViewModel()
    
    var selectedCellRect = CGRectZero
    @IBOutlet weak var collectionView: UICollectionView!

    enum CellType: String {
        case Category = "CategoryCellIdentifier"
        case Add = "CategoryAddCellIdentifier"
        case Remove = "CategoryRemoveCellIdentifier"
        
        func identifier() -> String {
            return self.rawValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.categoryViewModel.reloadDataFromDB()
        self.collectionView.reloadData()
        navigationController?.delegate = self
    }
    
    
    func cellRectForCategoryId(categoryId: NSManagedObjectID?) -> CGRect {        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        
        let cell = collectionView(collectionView, cellForItemAtIndexPath:indexPath)
        let offset = collectionView.contentOffset
        print("offset: \(offset)")
//        let cellFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)
        let cellFrame = cell.frame
        print("cell frame: \(cellFrame)")
        let result = collectionView.convertRect(cellFrame, toView: view)
        return result
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == selectCategorySegueIdentifier {
//            if let todoListVC = segue.destinationViewController as? TodoListViewController {
//            }
//        }
    }
}

extension TodoCategoryListViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func cellTypeForItemAtIndexPath(indexPath: NSIndexPath) -> CellType {
        let row = indexPath.row
        let count = self.categoryViewModel.categories.count + 1
        
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
            cell.categoryNameLabel.text = "All"
            return cell
        } else {
            let cell: CategoryCell = self.reusableCellForType(cellType, indexPath: indexPath) as! CategoryCell
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.categoryViewModel.categories.count
        return count + 3
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
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
            return RectZoomAnimator(direction: .ZoomOut, rect: {self.cellRectForCategoryId(nil)})
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

//extension TodoCategoryListViewController: UINavigationControllerDelegate {
//    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return RectZoomAnimator(presenting: operation == .Push, rect: selectedCellRect)
//    }
//}

