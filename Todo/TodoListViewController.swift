//
//  ViewController.swift
//  Todo
//
//  Created by Chi Zhang on 12/14/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UIViewController {
    let session = DataManager.instance.session
    var categoryId: NSManagedObjectID? {
        get {
            return innerTableViewController?.categoryId
        }
        
        set {
            innerTableViewController?.categoryId = newValue
        }
    }
    
    var innerTableViewController: TodoListTableViewController?
    
    // from select category controller
    @IBAction func unwindFromSelectCategory(segue: UIStoryboardSegue) {
        // TODO: set category id
    }
    
    // MARK: unwind actions from new item controller
    @IBAction func cancelNewTodoItem(segue: UIStoryboardSegue) {
        
    }
    
    // unwind from saving new todo item
    @IBAction func saveNewTodoItem(segue: UIStoryboardSegue) {
        if let newTodoItemVC = segue.sourceViewController as? NewTodoItemController {
            let content = newTodoItemVC.textView.text
            if content != "" {
                session.write({ (context) in
                    let item: TodoItem = TodoItem.dq_insertInContext(context)
                    item.title = content
                    item.dueDate = NSDate.today()
                    item.displayOrder = TodoItem.topDisplayOrder(context)
                    if let categoryId = self.categoryId {
                        item.category = context.dq_objectWithID(categoryId) as TodoItemCategory
                    }
                })
            }
        }
    }

}

class TodoListTableViewController: UITableViewController {
    // MARK: properties
    let session = DataManager.instance.session
    
    enum CellType: String{
        case ItemCell = "TodoItemCellIdentifier"
        case DoneItemCell = "DoneItemCellIdentifier"
        
        func identifier() -> String {
            return self.rawValue
        }
    }
    
    // the category id
    var categoryId: NSManagedObjectID? {
        didSet {
            self.todoItemsModel = TodoItemViewModel(categoryId: self.categoryId)
            self.todoItemsModel.reloadDataFromDB({
                self.tableView.reloadData()
            })
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
    var todoItemsModel = TodoItemViewModel()
    
    func reloadDataFromDB() {
        todoItemsModel.reloadDataFromDB {
            self.tableView.reloadData()
        }
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if let parentVC = parent as? TodoListViewController {
            parentVC.innerTableViewController = self
        }
    }
    
    // MARK: viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        reloadDataFromDB()
        self.todoItemsModel.onChange = {
            self.tableView.reloadData()
        }
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.purpleColor()
        
        let longPress = UILongPressGestureRecognizer(target: self, action:"longPressGestureRecognized:")
        tableView.addGestureRecognizer(longPress)
    }
    
    // MARK: gesture recognizer
    func longPressGestureRecognized(longPress: UILongPressGestureRecognizer!) {
        //print("long press! \(longPress)")
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
                    
                    
                    let rect = cell.convertRect(cell.bounds, toView: self.view)
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
                        self.todoItemsModel.moveTodoItem(fromRow: self.firstMovingIndexPath!.row, toRow: self.currentMovingIndexPath!.row,
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
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        print("get cell")
        let itemId = self.todoItemsModel.todoItems[indexPath.row]
        let item: TodoItem = session.defaultContext.dq_objectWithID(itemId)
        let itemCell = tableView.dequeueReusableCellWithIdentifier(CellType.ItemCell.identifier()) as! TodoItemCell
        itemCell.titleLabel.text = item.title
        if selectedIndexPath?.compare(indexPath) == .OrderedSame {
            itemCell.expandActionsAnimated(false)
        } else {
            itemCell.hideActionsAnimated(false)
        }
        itemCell.actionTriggered = { action in
            switch action {
            case .Delete:
                self.deleteItemForCell(itemCell)
            default:
                break
            }
        }
        return itemCell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let itemCount = self.todoItemsModel.todoItems.count
        return itemCount
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.todoItemsModel.moveTodoItem(fromRow: sourceIndexPath.row, toRow: destinationIndexPath.row)
    }
    
    // delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
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
            self.todoItemsModel.deleteTodoItemAtRow(indexPath.row) {
                self.selectedIndexPath = nil
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }
}








