//
//  LocalStorageService.swift
//  smoggler
//
//  Created by Christophe de Batz on 17/12/2017.
//  Copyright © 2017 Christophe de Batz. All rights reserved.
//

import Foundation
import CoreData

class LocalStorageService {
    
    let managedObjectContext: NSManagedObjectContext!
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    
    func removeAllCigarettes() -> Void {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Cigarette")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            try managedObjectContext?.execute(request)
        } catch {
            fatalError("Failed to fetch smoking moments: \(error)")
        }
    }
    
    
}
