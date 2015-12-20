//
//  DataManager.swift
//  Todo
//
//  Created by Chi Zhang on 12/17/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import Foundation
import DQuery

class DataManager {
    static let instance = DataManager()
    let session: DQ
    
    private init() {
        session = DQ(modelName: "Todo")
    }
}