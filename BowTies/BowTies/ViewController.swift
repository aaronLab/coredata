/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import CoreData
import UIKit

class ViewController: UIViewController {
  var managedContext: NSManagedObjectContext!

  var currentBowTie: EntityBowTie!

  // MARK: - IBOutlets

  @IBOutlet var segmentedControl: UISegmentedControl!
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var nameLabel: UILabel!
  @IBOutlet var ratingLabel: UILabel!
  @IBOutlet var timesWornLabel: UILabel!
  @IBOutlet var lastWornLabel: UILabel!
  @IBOutlet var favoriteLabel: UILabel!
  @IBOutlet var wearButton: UIButton!
  @IBOutlet var rateButton: UIButton!

  // MARK: - View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    managedContext = appDelegate?.persistentContainer.viewContext

    insertSampleData()

    let request: NSFetchRequest<EntityBowTie> = EntityBowTie.fetchRequest()
    let firstTitle = segmentedControl.titleForSegment(at: 0) ?? ""
    request.predicate = NSPredicate(
      format: "%K = %@",
      argumentArray: [#keyPath(EntityBowTie.searchKey), firstTitle]
    )

    do {
      let results = try managedContext.fetch(request)

      if let tie = results.first {
        populate(bowtie: tie)
      }
    } catch let e as NSError {
      print("Could not fetch \(e), \(e.userInfo)")
    }
  }

  private func populate(bowtie: EntityBowTie) {
    guard let imageData = bowtie.photoData,
          let lastWorn = bowtie.lastWorn,
          let tintColor = bowtie.tintColor
    else {
      return
    }

    imageView.image = UIImage(data: imageData)
    nameLabel.text = bowtie.name
    ratingLabel.text = "Rating: \(bowtie.rating)/5"

    timesWornLabel.text = "# times worn: \(bowtie.timesWorn)"

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .none

    lastWornLabel.text = "Last worn: \(dateFormatter.string(from: lastWorn))"

    favoriteLabel.isHidden = !bowtie.isFavorite
    view.tintColor = tintColor

    currentBowTie = bowtie
  }

  // MARK: - IBActions

  @IBAction func segmentedControl(_ sender: UISegmentedControl) {
    guard let selectedValue = sender.titleForSegment(at: sender.selectedSegmentIndex) else {
      return
    }

    let request: NSFetchRequest<EntityBowTie> = EntityBowTie.fetchRequest()
    request.predicate = NSPredicate(
      format: "%K = %@",
      argumentArray: [#keyPath(EntityBowTie.searchKey), selectedValue]
    )

    do {
      let results = try managedContext.fetch(request)
      guard let tie = results.first else {
        print("Could not fetch")
        return
      }

      currentBowTie = tie
      populate(bowtie: currentBowTie)
    } catch let e as NSError {
      print("Could not fetch \(e), \(e.userInfo)")
    }
  }

  @IBAction func wear(_: UIButton) {
    currentBowTie.timesWorn += 1
    currentBowTie.lastWorn = Date()

    do {
      try managedContext.save()
      populate(bowtie: currentBowTie)
    } catch let e as NSError {
      print("Could not save \(e), \(e.userInfo)")
    }
  }

  @IBAction func rate(_: UIButton) {
    let alert = UIAlertController(title: "New Rating",
                                  message: "Rate this bow tie",
                                  preferredStyle: .alert)

    alert.addTextField { textField in
      textField.keyboardType = .decimalPad
    }

    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .cancel)

    let saveAction = UIAlertAction(title: "Save",
                                   style: .default) { [weak self] _ in
      guard let self = self,
            let textField = alert.textFields?.first
      else {
        return
      }

      self.update(rating: textField.text)
    }

    alert.addAction(cancelAction)
    alert.addAction(saveAction)

    present(alert, animated: true)
  }

  private func update(rating: String?) {
    guard let str = rating,
          let rating = Double(str)
    else {
      return
    }

    do {
      currentBowTie.rating = rating
      try managedContext.save()
      populate(bowtie: currentBowTie)
    } catch let e as NSError {
      if e.domain == NSCocoaErrorDomain,
         e.code == NSValidationNumberTooLargeError || e
         .code == NSValidationNumberTooSmallError
      {
        rate(rateButton)
        return
      }

      print("Could not save \(e), \(e.userInfo)")
    }
  }

  private func insertSampleData() {
    let fetch: NSFetchRequest<EntityBowTie> = EntityBowTie.fetchRequest()
    fetch.predicate = NSPredicate(format: "searchKey != nil")

    let tieCount = (try? managedContext.count(for: fetch)) ?? .zero

    if tieCount > .zero {
      // SampleData.plist data already in Core Data
      return
    }

    let path = Bundle.main.url(forResource: "SampleData", withExtension: "plist")!
    let data = try! Data(contentsOf: path)
    let dataArray = try! PropertyListSerialization
      .propertyList(from: data, format: nil) as! [[String: Any]]

    for dict in dataArray {
      let entity = NSEntityDescription.entity(
        forEntityName: "BowTie",
        in: managedContext
      )!

      let bowtie = EntityBowTie(entity: entity, insertInto: managedContext)

      bowtie.id = UUID(uuidString: dict["id"] as! String)
      bowtie.name = dict["name"] as? String
      bowtie.searchKey = dict["searchKey"] as? String
      bowtie.rating = dict["rating"] as! Double

      let colorDict = dict["tintColor"] as! [String: Any]
      bowtie.tintColor = UIColor.color(dict: colorDict)

      let imageName = dict["imageName"] as? String
      let image = UIImage(named: imageName!)
      bowtie.photoData = image?.pngData()
      bowtie.lastWorn = dict["lastWorn"] as? Date

      let timesNumber = dict["timesWorn"] as! NSNumber
      bowtie.timesWorn = timesNumber.int32Value
      bowtie.isFavorite = dict["isFavorite"] as! Bool
      bowtie.url = URL(string: dict["url"] as! String)
    }

    try? managedContext.save()
  }
}

private extension UIColor {
  static func color(dict: [String: Any]) -> UIColor? {
    guard
      let red = dict["red"] as? NSNumber,
      let green = dict["green"] as? NSNumber,
      let blue = dict["blue"] as? NSNumber
    else {
      return nil
    }

    return UIColor(
      red: CGFloat(truncating: red) / 255.0,
      green: CGFloat(truncating: green) / 255.0,
      blue: CGFloat(truncating: blue) / 255.0,
      alpha: 1
    )
  }
}
