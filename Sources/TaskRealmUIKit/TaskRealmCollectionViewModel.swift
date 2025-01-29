//
//  TaskRealmCollectionViewModel.swift
//  TaskRealmUIKit
//
//  Created by Sereivoan Yong on 1/11/25.
//

import Foundation
import SwiftKit
import RealmSwift

public protocol TaskRealmCollectionViewModel: AnyObject {

  associatedtype CellObject: RealmSwift.Object & Identifiable
  associatedtype CellObjectViewModel: ObjectViewModel<CellObject>

  var cellViewModels: RealmCachingViewModels<AnyRealmCollection<CellObject>, CellObjectViewModel> { get set }
}
