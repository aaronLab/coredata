//
//  EntityBowTie+CoreDataProperties.swift
//  BowTies
//
//  Created by Aaron Lee on 2022/03/19.
//  Copyright © 2022 Razeware. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit


extension EntityBowTie {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<EntityBowTie> {
    return NSFetchRequest<EntityBowTie>(entityName: "BowTie")
  }
  
  @NSManaged public var name: String?
  @NSManaged public var isFavorite: Bool
  @NSManaged public var lastWorn: Date?
  @NSManaged public var rating: Double
  @NSManaged public var searchKey: String?
  @NSManaged public var timesWorn: Int32
  @NSManaged public var id: UUID?
  @NSManaged public var url: URL?
  @NSManaged public var photoData: Data?
  @NSManaged public var tintColor: UIColor?
  
}

extension EntityBowTie : Identifiable {
  
}
