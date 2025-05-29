//
//  RealmCachingViewModels.swift
//  TaskRealmUIKit
//
//  Created by Sereivoan Yong on 1/8/25.
//

import UIKit
import SwiftKit
import EmptyUIKit
import RealmSwift

public typealias AnyRealmCachingViewModels<Object: RealmSwift.Object, ViewModel> = RealmCachingViewModels<AnyRealmCollection<Object>, ViewModel>

open class RealmCachingViewModels<Collection: RealmCollection, ViewModel>: CachingViewModels<Collection, ViewModel> where Collection.Element: RealmSwift.Object, Collection.Index == Int {

  private var token: NotificationToken?

  open var sectionForObjects: Int = 0

  weak open var collectionView: UICollectionView?

  open var hasCollectionViewReloadedData: Bool = false

  open override func objectsDidChange(_ previousObjects: Collection?) {
    if let objects {
      if objects.realm != nil {
        token = objects.observe { [weak self] change in
          guard let self else { return }
          switch change {
          case .initial:
            break

          case .update(_, let deletions, let insertions, _):
            for index in deletions.reversed() {
              viewModels.remove(at: index)
            }
            for index in insertions {
              viewModels.insert(.uninitialized, at: index)
            }
            viewModelsSubject.send(viewModels)
            if let collectionView {
              if hasCollectionViewReloadedData {
                if !deletions.isEmpty || !insertions.isEmpty {
                  let sectionForObjects = sectionForObjects
                  let itemAdjustment = itemAdjustment
                  collectionView.performBatchUpdates({
                    collectionView.deleteItems(at: deletions.map { IndexPath(item: itemAdjustment + $0, section: sectionForObjects) })
                    collectionView.insertItems(at: insertions.map { IndexPath(item: itemAdjustment + $0, section: sectionForObjects) })
                  }, completion: { _ in
                    if let emptyView = collectionView.emptyView {
                      emptyView.reload()
                    } else if let owningViewController = collectionView.owningViewController, owningViewController.isViewLoaded {
                      for subview in owningViewController.view.subviews {
                        if let emptyView = subview as? EmptyView {
                          emptyView.reload()
                          return
                        }
                      }
                    }
                  })
                }
              } else {
                collectionView.reloadData()
                hasCollectionViewReloadedData = true
              }
            } else {
              hasCollectionViewReloadedData = false
            }
          }
        }
      } else {
        token = nil
      }
      viewModels = .init(repeating: .uninitialized, count: objects.count)
      viewModelsSubject.send(viewModels)
      collectionView?.reloadData()
      hasCollectionViewReloadedData = collectionView != nil
    } else {
      token = nil
      viewModels.removeAll()
      viewModelsSubject.send(viewModels)
      collectionView?.reloadData()
      hasCollectionViewReloadedData = collectionView != nil
    }
  }
}
