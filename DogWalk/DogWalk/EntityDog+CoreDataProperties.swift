//
//  EntityDog+CoreDataProperties.swift
//  DogWalk
//
//  Created by Aaron Lee on 2022/03/19.
//  Copyright © 2022 Razeware. All rights reserved.
//
//

import CoreData
import Foundation

public extension EntityDog {
  @nonobjc class func fetchRequest() -> NSFetchRequest<EntityDog> {
    NSFetchRequest<EntityDog>(entityName: "Dog")
  }

  @NSManaged var name: String?
  @NSManaged var walks: NSOrderedSet?
}

// MARK: Generated accessors for walks

public extension EntityDog {
  @objc(insertObject:inWalksAtIndex:)
  @NSManaged func insertIntoWalks(_ value: EntityWalk, at idx: Int)

  @objc(removeObjectFromWalksAtIndex:)
  @NSManaged func removeFromWalks(at idx: Int)

  @objc(insertWalks:atIndexes:)
  @NSManaged func insertIntoWalks(_ values: [EntityWalk], at indexes: NSIndexSet)

  @objc(removeWalksAtIndexes:)
  @NSManaged func removeFromWalks(at indexes: NSIndexSet)

  @objc(replaceObjectInWalksAtIndex:withObject:)
  @NSManaged func replaceWalks(at idx: Int, with value: EntityWalk)

  @objc(replaceWalksAtIndexes:withWalks:)
  @NSManaged func replaceWalks(at indexes: NSIndexSet, with values: [EntityWalk])

  @objc(addWalksObject:)
  @NSManaged func addToWalks(_ value: EntityWalk)

  @objc(removeWalksObject:)
  @NSManaged func removeFromWalks(_ value: EntityWalk)

  @objc(addWalks:)
  @NSManaged func addToWalks(_ values: NSOrderedSet)

  @objc(removeWalks:)
  @NSManaged func removeFromWalks(_ values: NSOrderedSet)
}

extension EntityDog: Identifiable {}
