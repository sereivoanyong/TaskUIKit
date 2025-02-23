//
//  SectionedViewModelsDataSource.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/12/25.
//

import UIKit
import Combine

open class SectionedViewModelsDataSource<SectionedItems: SectionedCollection, ViewModel>: NSObject, StaticDataSource, UICollectionViewDataSource where SectionedItems.SectionElement: Identifiable {

  public typealias SectionIdentifier = SectionedItems.SectionIdentifier

  public typealias ItemIdentifier = SectionedItems.SectionElement.ID

  public typealias Item = SectionedItems.SectionElement

  public typealias CellProvider = (UICollectionView, IndexPath, ViewModel) -> UICollectionViewCell

  open var sectionedItems: SectionedItems! {
    didSet {
      sectionedItemsDidChange(oldValue)
    }
  }

  open var viewModels: [[Lazy<ViewModel>]]

  public let viewModelsSubject: CurrentValueSubject<[[Lazy<ViewModel>]], Never>

  open var viewModelProvider: (Item) -> ViewModel

  open var sectionAdjustment: Int = 0

  open var itemAdjustment: Int = 0

  weak public private(set) var collectionView: UICollectionView?

  public let cellProvider: CellProvider!

  public init(sectionedItems: SectionedItems? = nil, viewModelProvider: @escaping (Item) -> ViewModel, collectionView: UICollectionView? = nil, cellProvider: CellProvider? = nil) {
    self.sectionedItems = sectionedItems
    self.viewModels = sectionedItems.map { $0.map { [Lazy<ViewModel>](repeating: .uninitialized, count: $0.count) } } ?? []
    self.viewModelsSubject = .init(viewModels)
    self.viewModelProvider = viewModelProvider
    self.collectionView = collectionView
    self.cellProvider = cellProvider
    super.init()

    if let collectionView {
      collectionView.dataSource = self
      collectionView.reloadData()
    }
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
    return viewModels[indexPath.section - sectionAdjustment][indexPath.item - itemAdjustment].value(or: makeViewModel(for: item(for: indexPath)))
  }

  open func sectionedItemsDidChange(_ previousSectionedItems: SectionedItems?) {
    if let sectionedItems {
      viewModels = sectionedItems.map { [Lazy<ViewModel>](repeating: .uninitialized, count: $0.count) }
    } else {
      viewModels.removeAll()
    }
    viewModelsSubject.send(viewModels)
    collectionView?.reloadData()
  }

  // MARK: Accessor

  open func sectionIdentifier(for index: Int) -> SectionIdentifier? {
    return sectionedItems[index - sectionAdjustment].id
  }

  open func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier? {
    return item(for: indexPath).id
  }

  open func item(for indexPath: IndexPath) -> Item {
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
    let cellViewModel = self[indexPath]
    return cellProvider(collectionView, indexPath, cellViewModel)
  }
}
