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
    // MARK: outlets
    //@IBOutlet weak var tableView: UITableView!
    
    // MARK: properties
    let session = DataManager.instance.session
    let identifier = "TodoItemCellIdentifier"
    
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item: TodoItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as! TodoItem
        let cell: TodoItemCell = tableView.dequeueReusableCellWithIdentifier(identifier) as! TodoItemCell
        cell.titleLabel.text = item.title
        //cell.dateLabel.text = "xlkajfdladsk"
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections![section].numberOfObjects
    }
    
    // MARK: tableviewdelegate
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: fetchedresultscontrollerdelegate
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }
}








