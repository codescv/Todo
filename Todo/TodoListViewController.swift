//
//  ViewController.swift
//  Todo
//
//  Created by Chi Zhang on 12/14/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit
import CoreData
import DQuery

class TodoListViewController: UIViewController {
    let selectCategorySegueIdentifier: String = "selectCategorySegue"
    
    var categoryId: NSManagedObjectID? {
        didSet {
            innerTableViewController?.categoryId = categoryId
            if categoryId == nil {
                self.title = "All"
            } else {
                let category: TodoItemCategory = DQ.objectWithID(categoryId!)
                self.title = category.name
            }
        }
    }
    
    var innerTableViewController: TodoListTableViewController?
    
    @IBAction func newTodoItemButtonTouched(sender: UIButton) {
        self.innerTableViewController?.startComposingNewTodoItem()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == selectCategorySegueIdentifier {
            if let navController = segue.destinationViewController as? UINavigationController {
                if let catListVC = navController.childViewControllers.first as? TodoCategoryListViewController {
                    // catlist vc must load its view so that it can return the rect for zooming
                    _ = catListVC.view
//                    navController.transitioningDelegate = catListVC
                }
            }
        }
    }
}

class TodoListTableViewController: UITableViewController {
    // MARK: properties
    enum CellType: String{
        case ItemCell = "TodoItemCellIdentifier"
        case DoneItemCell = "DoneItemCellIdentifier"
        case EditItemCell = "EditTodoItemIdentifier"
        
        func identifier() -> String {
            return self.rawValue
        }
    }
    
    enum Section: Int {
        case TodoSection
        case DoneSection
        
        static func count() -> Int {
            return 2
        }
        
        func sectionName() -> String {
            switch self {
            case .TodoSection:
                return "Todo"
            case .DoneSection:
                return "Done"
            }
        }
    }
    
    deinit {
        print("deinit todolist table vc")
    }
    
    // the category id
    var categoryId: NSManagedObjectID? {
        didSet {
            self.todoItemsDataController = TodoItemDataController(categoryId: self.categoryId)
            self.todoItemsDataController.reloadDataFromDB {
                self.tableView.reloadData()
            }
        }
    }
    
    // the cell expanded
    var selectedIndexPath: NSIndexPath?
    // the cell to be moved
    var firstMovingIndexPath: NSIndexPath?
    var currentMovingIndexPath: NSIndexPath?
    // snapshot of current moving cell
    var sourceCellSnapshot: UIView?
    
    // view model
    var todoItemsDataController = TodoItemDataController()
    
    // current editing item
    var editingIndexPath: NSIndexPath?
    
    var isComposingNewTodoItem = false {
        didSet {
            if isComposingNewTodoItem {
                self.editingIndexPath = NSIndexPath(forRow: 0, inSection: 0)
            }
        }
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if let parentVC = parent as? TodoListViewController {
            parentVC.innerTableViewController = self
            self.categoryId = parentVC.categoryId
        }
    }
    
    // MARK: viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .None
        
