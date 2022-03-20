//
//  CoreDataStack.swift
//  DogWalk
//
//  Created by Aaron Lee on 2022/03/19.
//  Copyright © 2022 Razeware. All rights reserved.
//

import CoreData
import Foundation

class CoreDataStack {
  private let modelName: String

  init(model: Model) {
    modelName = model.rawValue
  }

  private lazy var storeContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: modelName)

    container.loadPersistentStores { _, e in
      guard let e = e as? NSError else { return }

      print("Unresolved error \(e), \(e.userInfo)")
    }

    return container
  }()

  lazy var managedContext: NSManagedObjectContext = storeContainer.viewContext

  func saveContext() {
    guard managedContext.hasChanges else { return }

    do {
      try managedContext.save()
    } catch let e as NSError {
      print("Unaresolved error \(e), \(e.userInfo)")
    }
  }
}
