//
//  TaskCollectionListViewController.swift
//
//  Created by Sereivoan Yong on 1/14/22.
//

import UIKit

open class TaskCollectionListViewController<Response, Object>: TaskCollectionViewController<Response, [Object]> {

  open private(set) var objects: [Object] = []

  open override var isContentNilOrEmpty: Bool {
    return objects.isEmpty
  }

  open override func store(_ newObjects: [Object]?, for page: Int) {
    if page == 1 {
      objects.removeAll()
    }
    if let newObjects = newObjects {
      objects.append(contentsOf: newObjects)
    }
  }

  @objc(collectionView:numberOfItemsInSection:)
  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return objects.count
  }

  @objc(collectionView:cellForItemAtIndexPath:)
  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    fatalError()
  }
}
