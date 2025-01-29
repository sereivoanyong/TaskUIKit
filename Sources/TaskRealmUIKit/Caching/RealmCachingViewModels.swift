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

public typealias AnyRealmCachingViewModels<Object: RealmSwift.Object & Identifiable, ViewModel> = RealmCachingViewModels<AnyRealmCollection<Object>, ViewModel>

open class RealmCachingViewModels<Collection: RealmCollection, ViewModel>: CachingViewModels<Collection, ViewModel> where Collection.Element: RealmSwift.Object & Identifiable, Collection.Index == Int {

  private var token: NotificationToken?

  open var sectionForObjects: Int = 0

  weak open var collectionView: UICollectionView?

  open var hasCollectionViewReloadedData: Bool = false

  open private(set) var ids: [Object.ID] = []

  open override func objectsDidChange(_ previousObjects: Collection?) {
    if let objects {
      if objects.realm != nil {
        token = objects.observe { [weak self] change in
          guard let self else { return }
          switch change {
          case .initial:
            break

          case .update(let objects, let deletions, let insertions, _):
            for index in deletions {
              ids.remove(at: index)
              viewModels.remove(at: index)
            }
            for index in insertions {
              let object = objects[index]
              ids.insert(object.id, at: index)
              viewModels.insert(viewModelProvider(object), at: index)
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

          case .error:
            break
          }
        }
        ids = objects.map(\.id)
        viewModels = objects.map(viewModelProvider)
        viewModelsSubject.send(viewModels)
        collectionView?.reloadData()
        hasCollectionViewReloadedData = collectionView != nil
      } else {
        token = nil
        ids = objects.map(\.id)
        viewModels = objects.map(viewModelProvider)
        viewModelsSubject.send(viewModels)
        collectionView?.reloadData()
        hasCollectionViewReloadedData = collectionView != nil
      }
    } else {
      token = nil
      ids.removeAll()
      viewModels.removeAll()
      viewModelsSubject.send(viewModels)
      collectionView?.reloadData()
      hasCollectionViewReloadedData = collectionView != nil
    }
  }
}

//class CachingSectionedViewModels<Key: _Persistable & Hashable, Object: RealmCollectionValue & Identifiable, ViewModel> {
//
//  var objects: RealmMultiDimensionCollection<Key, Object>! {
//    didSet {
//      objectsDidChange(oldValue)
//    }
//  }
//
//  var viewModels: [ViewModel] = []
//
//  let viewModelsSubject: CurrentValueSubject<[ViewModel], Never>
//
//  let viewModelProvider: (Object) -> ViewModel
//
//  init(objects: RealmMultiDimensionCollection<Key, Object>?, viewModelProvider: @escaping (Object) -> ViewModel) {
//    self.objects = objects
//    self.viewModelProvider = viewModelProvider
//
//    if let objects {
//      viewModels = objects.map(viewModelProvider)
//    }
//    self.viewModelsSubject = .init(viewModels)
//  }
//
//  var numberOfSections: Int {
//    return objects.numberOfSections
//  }
//
//  func numberOfObjects(in section: Int) -> Int {
//    return objects.numberOfObjects(in: section)
//  }
//
//  func object(at indexPath: IndexPath) -> Object {
//    RealmSwift.Object().observe { ObjectChange<RLMObjectBase> in
//      <#code#>
//    }
//    return objects[indexPath]
//  }
//
//  func makeViewModel(for object: Object) -> ViewModel {
//    return viewModelProvider(object)
//  }
//
//  subscript(index: Int) -> ViewModel {
//    return viewModels[index]
//  }
//
//  func objectsDidChange(_ previousObjects: RealmMultiDimensionCollection<Key, Object>?) {
//    if let objects {
//      viewModels = objects.map(viewModelProvider)
//      //      let oldIds = Set(viewModels.keys)
//      //      for objectToCreate in objects where !oldIds.contains(objectToCreate.id) {
//      //        viewModels[objectToCreate.id] = viewModelProvider(objectToCreate)
//      //      }
//      //      for idToDelete in oldIds.subtracting(objects.map(\.id)) {
//      //        viewModels[idToDelete] = nil
//      //      }
//    } else {
//      viewModels.removeAll()
//    }
//    viewModelsSubject.send(viewModels)
//  }
//}
//
//enum RealmMultiDimensionCollection<Key: _Persistable & Hashable, Object: RealmCollectionValue> {
//
//  case one(AnyRealmCollection<Object>)
//  case two(SectionedResults<Key, Object>)
//
//  var numberOfSections: Int {
//    switch self {
//    case .one:
//      return 1
//    case .two(let two):
//      return two.count
//    }
//  }
//
//  func numberOfObjects(in section: Int) -> Int {
//    switch self {
//    case .one(let one):
//      return one.count
//    case .two(let two):
//      return two[section].count
//    }
//  }
//
//  var realm: Realm? {
//    switch self {
//    case .one(let one):
//      return one.realm
//    case .two(let two):
//      return two.realm
//    }
//  }
//
////  func object(item: Int, section: Int)
//}
