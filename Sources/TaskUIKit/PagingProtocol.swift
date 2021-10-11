//
//  PagingProtocol.swift
//
//  Created by Sereivoan Yong on 9/27/21.
//

import Foundation

public protocol PagingProtocol {

  var page: Int { get }

  func hasNextPage() -> Bool
}
