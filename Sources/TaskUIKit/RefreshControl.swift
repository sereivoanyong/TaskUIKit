//
//  RefreshControl.swift
//  TaskUIKit
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

  func endRefreshingAndHide()
}

extension UIRefreshControl: RefreshControl {
}
#endif

#if !targetEnvironment(macCatalyst) && canImport(MJRefresh)
import MJRefresh

extension MJRefreshHeader: RefreshControl {
}

extension MJRefreshFooter: FiniteRefreshControl {

  public func endRefreshingAndHide() {
    isHidden = true
  }
}
#endif
