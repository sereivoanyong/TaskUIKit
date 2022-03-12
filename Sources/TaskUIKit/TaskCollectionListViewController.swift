//
//  TaskCollectionListViewController.swift
//
//  Created by Sereivoan Yong on 1/14/22.
//

import UIKit

open class TaskCollectionListViewController<Response, Object>: TaskCollectionViewController<Response, [Object]> {

  open var objects: [Object] = []

  open override var isContentNilOrEmpty: Bool {
    return objects.isEmpty
  }

  open override func store(_ newObjects: [Object]?, for page: Int) {
    let newObjects = newObjects ?? []
    if page == 1 {
      objects = newObjects
    } else {
      objects.append(contentsOf: newObjects)
    }
  }

  open var numberOfObjects: Int {
    return objects.count
  }

  open func object(at indexPath: IndexPath) -> Object {
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
