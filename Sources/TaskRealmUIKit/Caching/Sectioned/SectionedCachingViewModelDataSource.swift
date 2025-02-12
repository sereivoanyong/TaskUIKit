//
//  SectionedCachingViewModelDataSource.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/12/25.
//

import UIKit
import Combine

open class SectionedCachingViewModelDataSource<SectionedItems: SectionedCollection, ViewModel>: NSObject, StaticDataSource, UICollectionViewDataSource where SectionedItems.SectionElement: Identifiable {

  public typealias SectionIdentifier = SectionedItems.SectionIdentifier

  public typealias ItemIdentifier = SectionedItems.SectionElement.ID

  public typealias Item = SectionedItems.SectionElement

  public typealias CellProvider = (UICollectionView, IndexPath, Item) -> UICollectionViewCell

  open var sectionedItems: SectionedItems! {
    didSet {
      sectionedItemsDidChange(oldValue)
    }
  }

  open var viewModels: [[Lazy<ViewModel>]] = []

  public let viewModelsSubject: CurrentValueSubject<[[Lazy<ViewModel>]], Never>

  open var viewModelProvider: (Item) -> ViewModel

  open var sectionAdjustment: Int = 0

  open var itemAdjustment: Int = 0

  weak open var collectionView: UICollectionView? {
    didSet {
      collectionView?.dataSource = self
    }
  }

  open var cellProvider: CellProvider?

  public init(sectionedItems: SectionedItems? = nil, viewModelProvider: @escaping (Item) -> ViewModel) {
    self.sectionedItems = sectionedItems
    self.viewModelProvider = viewModelProvider

    if let sectionedItems {
      viewModels = sectionedItems.map { [Lazy<ViewModel>](repeating: .uninitialized, count: $0.count) }
    }
    self.viewModelsSubject = .init(viewModels)
  }

  open func makeViewModel(for item: Item) -> ViewModel {
    return viewModelProvider(item)
  }

  open func loadViewModels() -> [[ViewModel]] {
    var loadedSectionedViewModels: [[ViewModel]] = []
    if let sectionedItems {
      assert(viewModels.count == sectionedItems.count)
      for (sectionIndex, items) in sectionedItems.enumerated() {
        var loadedViewModels: [ViewModel] = []
        assert(viewModels[sectionIndex].count == items.count)
        for (itemIndex, item) in items.enumerated() {
          let loadedViewModel = viewModels[sectionIndex][itemIndex].value(or: makeViewModel(for: item))
          loadedViewModels.append(loadedViewModel)
        }
        loadedSectionedViewModels.append(loadedViewModels)
      }
    }
    return loadedSectionedViewModels
  }

  open subscript(indexPath: IndexPath) -> ViewModel {
    return viewModels[indexPath.section - sectionAdjustment][indexPath.item - itemAdjustment].value(or: makeViewModel(for: item(for: indexPath)!))
  }

  open func sectionedItemsDidChange(_ previousSectionedItems: SectionedItems?) {
    if let sectionedItems {
      viewModels = sectionedItems.map { [Lazy<ViewModel>](repeating: .uninitialized, count: $0.count) }
    } else {
      viewModels.removeAll()
    }
    viewModelsSubject.send(viewModels)
  }

  // MARK: Accessor

  open func sectionIdentifier(for index: Int) -> SectionIdentifier? {
    return sectionedItems[index - sectionAdjustment].id
  }

  open func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier? {
    return sectionedItems[indexPath.section - sectionAdjustment][indexPath.item - itemAdjustment].id
  }

  open func item(for indexPath: IndexPath) -> Item? {
    return sectionedItems[indexPath.section - sectionAdjustment][indexPath.item - itemAdjustment]
  }

  // MARK: UICollectionViewDataSource

  open func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sectionAdjustment + sectionedItems.count
  }

  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return itemAdjustment + sectionedItems[section].count
  }

  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let item = item(for: indexPath)!
    return cellProvider!(collectionView, indexPath, item)
  }
}
