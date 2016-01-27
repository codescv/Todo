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
    var categoryId: NSManagedObjectID? {
        didSet {
            innerTableViewController?.categoryId = categoryId
            if let catId = categoryId {
                let category: TodoItemCategory = DQ.objectWithID(catId)
                self.title = category.name
            } else {
                self.title = "All"
            }
        }
    }
    
    @IBOutlet weak var categoryViewTopConstraint: NSLayoutConstraint!
    
    func showCategoryViewControllerAnimated(animated: Bool = true) {
        if animated {
            self.categoryCollectionViewController?.view.hidden = false
            self.categoryViewTopConstraint.constant = -44
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.3,
                animations: {
                    self.categoryViewTopConstraint.constant = 0
                    self.view.layoutIfNeeded()
                }, completion: { _ in
            })
        } else {
            self.categoryViewTopConstraint.constant = 0
            self.categoryCollectionViewController?.view.hidden = false
            self.view.layoutIfNeeded()
        }
    }
    
    func hideCategoryViewControllerAnimated(animated: Bool = true) {
        if animated {
            self.categoryViewTopConstraint.constant = 0
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.3, animations: {
                self.categoryViewTopConstraint.constant = -44
                self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.categoryCollectionViewController?.view.hidden = true
            })
        } else {
            self.categoryViewTopConstraint.constant = -44
            self.categoryCollectionViewController?.view.hidden = true
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let catId = categoryId {
            let category: TodoItemCategory = DQ.objectWithID(catId)
            self.navigationController?.navigationBar.barTintColor = category.color
        } else {
            self.navigationController?.navigationBar.barTintColor = CategoryColor.Blue.color()
        }
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.hideCategoryViewControllerAnimated(false)
    }
    
    var innerTableViewController: TodoListTableViewController?
    var categoryCollectionViewController: CategorySelectionViewController?
    
    @IBAction func newTodoItemButtonTouched(sender: UIButton) {
        self.innerTableViewController?.beginEditingNewTodoItem()
    }
    
    @IBAction func cancelMoveToCategory(segue: UIStoryboardSegue) {
    
    }
}

class CategorySelectionViewController: UICollectionViewController {
    let dataSource = TodoCategoryDataSource()
    var selectedIndexPath: NSIndexPath?
    
    func selectIndexPath(indexPath: NSIndexPath) {
        self.selectedIndexPath = indexPath
        self.collectionView?.reloadData()
    }
    
    func deselectAll() {
        self.selectedIndexPath = nil
        self.collectionView?.reloadData()
    }
    
    func categoryIdAtIndexPath(indexPath: NSIndexPath) -> NSManagedObjectID? {
        return self.dataSource.categoryAtIndexPath(indexPath).objId
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if let todoListVC = parent as? TodoListViewController {
            todoListVC.categoryCollectionViewController = self
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.dataSource.reloadDataFromDB() {
            self.collectionView?.reloadData()
        }
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.numberOfCategories
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CategoryCell", forIndexPath: indexPath)
        let cat = self.dataSource.categoryAtIndexPath(indexPath)
        cell.backgroundColor = cat.color
        if let label = cell.contentView.viewWithTag(1) as? UILabel {
            label.text = cat.name
            if indexPath.isEqual(self.selectedIndexPath) {
                label.layer.borderColor = UIColor.whiteColor().CGColor
                label.layer.borderWidth = 1
            } else {
                label.layer.borderWidth = 0
            }
        }
        
        return cell
    }
}

class TodoListTableViewController: UITableViewController {
    // MARK: constants
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
    
    // MARK: properties
    
