//
//  TaskCollectionListViewController.swift
//
//  Created by Sereivoan Yong on 1/14/22.
//

import UIKit

/// Subclass must implement these functions:
/// `startTasks(of:cancellables:completion:)`
open class TaskCollectionListViewController<Collection: RangeReplaceableCollection>: TaskCollectionViewController<Collection> where Collection.Index == Int {

  open var objects: Collection = .init()

  open override var contents: Collection? {
    return objects
  }

  open override func applyData(_ contents: SourcedContents?, completion: @escaping () -> Void) {
    guard let contents else {
      objects.removeAll()
      collectionView.reloadData()
      completion()
      return
    }
    switch contents {
    case .response(let newObjects, let isInitial, _):
      if isInitial {
        objects = newObjects
        collectionView.reloadData()
      } else {
        let oldCount = objects.count
        objects.append(contentsOf: newObjects)
        let currentCount = objects.count
        let section = sectionForObjects
        collectionView.insertItems(at: (oldCount..<currentCount).map { IndexPath(item: $0, section: section) })
      }
      completion()
    case .cache(let newObjects):
      objects = newObjects
      collectionView.reloadData()
      completion()
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
