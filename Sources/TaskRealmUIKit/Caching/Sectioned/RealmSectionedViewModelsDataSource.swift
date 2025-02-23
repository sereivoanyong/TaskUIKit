//
//  RealmSectionedViewModelsDataSource.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/12/25.
//

import UIKit
import EmptyUIKit
import RealmSwift

open class RealmSectionedViewModelsDataSource<Key: _Persistable & Hashable, Object: ObjectBase & RealmCollectionValue & Identifiable, ViewModel>: SectionedViewModelsDataSource<SectionedResults<Key, Object>, ViewModel> {

  private var token: NotificationToken?

  public override init(
    sectionedItems: SectionedResults<Key, Object>? = nil,
    viewModelProvider: @escaping (Item) -> ViewModel,
    collectionView: UICollectionView? = nil,
    cellProvider: CellProvider? = nil
  ) {
    super.init(sectionedItems: sectionedItems, viewModelProvider: viewModelProvider, collectionView: collectionView, cellProvider: cellProvider)
    if let sectionedItems {
      observeIfNeeded(sectionedItems)
    }
  }

  open override func sectionedItemsDidChange(_ previousSectionedItems: SectionedResults<Key, Object>?) {
    token = nil
    if let sectionedItems {
      viewModels = sectionedItems.map { [Lazy<ViewModel>](repeating: .uninitialized, count: $0.count) }
      viewModelsSubject.send(viewModels)
      collectionView?.reloadData()
      observeIfNeeded(sectionedItems)
    } else {
      viewModels.removeAll()
      viewModelsSubject.send(viewModels)
      collectionView?.reloadData()
    }
  }

  private func observeIfNeeded(_ sectionedItems: SectionedResults<Key, Object>) {
    guard sectionedItems.realm != nil else {
      token = nil
      return
    }
    token = sectionedItems.observe { [unowned self] change in
      switch change {
      case .initial:
        break

      case .update(_, let deletions, let insertions, _, let sectionsToInsert, let sectionsToDelete):
        for deletion in deletions {
          viewModels[deletion.section].remove(at: deletion.item)
        }
        for insertion in insertions {
          viewModels[insertion.section].insert(.uninitialized, at: insertion.item)
        }
        for sectionToInsert in sectionsToInsert {
          viewModels.insert([], at: sectionToInsert)
        }
        for sectionToDelete in sectionsToDelete {
          viewModels.remove(at: sectionToDelete)
        }
        viewModelsSubject.send(viewModels)
        if let collectionView, (!deletions.isEmpty || !insertions.isEmpty || !sectionsToInsert.isEmpty || !sectionsToDelete.isEmpty) {
          collectionView.performBatchUpdates({
            collectionView.deleteItems(at: deletions)
            collectionView.insertItems(at: insertions)
            collectionView.insertSections(sectionsToInsert)
            collectionView.deleteSections(sectionsToDelete)
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