    // segue ids
    let moveToCategorySegue = "SelectCategorySegue"
    let editReminderSegue = "editReminderSegue"
    
    
    // the category id
    var categoryId: NSManagedObjectID? {
        didSet {
            self.todoItemsDataSource = TodoItemDataSource(categoryId: self.categoryId)
            self.todoItemsDataSource.reloadDataFromDB {
                self.tableView.reloadData()
            }
            self.todoItemsDataSource.onChange = { [weak self] changes in
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
                        case .Move(fromIndexPath: let fromIndexPath, toIndexPath: let toIndexPath):
                            myself.tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
                        }
                    }
                    myself.tableView.endUpdates()
                }
            }
        }
    }
    
    // index path for the expanded cell
    var expandedIndexPath: NSIndexPath?
    
    // index path for the cell moving at the beginning
    var firstMovingIndexPath: NSIndexPath?
    // current index path for the moving cell
    var currentMovingIndexPath: NSIndexPath?
    // snapshot of current moving cell
    var sourceCellSnapshot: UIView?
    
    // data source for the table
    var todoItemsDataSource = TodoItemDataSource()

    // is tableview dragging
    var isDragging = false
    
    // index path for current editing cell
    var editingIndexPath: NSIndexPath?
    // is current editing a new item
    var isComposingNewTodoItem = false {
        didSet {
            if isComposingNewTodoItem {
                self.editingIndexPath = NSIndexPath(forRow: 0, inSection: 0)
            }
        }
    }
    
    // reference to the "move to category" shortcut
    var categoryViewController: CategorySelectionViewController? {
        return (parentViewController as? TodoListViewController)?.categoryCollectionViewController
    }
    
    // MARK: viewcontroller
    deinit {
        print("deinit todolist table vc")
    }

    override func didMoveToParentViewController(parent: UIViewController?) {
        if let parentVC = parent as? TodoListViewController {
            parentVC.innerTableViewController = self
            self.categoryId = parentVC.categoryId
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .None
        
        let longPress = UILongPressGestureRecognizer(target: self, action:"longPressGestureRecognized:")
        tableView.addGestureRecognizer(longPress)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == self.moveToCategorySegue {
            //let model = (sender as! TodoItemCell).model!
            if let toVC = segue.destinationViewController as? UINavigationController {
                if let categoryVC = toVC.topViewController as? TodoCategoryListViewController,
                    let cell = sender as? TodoItemCell {
                        categoryVC.readonly = true
                        categoryVC.onSelectCategory = { [weak categoryVC] categoryId in
                            self.todoItemsDataSource.changeCategory(cell.model!, categoryId: categoryId)
                            categoryVC?.dismissViewControllerAnimated(true, completion: {})
                        }
                        categoryVC.title = "Pick A List"
                        self.expandedIndexPath = nil
                        self.tableView.reloadData()
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
    
    
    func showCategoryViewController() {
        if let parent = parentViewController as? TodoListViewController {
            parent.showCategoryViewControllerAnimated()
        }
    }
    
    func hideCategoryViewController() {
        if let parent = parentViewController as? TodoListViewController {
            parent.hideCategoryViewControllerAnimated()
        }

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
                    self.showCategoryViewController()
                    self.firstMovingIndexPath = pressedIndexPath
                    self.currentMovingIndexPath = pressedIndexPath
                    let cell = self.tableView.cellForRowAtIndexPath(pressedIndexPath) as! TodoItemCell
                    cell.swipeGestureRecognizer?.enabled = false
                    cell.swipeGestureRecognizer?.enabled = true
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
            
            if expandedIndexPath != nil {
                expandedIndexPath = nil
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
            
            if let catPath = self.categoryViewController?.collectionView?.indexPathForItemAtPoint(location) {
                // move to category
                self.categoryViewController?.selectIndexPath(catPath)
                return
            }
            self.categoryViewController?.deselectAll()
            
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
            self.hideCategoryViewController()
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
                        if let categoryPath = self.categoryViewController?.selectedIndexPath {
                            // move to category
                            let item = self.todoItemsDataSource.itemAtIndexPath(self.firstMovingIndexPath!)
                            let categoryId = self.categoryViewController?.categoryIdAtIndexPath(categoryPath)
                            self.categoryViewController?.deselectAll()
                            self.todoItemsDataSource.changeCategory(item, categoryId: categoryId)
                        } else {
                            // reorder
                            self.todoItemsDataSource.moveTodoItem(fromRow: self.firstMovingIndexPath!.row, toRow: self.currentMovingIndexPath!.row)
                        }
                        self.firstMovingIndexPath = nil
                        self.currentMovingIndexPath = nil
                    } else {
                        print("state: \(state)")
                        self.tableView.reloadData()
                    }
            })
            
        }
    }

    // MARK: table datasource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.todoItemsDataSource.numberOfSections
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let itemCount = self.todoItemsDataSource.numberOfItemsInSection(section)
        if Section(rawValue: section)! == .TodoSection && self.isComposingNewTodoItem {
            return itemCount + 1
        }
        return itemCount
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.sectionName()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var model: TodoItemCellModel?
        let section = Section(rawValue: indexPath.section)!
        
        if section == .TodoSection {
            if indexPath.isEqual(self.editingIndexPath) {
                // new/edit
                if !self.isComposingNewTodoItem {
                    model = self.todoItemsDataSource.itemAtIndexPath(indexPath)
                }
                let cell = tableView.dequeueReusableCellWithIdentifier(CellType.EditItemCell.identifier()) as! EditTodoItemCell
                cell.model = model
                self.configureEditCell(cell)
                return cell
            } else {
                // todo
                var dataIndexPath = indexPath
                if self.isComposingNewTodoItem {
                    dataIndexPath = NSIndexPath(forRow: indexPath.row-1, inSection: indexPath.section)
                }
                model = self.todoItemsDataSource.itemAtIndexPath(dataIndexPath)
                model!.showsCategoryName = self.categoryId == nil // only show category name in "All" list
                let cell = tableView.dequeueReusableCellWithIdentifier(CellType.ItemCell.identifier()) as! TodoItemCell
                cell.model = model
                self.configureTodoCell(cell)
                return cell
            }
            
        } else {
            // done
            model = self.todoItemsDataSource.itemAtIndexPath(indexPath)
            let cell = tableView.dequeueReusableCellWithIdentifier(CellType.DoneItemCell.identifier()) as! DoneItemCell
            cell.model = model
            self.configureDoneCell(cell)
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.todoItemsDataSource.moveTodoItem(fromRow: sourceIndexPath.row, toRow: destinationIndexPath.row)
    }
    
    // MARK: table delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.isComposingNewTodoItem {
            return
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        if let selected = expandedIndexPath {
            if selected.compare(indexPath) == .OrderedSame {
                // fold
                expandedIndexPath = nil
                let cell = tableView.cellForRowAtIndexPath(indexPath) as? TodoItemCell
                cell?.hideActionsAnimated()
                
            } else {
                // fold old and expand new
                expandedIndexPath = indexPath
                let oldCell = tableView.cellForRowAtIndexPath(selected) as? TodoItemCell
                let newCell = tableView.cellForRowAtIndexPath(indexPath) as? TodoItemCell
                oldCell?.hideActionsAnimated()
                newCell?.expandActionsAnimated()
            }
        } else {
            // expand new
            expandedIndexPath = indexPath
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? TodoItemCell
            cell?.expandActionsAnimated()
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    // MARK: track table dragging state
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.isDragging = true
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.isDragging = false
    }
    
    // MARK: configure cell
    func configureEditCell(cell: EditTodoItemCell) {
        dispatch_async(dispatch_get_main_queue(), {
            cell.textView.becomeFirstResponder()
            cell.textView.delegate = self
        })
        cell.actionTriggered = { [unowned self] (cell, action) in
            switch action {
            case .OK:
                self.endEditingCell(cell, save: true)
            case .Cancel:
                self.endEditingCell(cell, save: false)
            default:
                break
            }
            
        }
    }
    
    func configureTodoCell(cell: TodoItemCell) {
        // keep view model in sync
        if let indexPath = self.tableView.indexPathForCell(cell) {
            if expandedIndexPath?.compare(indexPath) == .OrderedSame {
                cell.model?.isExpanded = true
            } else {
                cell.model?.isExpanded = false
            }
        }
        
        cell.actionTriggered = { [unowned self] (cell, action) in
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
        cell.isTableViewDragging = { [unowned self] in
            return self.isDragging
        }
        
    }
    
    func configureDoneCell(cell: DoneItemCell) {
        cell.actionTriggered = { [unowned self] cell, action in
            switch action {
            case .Delete:
                self.deleteItemForCell(cell)
            case .Undo:
                self.undoDoneItemForCell(cell)
            }
        }
        cell.isTableViewDragging = { [unowned self] in
            return self.isDragging
        }
    }
    
    // MARK: cell actions
    func deleteItemForCell(cell: UITableViewCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.expandedIndexPath = nil
            self.tableView.reloadData()
            self.todoItemsDataSource.deleteItemAtIndexPath(indexPath)
        }
    }
    
    func undoDoneItemForCell(cell: DoneItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.expandedIndexPath = nil
            self.tableView.reloadData()
            self.todoItemsDataSource.undoItemAtRow(indexPath.row)
        }
    }
    
    func markItemAsDoneForCell(cell: TodoItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.expandedIndexPath = nil
            self.tableView.reloadData()
            self.todoItemsDataSource.markTodoItemAsDoneAtRow(indexPath.row)
        }
    }
    
    
    func beginEditingNewTodoItem() {
        guard !self.isComposingNewTodoItem else { return }
        
        self.isComposingNewTodoItem = true
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.editingIndexPath = indexPath
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        if self.expandedIndexPath != nil {
            self.tableView.reloadRowsAtIndexPaths([self.expandedIndexPath!], withRowAnimation: .Automatic)
            self.expandedIndexPath = nil
        }
        self.tableView.endUpdates()
    }
    
    func beginEditingCell(cell: TodoItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.expandedIndexPath = nil
            self.editingIndexPath = indexPath
            self.tableView.beginUpdates()
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }
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
                self.todoItemsDataSource.editTodoItem(item, title: title)
            } else {
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        } else {
            // new item
            // remove the editing cell
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            if save {
                self.todoItemsDataSource.insertTodoItem(title: title)
            }
        }
    }
    
    func moveToCategoryForCell(cell: TodoItemCell) {
        self.performSegueWithIdentifier(self.moveToCategorySegue, sender: cell)
    }
    
    func editReminderForCell(cell: TodoItemCell) {
        self.performSegueWithIdentifier(self.editReminderSegue, sender: cell)
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
                self.todoItemsDataSource.editReminder(model, hasReminder: hasReminder,
                    reminderDate: reminderDate, isRepeated: isRepeated,
                    repeatType: repeatType, repeatValue: repeatValue)
            }
        }
    }
    
    @IBAction func cancelEditReminder(segue: UIStoryboardSegue) {
        
    }

}

extension TodoListTableViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        if textView.markedTextRange != nil {
            // if input methods are marking, wait for it
            return
        }
        
        let text = textView.text
        let recognizer = ReminderRecognizer(string: text)
        let ranges = recognizer.highlightedRanges()
        
        let attributedText = NSMutableAttributedString(string: text)
        for range in ranges {
            attributedText.addAttribute(NSBackgroundColorAttributeName, value: UIColor.redColor(), range: range)
        }
        textView.attributedText = attributedText
    }
    
}

class ReminderRecognizer {
    var string: String
    
    let patterns = [
        "(:?[0-2])?[0-9](?:a|p)m",
        "tomorrow",
        "every (day|monday|tuesday|wednesday|thursday|friday|saturday|sunday|weekday|month|year)",
        "next week",
        "next month",
        "next year",
    ]
    
    init(string: String) {
        self.string = string
    }
    
    func highlightedRanges() -> [NSRange] {
        var result = [NSRange]()
        for pattern in patterns {
            if let regexp = try? NSRegularExpression(pattern: pattern, options: []) {
                result.append(regexp.rangeOfFirstMatchInString(self.string, options: [], range: NSMakeRange(0, self.string.characters.count)))
            }
        }
        return result
    }
}







