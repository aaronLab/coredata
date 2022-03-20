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

protocol FilterViewControllerDelegate: AnyObject {
    func filterViewController(
        filter: FilterViewController,
        didSelectPredicate predicate: NSPredicate?,
        sortDescriptor: NSSortDescriptor?
    )
}

class FilterViewController: UITableViewController {
    @IBOutlet var firstPriceCategoryLabel: UILabel!
    @IBOutlet var secondPriceCategoryLabel: UILabel!
    @IBOutlet var thirdPriceCategoryLabel: UILabel!
    @IBOutlet var numDealsLabel: UILabel!

    // MARK: - Price section

    @IBOutlet var cheapVenueCell: UITableViewCell!
    @IBOutlet var moderateVenueCell: UITableViewCell!
    @IBOutlet var expensiveVenueCell: UITableViewCell!

    // MARK: - Most popular section

    @IBOutlet var offeringDealCell: UITableViewCell!
    @IBOutlet var walkingDistanceCell: UITableViewCell!
    @IBOutlet var userTipsCell: UITableViewCell!

    // MARK: - Sort section

    @IBOutlet var nameAZSortCell: UITableViewCell!
    @IBOutlet var nameZASortCell: UITableViewCell!
    @IBOutlet var distanceSortCell: UITableViewCell!
    @IBOutlet var priceSortCell: UITableViewCell!

    // MARK: - Properties

    var coreDataStack: CoreDataStack!

    weak var delegate: FilterViewControllerDelegate?
    var selectedSortDescriptor: NSSortDescriptor?
    var selectedPredicate: NSPredicate?

    lazy var cheapVenuePredicate: NSPredicate = .init(format: "%K == %@",
                                                      #keyPath(Venue.priceInfo.priceCategory), "$")

    lazy var moderateVenuPredicate: NSPredicate = .init(format: "%K == %@",
                                                        #keyPath(Venue.priceInfo.priceCategory), "$$")

    lazy var expensiveVenuePredicate: NSPredicate = .init(format: "%K == %@",
                                                          #keyPath(Venue.priceInfo.priceCategory), "$$$")

    lazy var offeringDealPredicate: NSPredicate = .init(format: "%K > 0",
                                                        #keyPath(Venue.specialCount))

    lazy var walkingDistancePredicate: NSPredicate = .init(format: "%K < 500",
                                                           #keyPath(Venue.location.distance))

    lazy var hasUserTipsPredicate: NSPredicate = .init(format: "%K > 0",
                                                       #keyPath(Venue.stats.tipCount))

    lazy var nameSortDescriptor: NSSortDescriptor = {
        let compareSelector = #selector(NSString.localizedStandardCompare(_:))
        return NSSortDescriptor(key: #keyPath(Venue.name),
                                ascending: true,
                                selector: compareSelector)
    }()

    lazy var distanceDescriptor: NSSortDescriptor = .init(key: #keyPath(Venue.location.distance),
                                                          ascending: true)

    lazy var priceSortDescriptor: NSSortDescriptor = .init(key: #keyPath(Venue.priceInfo.priceCategory),
                                                           ascending: true)

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        applyCount(predicate: cheapVenuePredicate, for: firstPriceCategoryLabel)
        applyCount(predicate: moderateVenuPredicate, for: secondPriceCategoryLabel)
        applyCountWithoutResultType(predicate: expensiveVenuePredicate, for: thirdPriceCategoryLabel)
        populateDealsCountLabel()
    }
}

// MARK: - IBActions

extension FilterViewController {
    @IBAction func search(_: UIBarButtonItem) {
        delegate?.filterViewController(filter: self,
                                       didSelectPredicate: selectedPredicate,
                                       sortDescriptor: selectedSortDescriptor)

        dismiss(animated: true)
    }
}

// MARK: - Helpers

extension FilterViewController {
    private func applyCount(predicate: NSPredicate, for label: UILabel) {
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: "Venue")
        fetchRequest.resultType = .countResultType
        fetchRequest.predicate = predicate

        do {
            let countResult = try coreDataStack.managedContext.fetch(fetchRequest)
            let count = countResult.first?.intValue ?? .zero
            applyString(with: count, for: label)
        } catch let e {
            printCountError(e)
        }
    }

    private func applyCountWithoutResultType(predicate: NSPredicate, for label: UILabel) {
        let fetchRequest: NSFetchRequest<Venue> = Venue.fetchRequest()
        fetchRequest.predicate = predicate

        do {
            let count = try coreDataStack.managedContext.count(for: fetchRequest)
            applyString(with: count, for: label)
        } catch let e {
            printCountError(e)
        }
    }

    private func applyString(with count: Int, for label: UILabel) {
        let pluralized = count == 1 ? "place" : "places"

        label.text = "\(count) bubble tea \(pluralized)"
    }

    private func populateDealsCountLabel() {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "Venue")
        fetchRequest.resultType = .dictionaryResultType

        let sumExpDesc = NSExpressionDescription()
        sumExpDesc.name = "sumDeals"

        let specialCountExp = NSExpression(forKeyPath: #keyPath(Venue.specialCount))
        sumExpDesc.expression = NSExpression(forFunction: "sum:",
                                             arguments: [specialCountExp])
        sumExpDesc.expressionResultType = .integer32AttributeType

        fetchRequest.propertiesToFetch = [sumExpDesc]

        do {
            let result = try coreDataStack.managedContext.fetch(fetchRequest)
            let dict = result.first
            let deals = dict?["sumDeals"] as? Int ?? .zero
            let pluralized = deals == 1 ? "deal" : "deals"
            numDealsLabel.text = "\(deals) \(pluralized)"
        } catch let e {
            printCountError(e)
        }
    }

    private func printCountError(_ e: Error) {
        let e = e as NSError
        print("Count not fetched \(e), \(e.userInfo)")
    }
}

// MARK: - UITableViewDelegate

extension FilterViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        switch cell {
        case cheapVenueCell:
            selectedPredicate = cheapVenuePredicate

        case moderateVenueCell:
            selectedPredicate = moderateVenuPredicate

        case expensiveVenueCell:
            selectedPredicate = expensiveVenuePredicate

        case offeringDealCell:
            selectedPredicate = offeringDealPredicate

        case walkingDistanceCell:
            selectedPredicate = walkingDistancePredicate

        case userTipsCell:
            selectedPredicate = hasUserTipsPredicate

        case nameAZSortCell:
            selectedSortDescriptor = nameSortDescriptor

        case nameZASortCell:
            selectedSortDescriptor = nameSortDescriptor.reversedSortDescriptor as? NSSortDescriptor

        case distanceSortCell:
            selectedSortDescriptor = distanceDescriptor

        case priceSortCell:
            selectedSortDescriptor = priceSortDescriptor

        default: break
        }

        cell.accessoryType = .checkmark

        for section in .zero ..< tableView.numberOfSections {
            for row in .zero ..< tableView.numberOfRows(inSection: section) {
                let currentIndexPath = IndexPath(row: row, section: section)

                guard currentIndexPath != indexPath,
                      let cell = tableView.cellForRow(at: currentIndexPath)
                else {
                    continue
                }

                cell.accessoryType = .none
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
