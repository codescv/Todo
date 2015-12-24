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
    var categoryId = TodoItemCategory.defaultCategory().objectID
    
    // from select category controller
    @IBAction func unwindFromSelectCategory(segue: UIStoryboardSegue) {
    }
    
    // MARK: unwind actions from new item controller
    @IBAction func cancelNewTodoItem(segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func saveNewTodoItem(segue: UIStoryboardSegue) {
        if let newTodoItemVC = segue.sourceViewController as? NewTodoItemController {
            let content = newTodoItemVC.textView.text
            session.write({ (context) in
                let item: TodoItem = TodoItem.dq_insertInContext(context)
                item.title = content
                item.startDate = NSDate()
                item.category = context.dq_objectWithID(self.categoryId) as TodoItemCategory
            })
        }
    }

}

class TodoListTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    // MARK: properties
    let session = DataManager.instance.session
    
    enum CellType: String{
        case ItemCell = "TodoItemCellIdentifier"
        case ActionCell = "TodoItemActionCellIdentifier"
        
        func identifier() -> String {
            return self.rawValue
        }
        
        func rowHeight() -> CGFloat {
            switch self {
            case .ActionCell:
                return 44
            case .ItemCell:
                return 60
            }
        }
    }
    
    // the cell selected
    var selectedIndexPath: NSIndexPath?
    
    // the cell to be moved
    var sourceIndexPath: NSIndexPath?
    var sourceCellSnapshot: UIView?
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        return self.session.query(TodoItem).fetchedResultsController()
    }()
    
    // MARK: viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.fetchedResultsController.delegate = self
        try! self.fetchedResultsController.performFetch()
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let longPress = UILongPressGestureRecognizer(target: self, action:"longPressGestureRecognized:")
        tableView.addGestureRecognizer(longPress)
    }
    
    // MARK: gesture recognizer
    func longPressGestureRecognized(longPress: UILongPressGestureRecognizer!) {
        //print("long press! \(longPress)")
        let state = longPress.state;
        let location = longPress.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(location)
        
        switch (state) {
        case .Began:
            if let pressedIndexPath = indexPath {
                self.sourceIndexPath = pressedIndexPath;
                let cell = self.tableView.cellForRowAtIndexPath(pressedIndexPath) as! TodoItemCell
                sourceCellSnapshot = cell.resizableSnapshotViewFromRect(cell.bounds, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
                
                // Add the snapshot as subview, centered at cell's center...
                let center: CGPoint = cell.center
                
                let snapshot: UIView! = sourceCellSnapshot
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
                        cell.alpha = 0.0;
                    },
                    completion: { (success) in
                        cell.hidden = true;
                    }
                )
                
            }
            
        case .Changed:
            guard
                let snapshot = sourceCellSnapshot,
                let _ = sourceIndexPath
                else {
                    print("error! source index path: \(sourceIndexPath) snapshot: \(sourceCellSnapshot)")
                    return
            }
            
            let center = snapshot.center
            snapshot.center = CGPointMake(center.x, location.y);
            
            if let targetIndexPath = indexPath {
                if targetIndexPath.compare(sourceIndexPath!) != .OrderedSame {
                    
                    // TODO update model
                    tableView.moveRowAtIndexPath(sourceIndexPath!, toIndexPath: targetIndexPath)
                    sourceIndexPath = indexPath
                }
            }
            

        default:
            guard
                let _ = sourceIndexPath
                else {
                    print("error! source index path is nil")
                    return
            }
            
            let cell = tableView.cellForRowAtIndexPath(sourceIndexPath!) as! TodoItemCell
            cell.hidden = false
            cell.alpha = 0.0
            
            UIView.animateWithDuration(0.25,
                animations: {
                    if let snapshot = self.sourceCellSnapshot {
                        snapshot.center = cell.center;
                        snapshot.transform = CGAffineTransformIdentity;
                        snapshot.alpha = 0.0;
                    }
                    
                    // Undo fade out.
                    cell.alpha = 1.0

                },
                completion: { (success) in
                    self.sourceIndexPath = nil
                    self.sourceCellSnapshot?.removeFromSuperview()
                    self.sourceCellSnapshot = nil
                    self.tableView.reloadData()
            })
            
        }
    }

    // MARK: datasource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item: TodoItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as! TodoItem
        let itemCell = tableView.dequeueReusableCellWithIdentifier(CellType.ItemCell.identifier()) as! TodoItemCell
        itemCell.titleLabel.text = item.title
        if selectedIndexPath?.compare(indexPath) == .OrderedSame {
            itemCell.expandActionsAnimated(false)
        } else {
            itemCell.hideActionsAnimated(false)
        }
        return itemCell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let itemCount = self.fetchedResultsController.sections![section].numberOfObjects
        return itemCount
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if selectedIndexPath?.compare(indexPath) == .OrderedSame {
            return 66
        } else {
            return 44
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        if let selected = selectedIndexPath {
            if selected.compare(indexPath) == .OrderedSame {
                // fold
                selectedIndexPath = nil
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                let cell = tableView.cellForRowAtIndexPath(indexPath) as? TodoItemCell
                cell?.hideActionsAnimated()
            } else {
                // fold old and expand new
                selectedIndexPath = indexPath
                tableView.reloadRowsAtIndexPaths([selected, indexPath], withRowAnimation: .Automatic)
                let oldCell = tableView.cellForRowAtIndexPath(selected) as? TodoItemCell
                let newCell = tableView.cellForRowAtIndexPath(indexPath) as? TodoItemCell
                oldCell?.hideActionsAnimated()
                newCell?.expandActionsAnimated()
            }
        } else {
            // expand new
            selectedIndexPath = indexPath
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? TodoItemCell
            cell?.expandActionsAnimated()
            
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
    }
    
    // MARK: fetchedresultscontrollerdelegate
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }
    
    
}








