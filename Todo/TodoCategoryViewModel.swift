//
//  TodoCategoryViewModel.swift
//  Todo
//
//  Created by Chi Zhang on 1/7/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import Foundation
import CoreData

class TodoCategoryViewModel {
    let session = DataManager.instance.session
    var categories = [NSManagedObject]()
    
    func reloadDataFromDB(completion: (() -> ())? = nil) {
        
    }
}
