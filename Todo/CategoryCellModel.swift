//
//  TodoCategoryViewModel.swift
//  Todo
//
//  Created by 陳小晶 on 16/1/15.
//  Copyright © 2016年 chi zhang. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CategoryCellModel {
    var numberOfItems: Int = 0
    var name = ""
    var objId: NSManagedObjectID?
    var indexPath: NSIndexPath?
    var editable = true
    var color: UIColor!
    var summaryItems: [String]?
}