//
//  TodoItemCategory.swift
//  Todo
//
//  Created by Chi Zhang on 12/19/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import Foundation
import CoreData
import DQuery


enum CategoryColor: Int {
    case Blue = 0
    case Cyan
    case Red
    case Orange
    case Green
    case End
    
    func color() -> UIColor {
        switch self {
        case .Blue:
            return UIColor(red: 16.0/255, green: 122.0/255, blue: 255.0/255, alpha: 1.0)
        case .Red:
            return UIColor(red: 255.0/255, green: 0, blue: 0, alpha: 1.0)
        case .Cyan:
            return UIColor(red: 181.0/255, green: 238.0/255, blue: 255.0/255, alpha: 1.0)
        case .Orange:
            return UIColor(red: 255.0/255, green: 127.0/255, blue: 0, alpha: 1.0)
        case .Green:
            return UIColor(red: 54.0/255, green: 192.0/255, blue: 44.0/255, alpha: 1.0)
        default:
            return UIColor(red: 16.0/255, green: 122.0/255, blue: 255.0/255, alpha: 1.0)
        }
    }
    
    static func all() -> [CategoryColor] {
        return (0..<CategoryColor.End.rawValue).map { CategoryColor(rawValue: $0)! }
    }
}


class TodoItemCategory: NSManagedObject {
    
    class func lastDisplayOrder(context: NSManagedObjectContext) -> Int {
        if let item = DQ.query(self, context: context).max("displayOrder").first() {
            if let order = item.displayOrder?.integerValue {
                return order + 1
            }
        }
        return 0
    }

    var color: UIColor {
        if let colorType = self.colorType?.integerValue {
            return CategoryColor(rawValue: colorType)!.color()
        }
        return CategoryColor.Blue.color()
    }
}
