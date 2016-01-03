//
//  DQuery.swift
//  Todo
//
//  Created by Chi Zhang on 12/14/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import Foundation
import CoreData

/**
 wrapper of context
*/
public class DQ {
    let modelName: String
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.codescv.productivity.Todo" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("\(self.modelName).sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    // the context for main queue
    public lazy var defaultContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        
        var context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.parentContext = self.rootContext
        return context
    }()
    
    // the private writer context running on background
    lazy var rootContext: NSManagedObjectContext = {
        var context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.performBlockAndWait({
            let coordinator = self.persistentStoreCoordinator
            context.persistentStoreCoordinator = coordinator
        })
        
        return context
    }()
        
    func saveContext () {
        self.defaultContext.performBlockAndWait({
            // TODO this is run on the UI queue, count the performance
            if self.defaultContext.hasChanges {
                do {
                    try self.defaultContext.save()
                    print("saved default")
                } catch {
                    print("save default error")
                    return
                }
            }
        })
        
        self.rootContext.performBlock({
            if self.rootContext.hasChanges {
                do {
                    try self.rootContext.save()
                    print("saved root")
                } catch {
                    print("save root error")
                    return
                }
            }
        })
    }

    
    public init(modelName: String) {
        self.modelName = modelName
    }
    
    public func query<T:NSManagedObject>(entity: T.Type) -> DQQuery<T> {
        let entityName:String = NSStringFromClass(entity).componentsSeparatedByString(".").last!
        return DQQuery<T>(entityName: entityName, context: self.defaultContext)
    }
    
    public func query<T:NSManagedObject>(entity: T.Type, context: NSManagedObjectContext) -> DQQuery<T> {
        let entityName:String = NSStringFromClass(entity).componentsSeparatedByString(".").last!
        return DQQuery<T>(entityName: entityName, context: context)
    }
    
    public func insertObject<T:NSManagedObject>(entity: T.Type, context: NSManagedObjectContext) -> T {
        let entityName = NSStringFromClass(entity).componentsSeparatedByString(".").last!
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! T
    }
    
    public func insertObject<T:NSManagedObject>(entity: T.Type) -> T {
        let entityName = NSStringFromClass(entity).componentsSeparatedByString(".").last!
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.rootContext) as! T
    }
    
    public func write(block: (NSManagedObjectContext)->Void, sync: Bool = false, completion: (()->Void)? = nil) {
        let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateContext.parentContext = defaultContext
        
        let writeBlock = {
            block(privateContext)
            do {
                try privateContext.save()
            } catch {
                print("unable to save private context!")
            }
            self.saveContext()
            dispatch_async(dispatch_get_main_queue(), {
                completion?()
            })
        }
        
        if sync {
            privateContext.performBlockAndWait(writeBlock)
        } else {
            privateContext.performBlock(writeBlock)
        }
    }
}


public class DQQuery<T:NSManagedObject> {
    let entityName: String
    let context: NSManagedObjectContext
    var predicate: NSPredicate?
    var sortDescriptors = [NSSortDescriptor]()
    var section: String?
    var limit: Int?
    
    private var fetchRequest: NSFetchRequest {
        get {
            let request = NSFetchRequest(entityName: entityName)
            if let pred = predicate {
                request.predicate = pred
            }
            //let idSort = NSSortDescriptor(key: "id", ascending: true)
            request.sortDescriptors = self.sortDescriptors
            if let limit = self.limit {
                request.fetchLimit = limit
            }
            return request
        }
    }

    public init(entityName: String, context: NSManagedObjectContext) {
        self.context = context
        self.entityName = entityName
    }
    
    public func filter(format: String, _ args: AnyObject...) -> Self {
        let pred = NSPredicate(format: format, argumentArray: args)
        
        if let oldPred = predicate {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [oldPred, pred])
        } else {
            predicate = pred
        }
        
