//
//  CachingViewModels.swift
//  TaskRealmUIKit
//
//  Created by Sereivoan Yong on 1/8/25.
//

import Foundation
import Combine

open class CachingViewModels<Collection: Swift.Collection, ViewModel> where Collection.Index == Int {

  public typealias Object = Collection.Element

  open var objects: Collection? {
    didSet {
      objectsDidChange(oldValue)
    }
  }

  open var viewModels: [Lazy<ViewModel>] = []

  public let viewModelsSubject: CurrentValueSubject<[Lazy<ViewModel>], Never>

  open var viewModelProvider: (Object) -> ViewModel

  open var itemAdjustment: Int = 0

  public init(objects: Collection? = nil, viewModelProvider: @escaping (Object) -> ViewModel) {
    self.objects = objects
    self.viewModelProvider = viewModelProvider

    if let objects {
      viewModels = .init(repeating: .uninitialized, count: objects.count)
    }
    self.viewModelsSubject = .init(viewModels)
  }

  open var numberOfItems: Int {
    return itemAdjustment + viewModels.count
  }

  open func makeViewModel(for object: Object) -> ViewModel {
    return viewModelProvider(object)
  }

  open func loadViewModels() -> [ViewModel] {
    var loadedViewModels: [ViewModel] = []
    if let objects {
      assert(viewModels.count == objects.count)
      for (index, object) in objects.enumerated() {
        let loadedViewModel = viewModels[index].value(or: makeViewModel(for: object))
        loadedViewModels.append(loadedViewModel)
      }
    }
    return loadedViewModels
  }

  open subscript(index: Int) -> ViewModel {
    return viewModels[index - itemAdjustment].value(or: makeViewModel(for: objects![index - itemAdjustment]))
  }

  open func objectsDidChange(_ previousObjects: Collection?) {
    if let objects {
      viewModels = .init(repeating: .uninitialized, count: objects.count)
    } else {
      viewModels.removeAll()
    }
    viewModelsSubject.send(viewModels)
  }
}
