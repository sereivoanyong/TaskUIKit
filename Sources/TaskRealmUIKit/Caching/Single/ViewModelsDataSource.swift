//
//  ViewModelsDataSource.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/24/25.
//

import Foundation
import Combine

open class ViewModelsDataSource<Items: Collection, ViewModel>: NSObject, StaticDataSource where Items.Element: Identifiable, Items.Index == Int {

  public typealias SectionIdentifier = Int

  public typealias ItemIdentifier = Items.Element.ID

  public typealias Item = Items.Element

  public typealias CellProvider = (UICollectionView, IndexPath, ViewModel) -> UICollectionViewCell

  open var items: Items! {
    didSet {
      itemsDidChange(oldValue)
    }
  }

  open var viewModels: [Lazy<ViewModel>]

  public let viewModelsSubject: CurrentValueSubject<[Lazy<ViewModel>], Never>

  open var viewModelProvider: (Item) -> ViewModel

  open var sectionForObjects: Int = 0

  open var itemAdjustment: Int = 0

  weak public private(set) var collectionView: UICollectionView?

  public let cellProvider: CellProvider!

  public init(
    items: Items? = nil,
    viewModelProvider: @escaping (Item) -> ViewModel,
    collectionView: UICollectionView? = nil,
    cellProvider: CellProvider? = nil
  ) {
    self.items = items
    self.viewModels = .init(repeating: .uninitialized, count: items?.count ?? 0)
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

  open func loadViewModels() -> [ViewModel] {
    var loadedViewModels: [ViewModel] = []
    if let items {
      assert(viewModels.count == items.count)
      for (index, item) in items.enumerated() {
        let loadedViewModel = viewModels[index].value(or: makeViewModel(for: item))
        loadedViewModels.append(loadedViewModel)
      }
    }
    return loadedViewModels
  }

  open subscript(index: Int) -> ViewModel {
    return viewModels[index - itemAdjustment].value(or: makeViewModel(for: item(for: index)))
  }

  open func itemsDidChange(_ previousItems: Items?) {
    if let items {
      viewModels = .init(repeating: .uninitialized, count: items.count)
    } else {
      viewModels.removeAll()
    }
    viewModelsSubject.send(viewModels)
    collectionView?.reloadData()
  }

  // MARK: Accessor

  open func sectionIdentifier(for index: Int) -> Int? {
    return 0
  }

  private func item(for index: Int) -> Item {
    return items[index - itemAdjustment]
  }

  open func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier? {
    return item(for: indexPath).id
  }

  open func item(for indexPath: IndexPath) -> Item {
    return item(for: indexPath.item)
  }

  // MARK: UICollectionViewDataSource

  open func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items?.count ?? 0
  }

  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cellViewModel = self[indexPath.item]
    return cellProvider(collectionView, indexPath, cellViewModel)
  }
}
