//
//  StaticDataSource.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/12/25.
//

import Foundation

public protocol StaticDataSource<SectionIdentifier, ItemIdentifier>: NSObject {

  associatedtype SectionIdentifier

  associatedtype ItemIdentifier

  func sectionIdentifier(for index: Int) -> SectionIdentifier?

  func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier?
}

import UIKit

@available(iOS 15.0, *)
extension UICollectionViewDiffableDataSource: StaticDataSource {
}
