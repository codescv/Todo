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
    // action cell is the cell below the selected cell
    var actionCellIndexPath: NSIndexPath? {
        if let selected = selectedIndexPath {
            return NSIndexPath(forRow: selected.row + 1, inSection: selected.section)
        }
        return nil
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        return self.session.query(TodoItem).fetchedResultsController()
    }()
    
    // MARK: viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.fetchedResultsController.delegate = self
        try! self.fetchedResultsController.performFetch()
    }

    // MARK: datasource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func cellTypeForIndexPath(indexPath: NSIndexPath) -> CellType {
        if let acIndexPath = actionCellIndexPath {
            if acIndexPath.compare(indexPath) == .OrderedSame {
                return .ActionCell
            }
        }
        return .ItemCell
    }
    
    func itemIndexPathForCellIndexPath(indexPath: NSIndexPath) -> NSIndexPath? {
        if let acIndexPath = actionCellIndexPath {
            switch (acIndexPath.compare(indexPath)) {
            case .OrderedSame:
                return nil
            case .OrderedAscending:
                return NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section)
            case .OrderedDescending:
                return indexPath
            }
        }
        return indexPath
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellType = cellTypeForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(cellType.identifier())
        if cellType == .ActionCell {
            return cell!
        } else {
            let item: TodoItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as! TodoItem
            let itemCell = cell as! TodoItemCell
            itemCell.titleLabel.text = item.title
            return itemCell
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let itemCount = self.fetchedResultsController.sections![section].numberOfObjects
        if selectedIndexPath != nil {
            return itemCount + 1
        }
        return itemCount
    }
    
    // MARK: tableviewdelegate
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let cellType = cellTypeForIndexPath(indexPath)
        return cellType.rowHeight()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let itemIndexPath = itemIndexPathForCellIndexPath(indexPath)
            else { return }
        
        if selectedIndexPath?.compare(itemIndexPath) == .OrderedSame {
            // selected the same cell again, fold the action
            if let acIndexPath = actionCellIndexPath {
                selectedIndexPath = nil
                tableView.beginUpdates()
                tableView.deleteRowsAtIndexPaths([acIndexPath], withRowAnimation: .Automatic)
                tableView.endUpdates()
            }
            return
        }
        
        tableView.beginUpdates()
        // if action view exists, remove it
        if let acIndexPath = actionCellIndexPath {
            tableView.deleteRowsAtIndexPaths([acIndexPath], withRowAnimation: .Automatic)
        }
        
        // expand new action cell
        selectedIndexPath = itemIndexPath
        tableView.insertRowsAtIndexPaths([actionCellIndexPath!], withRowAnimation: .Automatic)
        tableView.endUpdates()
    }
    
    // MARK: fetchedresultscontrollerdelegate
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }
    
    
}








