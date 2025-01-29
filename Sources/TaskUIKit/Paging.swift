//
//  Paging.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 9/27/21.
//

import Foundation

public protocol Paging {

  func hasNextPage() -> Bool
}

public protocol PageBasedPaging: Paging {

  var page: Int { get }
}

extension Optional where Wrapped == Paging {

  public var nextOrFirstPage: Int {
    switch self {
    case .none:
      return 1
    case .some(let paging):
      if let paging = paging as? PageBasedPaging {
        return paging.page + 1
      }
      assertionFailure("Attemp to access `nextOrFirstPage` on non-`PageBasedPaging`")
      return 1
    }
  }
}
