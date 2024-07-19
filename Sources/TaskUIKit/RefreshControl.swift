//
//  RefreshControl.swift
//
//  Created by Sereivoan Yong on 7/19/24.
//

#if !targetEnvironment(macCatalyst)
import UIKit

public protocol RefreshControl: UIView {

  func beginRefreshing()
  func endRefreshing()
}

public protocol FiniteRefreshControl: RefreshControl {

  func endRefreshingWithNoMoreData()
}

extension UIRefreshControl: RefreshControl { }
#endif

#if !targetEnvironment(macCatalyst) && canImport(MJRefresh)
import MJRefresh

extension MJRefreshHeader: RefreshControl { }

extension MJRefreshFooter: FiniteRefreshControl { }
#endif
