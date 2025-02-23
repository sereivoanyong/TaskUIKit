//
//  StaticDataSource.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/12/25.
//

import UIKit

public protocol StaticIdentifiableDataSource<SectionIdentifier, ItemIdentifier>: NSObject, UICollectionViewDataSource {

  associatedtype SectionIdentifier

  associatedtype ItemIdentifier

  func sectionIdentifier(for index: Int) -> SectionIdentifier?

  func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier?
}

public protocol StaticDataSource<SectionIdentifier, Item>: StaticIdentifiableDataSource where Item.ID == ItemIdentifier {

  associatedtype Item: Identifiable

  func item(for indexPath: IndexPath) -> Item
}

extension StaticDataSource {

  public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier? {
    return item(for: indexPath).id
  }
}

import UIKit

@available(iOS 15.0, *)
extension UICollectionViewDiffableDataSource: StaticIdentifiableDataSource {
}
