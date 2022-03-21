//
//  Attachment.swift
//  UnCloudNotes
//
//  Created by Aaron Lee on 2022/03/21.
//  Copyright © 2022 Ray Wenderlich. All rights reserved.
//

import CoreData
import Foundation
import UIKit

class Attachment: NSManagedObject {
  @NSManaged var dateCreated: Date
  @NSManaged var image: UIImage?
  @NSManaged var note: Note?
}
