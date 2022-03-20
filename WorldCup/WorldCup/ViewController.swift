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
  // MARK: - Properties

  private let teamCellIdentifier = "teamCellReuseIdentifier"
  lazy var coreDataStack = CoreDataStack(modelName: "WorldCup")
  lazy var fetchedResultscontroller: NSFetchedResultsController<Team> = {
    let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()

    let zoneSort = NSSortDescriptor(key: #keyPath(Team.qualifyingZone), ascending: true)
    let scoreSort = NSSortDescriptor(key: #keyPath(Team.wins), ascending: false)
    let nameSort = NSSortDescriptor(key: #keyPath(Team.teamName), ascending: true)

    fetchRequest.sortDescriptors = [zoneSort, scoreSort, nameSort]

    let fetchedRequestController = NSFetchedResultsController(
      fetchRequest: fetchRequest,
      managedObjectContext: coreDataStack.managedContext,
      sectionNameKeyPath: #keyPath(Team.qualifyingZone),
      cacheName: "worldCup"
    )

    return fetchedRequestController
  }()

  // MARK: - IBOutlets

  @IBOutlet var tableView: UITableView!
  @IBOutlet var addButton: UIBarButtonItem!

  // MARK: - View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    importJSONSeedDataIfNeeded()

    fetchedResultscontroller.delegate = self

    do {
      try fetchedResultscontroller.performFetch()
    } catch let e {
      printError(e)
    }
  }

  private func printError(_ e: Error) {
    let e = e as NSError
    print("Error: \(e), \(e.userInfo)")
  }

  override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
      addButton.isEnabled = true
    }
  }
}

// MARK: - Internal

extension ViewController {
  func configure(cell: UITableViewCell, for indexPath: IndexPath) {
    guard let cell = cell as? TeamCell else {
      return
    }

    let team = fetchedResultscontroller.object(at: indexPath)
    cell.teamLabel.text = team.teamName
    cell.scoreLabel.text = "Wins: \(team.wins)"

    if let imageName = team.imageName {
      cell.flagImageView.image = UIImage(named: imageName)
    } else {
      cell.flagImageView.image = nil
    }
  }

  @IBAction func addTeam(_ sender: Any) {
    let alertController = UIAlertController(
      title: "Secret Team",
      message: "Add a new team",
      preferredStyle: .alert
    )

    alertController.addTextField { textField in
      textField.placeholder = "Team Name"
    }

    alertController.addTextField { textField in
      textField.placeholder = "Qualifying Zone"
    }

    let saveAction = UIAlertAction(
      title: "Save",
      style: .default
    ) { [weak self] _ in
      guard let self = self,
            let nameTextField = alertController.textFields?.first,
            let zoneTextField = alertController.textFields?.last else {
        return
      }

      let team = Team(context: self.coreDataStack.managedContext)
      team.teamName = nameTextField.text
      team.qualifyingZone = zoneTextField.text
      team.imageName = "wenderland-flag"
      self.coreDataStack.saveContext()
    }

    alertController.addAction(saveAction)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    present(alertController, animated: true)
  }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    fetchedResultscontroller.sections?.count ?? .zero
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let sectionInfo = fetchedResultscontroller.sections?[section] else {
      return .zero
    }

    return sectionInfo.numberOfObjects
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let sectionInfo = fetchedResultscontroller.sections?[section]
    return sectionInfo?.name
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: teamCellIdentifier, for: indexPath)
    configure(cell: cell, for: indexPath)
    return cell
  }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let team = fetchedResultscontroller.object(at: indexPath)
    team.wins += 1
    coreDataStack.saveContext()
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

// MARK: - Helper methods

extension ViewController {
  func importJSONSeedDataIfNeeded() {
    let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
    let count = try? coreDataStack.managedContext.count(for: fetchRequest)

    guard let teamCount = count,
          teamCount == 0 else {
      return
    }

    importJSONSeedData()
  }

  // swiftlint:disable force_unwrapping force_cast force_try
  func importJSONSeedData() {
    let jsonURL = Bundle.main.url(forResource: "seed", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)

    do {
      let jsonArray = try JSONSerialization.jsonObject(
        with: jsonData,
        options: [.allowFragments]
      ) as! [[String: Any]]

      for jsonDictionary in jsonArray {
        let teamName = jsonDictionary["teamName"] as! String
        let zone = jsonDictionary["qualifyingZone"] as! String
        let imageName = jsonDictionary["imageName"] as! String
        let wins = jsonDictionary["wins"] as! NSNumber

        let team = Team(context: coreDataStack.managedContext)
        team.teamName = teamName
        team.imageName = imageName
        team.qualifyingZone = zone
        team.wins = wins.int32Value
      }

      coreDataStack.saveContext()
      print("Imported \(jsonArray.count) teams")
    } catch let error as NSError {
      print("Error importing teams: \(error)")
    }
  }
  // swiftlint:enable force_unwrapping force_cast force_try
}

// MARK: - NSFetchedResultsControllerDelegate

extension ViewController: NSFetchedResultsControllerDelegate {
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }

  func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    didChange anObject: Any,
    at indexPath: IndexPath?,
    for type: NSFetchedResultsChangeType,
    newIndexPath: IndexPath?
  ) {
    switch type {
    case .insert:
      tableView.insertRows(at: [newIndexPath!], with: .automatic)
    case .delete:
      tableView.deleteRows(at: [indexPath!], with: .automatic)
    case .move:
      tableView.deleteRows(at: [indexPath!], with: .automatic)
      tableView.insertRows(at: [newIndexPath!], with: .automatic)
    case .update:
      let cell = tableView.cellForRow(at: indexPath!) as! TeamCell
      configure(cell: cell, for: indexPath!)
    @unknown default:
      fatalError()
    }
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
  }

  func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    didChange sectionInfo: NSFetchedResultsSectionInfo,
    atSectionIndex sectionIndex: Int,
    for type: NSFetchedResultsChangeType
  ) {
    let indexSet = IndexSet(integer: sectionIndex)

    switch type {
    case .insert:
      tableView.insertSections(indexSet, with: .automatic)
    case .delete:
      tableView.deleteSections(indexSet, with: .automatic)
    default:
      break
    }
  }
}
