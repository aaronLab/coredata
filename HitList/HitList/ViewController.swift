//
//  ViewController.swift
//  HitList
//
//  Created by Aaron Lee on 2022/03/18.
//

import CoreData
import UIKit

class ViewController: UIViewController {
  var names: [String] = []

  var people: [NSManagedObject] = []

  private let cellIdentifier = "cell"

  @IBOutlet var tableView: UITableView!
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "The List"
    tableView.register(UITableViewCell.self,
                       forCellReuseIdentifier: cellIdentifier)

    tableView.dataSource = self
    tableView.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    let managedContext = UIApplication.shared.appDelegate.persistentContainer.viewContext

    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Person")

    do {
      people = try managedContext.fetch(fetchRequest)
    } catch let e as NSError {
      print("Could not fetch. \(e), \(e.userInfo)")
    }
  }

  @IBAction func addName(_: UIBarButtonItem) {
    let alert = UIAlertController(title: "New Name",
                                  message: "Add a new name",
                                  preferredStyle: .alert)

    let saveAction = UIAlertAction(title: "Save",
                                   style: .default) { [weak self] _ in
      guard let self = self else { return }

      guard let textField = alert.textFields?.first,
            let nameToSave = textField.text
      else {
        return
      }

      self.save(name: nameToSave)
      self.tableView.reloadData()
    }

    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .cancel)

    alert.addTextField()
    alert.textFields?.first?.returnKeyType = .done

    alert.addAction(saveAction)
    alert.addAction(cancelAction)

    present(alert, animated: true)
  }

  private func save(name: String) {
    let managedContext = UIApplication.shared.appDelegate.persistentContainer.viewContext

    guard let entity = NSEntityDescription.entity(forEntityName: "Person", in: managedContext)
    else {
      return
    }

    let person = NSManagedObject(entity: entity, insertInto: managedContext)
    person.setValue(name, forKey: "name")

    do {
      try managedContext.save()
      people.append(person)
    } catch let e as NSError {
      print("Could not save. \(e), \(e.userInfo)")
    }
  }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    people.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

    cell.selectionStyle = .none

    var content = cell.defaultContentConfiguration()

    let person = people[indexPath.row]
    content.text = person.value(forKey: "name") as? String

    cell.contentConfiguration = content

    return cell
  }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
  func tableView(_: UITableView,
                 trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
    let deleteAction = UIContextualAction(style: .destructive,
                                          title: "Delete") { [weak self] _, _, completion in
      guard let self = self else { return }

      self.deletePerson(at: indexPath)

      completion(true)
    }

    let config = UISwipeActionsConfiguration(actions: [deleteAction])

    return config
  }

  private func deletePerson(at indexPath: IndexPath) {
    let managedContext = UIApplication.shared.appDelegate.persistentContainer.viewContext

    let person = people[indexPath.row]
    managedContext.delete(person)

    people.remove(at: indexPath.item)
    tableView.deleteRows(at: [indexPath], with: .fade)

    UIApplication.shared.appDelegate.saveContext()
  }
}

extension UIApplication {
  var appDelegate: AppDelegate {
    delegate as! AppDelegate
  }
}