        let longPress = UILongPressGestureRecognizer(target: self, action:"longPressGestureRecognized:")
        tableView.addGestureRecognizer(longPress)
    }
    
    // MARK: gesture recognizer
    func longPressGestureRecognized(longPress: UILongPressGestureRecognizer!) {
        if self.editingIndexPath != nil {
            return
        }
        
        let state = longPress.state
        let location = longPress.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(location)
        
        switch (state) {
        case .Began:
            
            let blk = {
                if let pressedIndexPath = indexPath {
                    self.firstMovingIndexPath = pressedIndexPath
                    self.currentMovingIndexPath = pressedIndexPath
                    let cell = self.tableView.cellForRowAtIndexPath(pressedIndexPath) as! TodoItemCell
                    let rect = cell.cardBackgroundView.convertRect(cell.cardBackgroundView.bounds, toView: self.view)
                    // using cell to create snapshot can sometimes lead to error
                    self.sourceCellSnapshot = self.view.resizableSnapshotViewFromRect(rect, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
                    
                    // Add the snapshot as subview, centered at cell's center...
                    let center: CGPoint = cell.center
                    
                    let snapshot: UIView! = self.sourceCellSnapshot
                    snapshot.center = center
                    snapshot.alpha = 1.0
                    snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05)
                    self.tableView.addSubview(snapshot)
                    
                    UIView.animateWithDuration(0.25,
                        animations: {
                            // Offset for gesture location.
                            snapshot.center = CGPointMake(center.x, location.y)
                            snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05)
                            snapshot.alpha = 0.98
                            
                            // Fade out.
                            cell.alpha = 0.0
                        },
                        completion: { (success) in
                            cell.hidden = true
                        }
                    )
                    
                }
            }
            
            if selectedIndexPath != nil {
                selectedIndexPath = nil
                tableView.reloadData()
                dispatch_async(dispatch_get_main_queue(), {
                    blk();
                })
            } else {
                blk();
            }
            
        case .Changed:
            guard
                let snapshot = sourceCellSnapshot,
                let _ = currentMovingIndexPath
                else {
                    print("error! current index path: \(currentMovingIndexPath) snapshot: \(sourceCellSnapshot)")
                    return
            }
            
            let center = snapshot.center
            snapshot.center = CGPointMake(center.x, location.y);
            
            if let targetIndexPath = indexPath {
                if targetIndexPath.section != Section.TodoSection.rawValue {
                    return
                }
                if targetIndexPath.compare(currentMovingIndexPath!) != .OrderedSame {
                    tableView.moveRowAtIndexPath(currentMovingIndexPath!, toIndexPath: targetIndexPath)
                    currentMovingIndexPath = indexPath
                }
            }
            

        default:
            guard
                currentMovingIndexPath != nil &&
                firstMovingIndexPath != nil
                else {
                    print("error! current index path \(currentMovingIndexPath) first index path \(firstMovingIndexPath)")
                    return
            }
            
            let cell = tableView.cellForRowAtIndexPath(currentMovingIndexPath!) as! TodoItemCell
            cell.hidden = false
            cell.alpha = 0.0
            
            UIView.animateWithDuration(0.25,
                animations: {
                    if let snapshot = self.sourceCellSnapshot {
                        snapshot.center = cell.center
                        snapshot.transform = CGAffineTransformIdentity
                        snapshot.alpha = 0.0
                    }
                    
                    // Undo fade out.
                    cell.alpha = 1.0

                },
                completion: { (success) in
                    self.sourceCellSnapshot?.removeFromSuperview()
                    self.sourceCellSnapshot = nil
                    if state == .Ended {
                        self.todoItemsDataController.moveTodoItem(fromRow: self.firstMovingIndexPath!.row, toRow: self.currentMovingIndexPath!.row,
                            completion: {
                                self.firstMovingIndexPath = nil
                                self.currentMovingIndexPath = nil
                                self.tableView.reloadData()
                        })
                    } else {
                        print("state: \(state)")
                        self.tableView.reloadData()
                    }
            })
            
        }
    }

    // MARK: datasource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.count()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .TodoSection:
            let itemCount = self.todoItemsDataController.todoItemsCount
            
            if self.isComposingNewTodoItem {
                return itemCount + 1
            }
            
            return itemCount
        case .DoneSection:
            return self.todoItemsDataController.doneItemsCount
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.sectionName()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // new/edit item cell
        if indexPath.isEqual(self.editingIndexPath) {
            let editItemCell = tableView.dequeueReusableCellWithIdentifier(CellType.EditItemCell.identifier()) as! EditTodoItemCell
            print("edit item cell")
            if self.isComposingNewTodoItem {
                editItemCell.model = nil
            } else {
                let item = self.todoItemsDataController.todoItemAtRow(indexPath.row)
                editItemCell.model = item
            }
            dispatch_async(dispatch_get_main_queue(), {
                editItemCell.textView.becomeFirstResponder()
            })
            editItemCell.actionTriggered = { [unowned self] (cell, action) in
                    switch action {
                    case .OK:
//                        let title = cell.textView.text
                        self.endEditingCell(cell, save: true)
//                        self.todoItemsDataController.insertTodoItem(title: title) {
//                            self.endComposingNewTodoItem(insertedNewItem: true)
//                        }
                    case .Cancel:
//                        self.endComposingNewTodoItem(insertedNewItem: false)
                        self.endEditingCell(cell, save: false)
                    default:
                        break
                    }
                
            }
            return editItemCell
        }
        
        // done item cell
        if indexPath.section == Section.DoneSection.rawValue {
            let doneCell = tableView.dequeueReusableCellWithIdentifier(CellType.DoneItemCell.identifier()) as! DoneItemCell
            let item = self.todoItemsDataController.doneItemAtRow(indexPath.row)
            doneCell.model = item
            doneCell.actionTriggered = { [unowned self] cell, action in
                self.deleteDoneItemForCell(cell)
            }
            return doneCell
        }
        
        // todo item cell
        var row = indexPath.row
        if self.isComposingNewTodoItem {
            row -= 1
        }
        
        let item = self.todoItemsDataController.todoItemAtRow(row)
        let itemCell = tableView.dequeueReusableCellWithIdentifier(CellType.ItemCell.identifier()) as! TodoItemCell
        if selectedIndexPath?.compare(indexPath) == .OrderedSame {
            item.isExpanded = true
        } else {
            item.isExpanded = false
        }
        // only show category name inside the "all" list
        if self.categoryId != nil {
            item.categoryName = nil
        }
        itemCell.model = item
        itemCell.actionTriggered = { [unowned self] (cell, action) in
            switch action {
            case .Delete:
                self.deleteItemForCell(cell)
            case .MarkAsDone:
                self.markItemAsDoneForCell(cell)
            case .Edit:
                self.beginEditingCell(cell)
            default:
                break
            }
        }
        return itemCell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.todoItemsDataController.moveTodoItem(fromRow: sourceIndexPath.row, toRow: destinationIndexPath.row)
    }
    
    // delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.isComposingNewTodoItem {
            return
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        if let selected = selectedIndexPath {
            if selected.compare(indexPath) == .OrderedSame {
                // fold
                selectedIndexPath = nil
                let cell = tableView.cellForRowAtIndexPath(indexPath) as? TodoItemCell
                cell?.hideActionsAnimated()
                
            } else {
                // fold old and expand new
                selectedIndexPath = indexPath
                let oldCell = tableView.cellForRowAtIndexPath(selected) as? TodoItemCell
                let newCell = tableView.cellForRowAtIndexPath(indexPath) as? TodoItemCell
                oldCell?.hideActionsAnimated()
                newCell?.expandActionsAnimated()
            }
        } else {
            // expand new
            selectedIndexPath = indexPath
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? TodoItemCell
            cell?.expandActionsAnimated()
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    // table cell actions
    func deleteItemForCell(cell: TodoItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.todoItemsDataController.deleteTodoItemAtRow(indexPath.row) {
                self.selectedIndexPath = nil
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            }
        }
    }
    
    func deleteDoneItemForCell(cell: DoneItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.todoItemsDataController.deleteDoneItemAtRow(indexPath.row) {
                self.selectedIndexPath = nil
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            }
        }
    }
    
    func markItemAsDoneForCell(cell: TodoItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.selectedIndexPath = nil
            self.todoItemsDataController.markTodoItemAsDoneAtRow(indexPath.row) {
                self.tableView.beginUpdates()
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: Section.DoneSection.rawValue)], withRowAnimation: .Left)
                self.tableView.endUpdates()
            }
        }
    }
    
    func beginEditingCell(cell: TodoItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.selectedIndexPath = nil
            self.editingIndexPath = indexPath
            self.tableView.beginUpdates()
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }
    }
    
    func startComposingNewTodoItem() {
        if self.isComposingNewTodoItem {
            return
        }
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.isComposingNewTodoItem = true
        self.editingIndexPath = indexPath
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
        if self.selectedIndexPath != nil {
            self.tableView.reloadRowsAtIndexPaths([self.selectedIndexPath!], withRowAnimation: .Automatic)
            self.selectedIndexPath = nil
        }
        self.tableView.endUpdates()
    }
    
    func endEditingCell(cell: EditTodoItemCell, save: Bool) {
        let title = cell.textView.text
        let indexPath = self.editingIndexPath!
        if let item = cell.model {
            // edit
            if save {
                self.todoItemsDataController.editTodoItem(item, title: title) {
                    self.isComposingNewTodoItem = false
                    self.editingIndexPath = nil
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            } else {
                self.isComposingNewTodoItem = false
                self.editingIndexPath = nil
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        } else {
            // new
            self.todoItemsDataController.insertTodoItem(title: title) {
                self.editingIndexPath = nil
                self.isComposingNewTodoItem = false
                self.tableView.beginUpdates()
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
                if save {
                    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                }
                self.tableView.endUpdates()
                
            }
        }
    }

}








