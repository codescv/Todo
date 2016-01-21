//
//  ReminderViewController.swift
//  Todo
//
//  Created by 陳小晶 on 16/1/16.
//  Copyright © 2016年 chi zhang. All rights reserved.
//

import UIKit

class ReminderViewController: UITableViewController {
    let editReminderSegue = "editReminderSegue"
    let cancelEditSegue = "cancelEditSegue"
    
    var item: TodoItemCellModel!
    
    var hasReminder: Bool {
        get {
            return self.item.hasReminder ?? false
        }
        set {
            self.item.hasReminder = newValue
        }
    }
    
    var reminderDate: NSDate {
        get {
            return self.item.reminderDate ?? NSDate()
        }
        
        set {
            self.item.reminderDate = newValue
        }
    }
    
    var isRepeated: Bool {
        get {
            return self.item.isRepeated
        }
        set {
            self.item.isRepeated = newValue
        }
    }
    
    var repeatType: RepeatType {
        get {
            return self.item.repeatType ?? .Daily
        }
        set {
            self.item.repeatType = newValue
        }
    }
    
    var repeatValue: Set<Int> {
        get {
            return self.item.repeatValue
        }
        set {
            self.item.repeatValue = newValue
        }
    }
    
    @IBAction func didPickDate(picker: UIDatePicker) {
        self.reminderDate = picker.date
    }
    
    let weeklyRepeatValue = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    @IBAction func toggleReminder(sender: AnyObject) {
        self.hasReminder = !self.hasReminder
        self.tableView.reloadData()
    }
    
    @IBAction func toggleRepeat(sender: AnyObject) {
        self.isRepeated = !self.isRepeated
        self.tableView.reloadData()
    }
    
    
    enum CellType {
        case RemindSwitchCell
        case DatePickerCell
        case RepeatSwitchCell
        case RepeatTypeCell
        case RepeatValueCell
        
        func identifer() -> String {
            switch self {
            case .RemindSwitchCell:
                return "RemindSwitchCell"
            case .DatePickerCell:
                return "DatePickerCell"
            case .RepeatSwitchCell:
                return "RepeatSwitchCell"
            case .RepeatTypeCell:
                return "OptionCheckCell"
            case .RepeatValueCell:
                return "OptionCheckCell"
            }
        }
    }
    
        
    override func viewDidLoad() {
        self.tableView.estimatedRowHeight = 100
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "save:")
    }
    
    func save(sender: AnyObject?) {
        self.performSegueWithIdentifier(editReminderSegue, sender: self)
    }
    
    func cancel(sender: AnyObject?) {
        self.performSegueWithIdentifier(cancelEditSegue, sender: self)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            if !self.hasReminder {
                return 1
            }

            if !self.isRepeated {
                return 3
            }
            
            return 7
        } else {
            if !self.hasReminder || !self.isRepeated {
                return 0
            }
            
            if self.repeatType == .Weekly {
                return self.weeklyRepeatValue.count
            }
            return 0
        }
    }
    
    func cellTypeForIndexPath(indexPath: NSIndexPath) -> CellType {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                return .RemindSwitchCell
            case 1:
                return .DatePickerCell
            case 2:
                return .RepeatSwitchCell
            case 3...6:
                return .RepeatTypeCell
            default:
                fatalError("UnknownCellType")
            }
        } else {
            return .RepeatValueCell
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellType = cellTypeForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(cellType.identifer())!
        switch cellType {
        case .RemindSwitchCell:
            if let control = cell.contentView.viewWithTag(1) as? UISwitch {
                control.on = self.hasReminder
            }
            cell.selectionStyle = .None
        case .RepeatSwitchCell:
            if let control = cell.contentView.viewWithTag(1) as? UISwitch {
                control.on = self.isRepeated
            }
            cell.selectionStyle = .None
        case .RepeatTypeCell:
            let repeatType = RepeatType(rawValue: indexPath.row - 3)!
            if let label = cell.contentView.viewWithTag(1) as? UILabel {
                label.text = repeatType.name()
            }
            if let check = cell.contentView.viewWithTag(2) as? UILabel {
                if repeatType == self.repeatType {
                    check.hidden = false
                } else {
                    check.hidden = true
                }
            }
        case .DatePickerCell:
            if let datePicker = cell.contentView.viewWithTag(1) as? UIDatePicker {
                datePicker.date = self.reminderDate
            }
        case .RepeatValueCell:
            if repeatType == .Weekly {
                let r = indexPath.row
                if let label = cell.contentView.viewWithTag(1) as? UILabel {
                    label.text = self.weeklyRepeatValue[r]
                }
                if let check = cell.contentView.viewWithTag(2) as? UILabel {
                    check.hidden = true
                    if self.repeatValue.contains(r) {
                        check.hidden = false
                    }
                }
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            if let repeatType = RepeatType(rawValue: indexPath.row - 3) {
                self.repeatType = repeatType
                tableView.reloadData()
            }
        } else {
            let r = indexPath.row
            if self.repeatValue.contains(r) {
                self.repeatValue.remove(r)
            } else {
                self.repeatValue.insert(r)
            }
            tableView.reloadData()
        }
        
    }
}
