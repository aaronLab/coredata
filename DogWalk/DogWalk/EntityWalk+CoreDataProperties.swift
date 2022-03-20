//
//  EntityWalk+CoreDataProperties.swift
//  DogWalk
//
//  Created by Aaron Lee on 2022/03/19.
//  Copyright © 2022 Razeware. All rights reserved.
//
//

import CoreData
import Foundation

public extension EntityWalk {
  @nonobjc class func fetchRequest() -> NSFetchRequest<EntityWalk> {
    NSFetchRequest<EntityWalk>(entityName: "Walk")
  }

  @NSManaged var date: Date?
  @NSManaged var dog: EntityDog?
}

extension EntityWalk: Identifiable {}
