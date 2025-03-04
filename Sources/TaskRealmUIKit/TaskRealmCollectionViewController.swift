//
//  TaskRealmCollectionViewController.swift
//  TaskRealmUIKit
//
//  Created by Sereivoan Yong on 1/11/25.
//

import UIKitUtilities
import TaskUIKit
import RealmSwift

/// Every object is managed but the collection can either be managed or unmanaged.
/// If response objects are for insertion only, use `List`.
/// If they are also for deletion, use `Results` as it is observed. Make sure to override `filter(_:` and `sort(_:)` so that the response objects query matches the `Results`
open class TaskRealmCollectionViewController<ViewModel: TaskRealmCollectionViewModel>: TaskViewController<AnyRealmCollection<ViewModel.CellObject>> where ViewModel.CellObject: RealmSwift.Object & Identifiable {

  public typealias Object = ViewModel.CellObject

  /// Must be initialized in initializer.
  /// `viewModel.cellViewModels.objects` is managed by task view controller.
  /// `filter(_:)`, `sort(_:)` will be called accordingly.
  open var viewModel: ViewModel

  open var realm: Realm {
    fatalError()
  }

  open var contentsStore: TaskRealmCollectionStore {
    return .list
  }

  open private(set) var fetchedAt: Date = Date() {
    didSet {
      print("Fetching reset for \(type(of: self)) to \(fetchedAt) (from \(oldValue))")
    }
  }

  open var fetchedAtKeyPath: ReferenceWritableKeyPath<Object, Date?>? {
    return nil
  }

  /// Optional. For realm-managed `contents` only. This must match the response query.
  open func filter(_ predicates: inout [NSPredicate]) {
  }

  /// Optional. For realm-managed `contents` only. This must match the response query.
  open func sort(_ descriptors: inout [NSSortDescriptor]) {
  }

  open override func loadContents(for source: Source) -> AnyRealmCollection<Object>? {
    switch contentsStore {
    case .list:
      return nil
    case .results:
      var results = realm.objects(Object.self)
      if source == .response, let fetchedAtKeyPath {
        results = results.filter("\(_name(for: fetchedAtKeyPath)) >= %@", fetchedAt)
      }

      do { // Filter
        var predicates: [NSPredicate] = []
        filter(&predicates)
        for predicate in predicates {
          results = results.filter(predicate)
        }
      }

      do { // Sort
        var descriptors: [NSSortDescriptor] = []
        sort(&descriptors)
        results = results.sorted(by: descriptors.map { RealmSwift.SortDescriptor(keyPath: $0.key!, ascending: $0.ascending) })
      }
      return .init(results)
    }
  }

  public init(viewModel: ViewModel, nibName: String? = nil, bundle: Bundle? = nil) {
    self.viewModel = viewModel
    super.init(nibName: nibName, bundle: bundle)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View Lifecycle

  open override var contents: AnyRealmCollection<Object>? {
    return viewModel.cellViewModels.objects
  }

  open override func resetData() {
    fetchedAt = Date()
    viewModel.cellViewModels.objects = nil
  }

  /// `completion` must be called at the end (usually) or deferred until data is applied. `completion` isn't called if self dealloc
  open override func applyData(_ contents: SourcedContents, completion: @escaping () -> Void) {
    switch contents {
    case .response(let newObjects, let isInitial, let userInfo):
      if isInitial {
        resetData()
      }
      process(newObjects, isInitial: isInitial, userInfo: userInfo, in: realm, completion: completion)
    case .cache(let newObjects):
      viewModel.cellViewModels.objects = newObjects
      completion()
    }
  }

  private func process(_ newObjects: AnyRealmCollection<Object>, isInitial: Bool, userInfo: TaskUserInfo?, in realm: Realm, completion: @escaping () -> Void) {
    realm.beginWrite()
    let newObjects = write(newObjects.array, userInfo: userInfo, in: realm)
    realm.commitAsyncWrite { [weak self] error in
      if let error {
        printIfDEBUG(error)
      }
      if let self {
        switch contentsStore {
        case .list:
          let list = List<Object>()
          if !isInitial, let objects = viewModel.cellViewModels.objects {
            list.append(objectsIn: objects)
          }
          list.append(objectsIn: newObjects)
          viewModel.cellViewModels.objects = .init(list)
        case .results:
          viewModel.cellViewModels.objects = loadContents(for: .response)
        }
        completion()
      }
    }
  }

  open func write(_ newObjects: [Object], userInfo: TaskUserInfo?, in realm: Realm) -> [Object] {
    var newObjects = newObjects
    for (index, var newObject) in newObjects.enumerated() {
      Configuration.shared.willWriteObjectHandler?(newObject, userInfo, realm)
      newObject = write(newObject, at: index, to: realm)
      if let fetchedAtKeyPath {
        newObject[keyPath: fetchedAtKeyPath] = fetchedAt
      }
      newObjects[index] = newObject
    }
    return newObjects
  }

  open func write(_ newObject: Object, at index: Int, to realm: Realm) -> Object {
    realm.add(newObject, update: .modified)
    return newObject
  }

  open var sectionForObjects: Int {
    return viewModel.cellViewModels.sectionForObjects
  }

  open func object(at indexPath: IndexPath) -> Object {
    return viewModel.cellViewModels[indexPath.item].object
  }
}
