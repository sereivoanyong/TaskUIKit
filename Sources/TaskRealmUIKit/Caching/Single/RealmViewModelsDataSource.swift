//
//  RealmViewModelsDataSource.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/24/25.
//

import UIKit
import EmptyUIKit
import RealmSwift

open class RealmViewModelsDataSource<Object: ObjectBase & RealmCollectionValue & Identifiable, ViewModel>: ViewModelsDataSource<AnyRealmCollection<Object>, ViewModel> {

  private var token: NotificationToken?

  public override init(
    items: AnyRealmCollection<Object>? = nil,
    viewModelProvider: @escaping (Item) -> ViewModel,
    collectionView: UICollectionView? = nil,
    cellProvider: CellProvider? = nil
  ) {
    super.init(items: items, viewModelProvider: viewModelProvider, collectionView: collectionView, cellProvider: cellProvider)
    if let items {
      observeIfNeeded(items)
    }
  }

  open override func itemsDidChange(_ previousItems: AnyRealmCollection<Object>?) {
    token = nil
    if let items {
      viewModels = .init(repeating: .uninitialized, count: items.count)
      viewModelsSubject.send(viewModels)
      collectionView?.reloadData()
      observeIfNeeded(items)
    } else {
      viewModels.removeAll()
      viewModelsSubject.send(viewModels)
      collectionView?.reloadData()
    }
  }

  private func observeIfNeeded(_ items: AnyRealmCollection<Object>) {
    guard items.realm != nil else {
      token = nil
      return
    }
    token = items.observe { [weak self] change in
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
        if let collectionView, (!deletions.isEmpty || !insertions.isEmpty) {
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
      }
    }
  }
}
