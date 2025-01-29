//
//  CachingViewModels.swift
//  TaskRealmUIKit
//
//  Created by Sereivoan Yong on 1/8/25.
//

import Foundation
import Combine

open class CachingViewModels<Objects: Collection, ViewModel> where Objects.Element: Identifiable, Objects.Index == Int {

  public typealias Object = Objects.Element

  open var objects: Objects? {
    didSet {
      objectsDidChange(oldValue)
    }
  }

  open var viewModels: [ViewModel] = []

  public let viewModelsSubject: CurrentValueSubject<[ViewModel], Never>

  open var viewModelProvider: (Object) -> ViewModel

  open var itemAdjustment: Int = 0

  public init(objects: Objects? = nil, viewModelProvider: @escaping (Object) -> ViewModel) {
    self.objects = objects
    self.viewModelProvider = viewModelProvider

    if let objects {
      viewModels = objects.map(viewModelProvider)
    }
    self.viewModelsSubject = .init(viewModels)
  }

  open var numberOfItems: Int {
    return itemAdjustment + viewModels.count
  }

  open func makeViewModel(for object: Object) -> ViewModel {
    return viewModelProvider(object)
  }

  open subscript(index: Int) -> ViewModel {
    return viewModels[index - itemAdjustment]
  }

  open func objectsDidChange(_ previousObjects: Objects?) {
    if let objects {
      viewModels = objects.map(viewModelProvider)
//      let oldIds = Set(viewModels.keys)
//      for objectToCreate in objects where !oldIds.contains(objectToCreate.id) {
//        viewModels[objectToCreate.id] = viewModelProvider(objectToCreate)
//      }
//      for idToDelete in oldIds.subtracting(objects.map(\.id)) {
//        viewModels[idToDelete] = nil
//      }
    } else {
      viewModels.removeAll()
    }
    viewModelsSubject.send(viewModels)
  }
}
