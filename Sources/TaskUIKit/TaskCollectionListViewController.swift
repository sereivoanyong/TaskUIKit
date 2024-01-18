//
//  TaskCollectionListViewController.swift
//
//  Created by Sereivoan Yong on 1/14/22.
//

import UIKit

/// Subclass must implement these functions:
/// `startTasks(page:completion:)`
/// `contents`
open class TaskCollectionListViewController<Collection: RangeReplaceableCollection>: TaskCollectionViewController<Collection> where Collection.Index == Int {

  open var objects: Collection = .init()

  open override var contents: Collection? {
    return objects
  }

  open override func store(_ newObjects: Collection?, page: Int) {
    let newObjects = newObjects ?? .init()
    if page > 1 {
      objects.append(contentsOf: newObjects)
    } else {
      objects = newObjects
    }
  }

  open override func reloadData(_ newObjects: Collection?, page: Int) {
    if page > 1 {
      if let newObjects {
        let oldCount = objects.count - newObjects.count
        let section = sectionForObjects
        collectionView.insertItems(at: (oldCount..<objects.count).map { IndexPath(item: $0, section: section) })
      }
    } else {
      collectionView.reloadData()
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

  @objc(collectionView:numberOfItemsInSection:)
  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return numberOfObjects
  }

  @objc(collectionView:cellForItemAtIndexPath:)
  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    fatalError()
  }
}
