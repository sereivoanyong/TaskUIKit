//
//  TaskTableListViewController.swift
//
//  Created by Sereivoan Yong on 8/28/23.
//

import UIKit

/// Subclass must implement these functions:
/// `startTasks(page:completion:)`
open class TaskTableListViewController<Collection: RangeReplaceableCollection>: TaskTableViewController<Collection> where Collection.Index == Int {

  open var objects: Collection = .init()

  open override var contents: Collection? {
    return objects
  }

  open override func applyData(_ newObjects: Collection?, page: Int?) {
    let newObjects = newObjects ?? .init()
    if page == nil || page == 1 {
      objects = newObjects
      tableView.reloadData()
    } else {
      let oldCount = objects.count
      objects.append(contentsOf: newObjects)
      let currentCount = objects.count
      let section = sectionForObjects
      tableView.insertRows(at: (oldCount..<currentCount).map { IndexPath(item: $0, section: section) }, with: .automatic)
    }
  }

  open var sectionForObjects: Int {
    return 0
  }

  open var numberOfObjects: Int {
    return objects.count
  }

  open func object(at indexPath: IndexPath) -> Collection.Element {
    return objects[indexPath.item]
  }

  @objc(tableView:numberOfRowsInSection:)
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return numberOfObjects
  }

  @objc(tableView:cellForRowAtIndexPath:)
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    fatalError()
  }
}
