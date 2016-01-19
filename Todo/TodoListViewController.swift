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
    var category: TodoCategoryViewModel? {
        didSet {
            innerTableViewController?.categoryId = category?.objId
            self.title = category?.name
        }
    }
    
    var innerTableViewController: TodoListTableViewController?
    
    @IBAction func newTodoItemButtonTouched(sender: UIButton) {
        self.innerTableViewController?.startComposingNewTodoItem()
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
    
    let moveToCategorySegue = "SelectCategorySegue"
    let editReminderSegue = "editReminderSegue"
    
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
            self.todoItemsDataController.onChange = { [weak self] changes in
                if let myself = self {
                    if changes.count == 0 {
                        myself.tableView.reloadData()
                        return
                    }
                    myself.tableView.beginUpdates()
                    for change in changes {
                        switch change {
                        case .Insert(indexPaths: let indexPaths):
                            myself.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Left)
                        case .Delete(indexPaths: let indexPaths):
                            myself.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Right)
                        case .Update(indexPaths: let indexPaths):
                            myself.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
                        default:
                            ()
                        }
                    }
                    myself.tableView.endUpdates()
                }
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
    
    // is tableview dragging
    var isDragging = false
    
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
            self.categoryId = parentVC.category?.objId
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
                        self.todoItemsDataController.moveTodoItem(fromRow: self.firstMovingIndexPath!.row, toRow: self.currentMovingIndexPath!.row)
                        self.firstMovingIndexPath = nil
                        self.currentMovingIndexPath = nil
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
                        self.endEditingCell(cell, save: true)
                    case .Cancel:
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
                switch action {
                case .Delete:
                    self.deleteDoneItemForCell(cell)
                case .Undo:
                    self.undoDoneItemForCell(cell)
                }
            }
            doneCell.isTableViewDragging = { [unowned self] in
                return self.isDragging
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
            case .MoveToCategory:
                self.moveToCategoryForCell(cell)
            case .EditReminder:
                self.editReminderForCell(cell)
            default:
                break
            }
        }
        itemCell.isTableViewDragging = { [unowned self] in
            return self.isDragging
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
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.isDragging = true
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.isDragging = false
    }
    
    // table cell actions
    func deleteItemForCell(cell: TodoItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.selectedIndexPath = nil
            self.tableView.reloadData()
            self.todoItemsDataController.deleteTodoItemAtRow(indexPath.row)
        }
    }
    
    func deleteDoneItemForCell(cell: DoneItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.selectedIndexPath = nil
            self.tableView.reloadData()
            self.todoItemsDataController.deleteDoneItemAtRow(indexPath.row)
        }
    }
    
    func undoDoneItemForCell(cell: DoneItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.selectedIndexPath = nil
            self.tableView.reloadData()
            self.todoItemsDataController.undoItemAtRow(indexPath.row)
        }
    }
    
    func markItemAsDoneForCell(cell: TodoItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.selectedIndexPath = nil
            self.tableView.reloadData()
            self.todoItemsDataController.markTodoItemAsDoneAtRow(indexPath.row)
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
        if save && title.isEmpty {
            return
        }
        let indexPath = self.editingIndexPath!
        self.isComposingNewTodoItem = false
        self.editingIndexPath = nil
        if let item = cell.model {
            // edit item
            if save {
                self.todoItemsDataController.editTodoItem(item, title: title)
            } else {
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        } else {
            // new item
            // remove the editing cell
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            if save {
                self.todoItemsDataController.insertTodoItem(title: title)
            }
        }
    }
    
    func moveToCategoryForCell(cell: TodoItemCell) {
        self.performSegueWithIdentifier(self.moveToCategorySegue, sender: cell)
    }
    
    func editReminderForCell(cell: TodoItemCell) {
        self.performSegueWithIdentifier(self.editReminderSegue, sender: cell)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == self.moveToCategorySegue {
            //let model = (sender as! TodoItemCell).model!
            if let toVC = segue.destinationViewController as? UINavigationController {
                if let categoryVC = toVC.topViewController as? TodoCategoryListViewController,
                   let cell = sender as? TodoItemCell {
                    categoryVC.readonly = true
                    categoryVC.onSelectCategory = { [weak categoryVC] category in
                        self.todoItemsDataController.changeCategory(cell.model!, category: category) {
                            categoryVC?.dismissViewControllerAnimated(true, completion: {})
                        }
                    }
                    categoryVC.title = "Pick A List"
                }
            }
        } else if segue.identifier == self.editReminderSegue {
            if let cell = sender as? TodoItemCell {
                if let reminderVC = segue.destinationViewController as? ReminderViewController {
                    reminderVC.item = cell.model
                }
            }
        }
    }
    
    // unwind from edit reminder
    @IBAction func editReminder(segue: UIStoryboardSegue) {
        if let reminderVC = segue.sourceViewController as? ReminderViewController {
            if let model = reminderVC.item {
                //let x = "abc"
                let isRepeated = model.isRepeated
                let repeatType = model.repeatType
                let repeatValue = model.repeatValue
                let hasReminder = model.hasReminder
                let reminderDate = model.reminderDate
                self.todoItemsDataController.editReminder(model, hasReminder: hasReminder,
                    reminderDate: reminderDate, isRepeated: isRepeated,
                    repeatType: repeatType, repeatValue: repeatValue)
            }
        }
    }
    
    @IBAction func cancelEditReminder(segue: UIStoryboardSegue) {
        
    }

}








