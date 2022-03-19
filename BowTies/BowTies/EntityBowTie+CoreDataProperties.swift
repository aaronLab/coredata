//
//  EntityBowTie+CoreDataProperties.swift
//  BowTies
//
//  Created by Aaron Lee on 2022/03/19.
//  Copyright © 2022 Razeware. All rights reserved.
//
//

import CoreData
import Foundation
import UIKit

public extension EntityBowTie {
    @nonobjc class func fetchRequest() -> NSFetchRequest<EntityBowTie> {
        return NSFetchRequest<EntityBowTie>(entityName: "BowTie")
    }

    @NSManaged var name: String?
    @NSManaged var isFavorite: Bool
    @NSManaged var lastWorn: Date?
    @NSManaged var rating: Double
    @NSManaged var searchKey: String?
    @NSManaged var timesWorn: Int32
    @NSManaged var id: UUID?
    @NSManaged var url: URL?
    @NSManaged var photoData: Data?
    @NSManaged var tintColor: UIColor?
}

extension EntityBowTie: Identifiable {}