        return self
    }
    
    public func groupBy(section: String) -> Self {
        self.section = section
        return self
    }
    
    public func orderBy(key: String, ascending: Bool = true) -> Self {
        self.sortDescriptors.append(NSSortDescriptor(key: key, ascending: ascending))
        return self
    }
    
    public func limit(limit: Int) -> Self {
        self.limit = limit
        return self
    }
    
    public func max(key: String) -> Self {
        return orderBy(key, ascending: false).limit(1)
    }
    
    public func min(key: String) -> Self {
        return orderBy(key, ascending: true).limit(1)
    }
    
    // sync fetch
    public func all() -> [T] {
        var results = [T]()
        
        context.performBlockAndWait({
            let request = self.fetchRequest
            if let r = try? self.context.executeFetchRequest(request) {
                results = r as! [T]
            }
        })
        
        return results
    }
    
    // sync count
    public func count() -> Int {
        var result = 0
        
        context.performBlockAndWait({
            let request = self.fetchRequest
            if let r = try? self.context.executeFetchRequest(request) {
                result = r.count
            }
        })
        
        return result
    }
    
    // return fist object
    public func first() -> T? {
        var result: T?
        
        context.performBlockAndWait({
            let request = self.fetchRequest
            if let r = try? self.context.executeFetchRequest(request) {
                for rr in r {
                    result = rr as? T
                    break
                }
            }
        })
        
        return result
    }

    
    // async fetch
    public func execute(complete: ((NSManagedObjectContext, [NSManagedObjectID]) -> Void)? = nil) {
        let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateContext.parentContext = self.context
//        let defaultContext = self.context
        
        privateContext.performBlock {
            let request = self.fetchRequest
            if let results = try? privateContext.executeFetchRequest(request) {
                var objectIDs = [NSManagedObjectID]()
                for r in results {
                    objectIDs.append(r.objectID)
                }
                
                complete?(privateContext, objectIDs)
                
//                dispatch_async(dispatch_get_main_queue(), {
//                    complete?(defaultContext, objectIDs)
//                })
            }
        }
    }
    
    // delete all objects matching query
//    public func delete(sync sync: Bool = false, complete: (() -> Void)? = nil) {
//        let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
//        privateContext.parentContext = dq.defaultContext
//        
//        let deleteBlock = {
//            let request = self.fetchRequest
//            if let results = try? privateContext.executeFetchRequest(request) {
//                for r in results {
//                    r.dq_delete()
//                }
//                do {
//                    try privateContext.save()
//                } catch {
//                    print("unable to delete")
//                }
//                self.dq.saveContext()
//                dispatch_async(dispatch_get_main_queue(), {
//                    complete?()
//                })
//            }
//        }
//        
//        if sync {
//            privateContext.performBlockAndWait(deleteBlock)
//        } else {
//            privateContext.performBlock(deleteBlock)
//        }
//    }
    
    public func fetchedResultsController() -> NSFetchedResultsController {
        return NSFetchedResultsController(fetchRequest: self.fetchRequest,
            managedObjectContext: self.context,
            sectionNameKeyPath: self.section, cacheName: entityName)
    }
}


// TODO REFACTOR: move to separate file
public extension NSManagedObject {
    public class func dq_insertInContext(context: NSManagedObjectContext) -> Self {
        return insertInContextHelper(context)
    }
    
    private class func insertInContextHelper<T>(context: NSManagedObjectContext) -> T {
        let entityName = NSStringFromClass(self).componentsSeparatedByString(".").last!
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! T
    }
    
    public func dq_delete() {
        self.managedObjectContext?.deleteObject(self)
    }
}


// TODO REFACTOR: move to separate file
public extension NSManagedObjectContext {
    public func dq_objectWithID<T: NSManagedObject>(id: NSManagedObjectID) -> T {
        return self.objectWithID(id) as! T
    }
    
    public func dq_objectsWithIDs<T: NSManagedObject>(ids: [NSManagedObjectID]) -> [T] {
        return ids.map { (id) -> T in
            dq_objectWithID(id)
        }
    }
}


