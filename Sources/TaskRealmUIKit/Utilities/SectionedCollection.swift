//
//  NewCachingViewModel.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/12/25.
//

import Foundation

public protocol IndexCollection<Element, Index>: Collection {
}

public protocol SectionedCollection<SectionIdentifier, SectionElement>: Collection where Index == Int, Element: IndexCollection<SectionElement, Int> & Identifiable, Element.ID == SectionIdentifier {

  associatedtype SectionIdentifier

  associatedtype SectionElement
}

extension Array: IndexCollection {
}

import RealmSwift

extension SectionedResults: SectionedCollection {
}

extension ResultsSection: IndexCollection {
}

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 15.0, *)
extension SectionedFetchResults: SectionedCollection {
}

@available(iOS 15.0, *)
extension SectionedFetchResults.Section: IndexCollection {
}
#endif
