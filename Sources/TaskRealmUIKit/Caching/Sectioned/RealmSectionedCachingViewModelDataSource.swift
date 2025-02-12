//
//  RealmSectionedCachingViewModelDataSource.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/12/25.
//

import UIKit
import RealmSwift

open class RealmSectionedCachingViewModelDataSource<Key: _Persistable & Hashable, Object: ObjectBase & RealmCollectionValue & Identifiable, ViewModel>: SectionedCachingViewModelDataSource<SectionedResults<Key, Object>, ViewModel> {

  private var token: NotificationToken?

  open override func sectionedItemsDidChange(_ previousSectionedItems: SectionedResults<Key, Object>?) {
    if let sectionedItems {
      if sectionedItems.realm != nil {
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
          }
        }
      } else {
        token = nil
      }
      viewModels = sectionedItems.map { [Lazy<ViewModel>](repeating: .uninitialized, count: $0.count) }
      viewModelsSubject.send(viewModels)
    } else {
      token = nil
      viewModels = sectionedItems.map { [Lazy<ViewModel>](repeating: .uninitialized, count: $0.count) }
      viewModelsSubject.send(viewModels)
    }
  }
}
