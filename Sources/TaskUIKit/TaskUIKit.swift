//
//  TaskUIKit.swift
//
//  Created by Sereivoan Yong on 11/24/23.
//

@_exported import Combine
@_exported import EmptyUIKit
import UIKit
import MJRefresh

public enum TaskUIKitConfiguration {

#if !targetEnvironment(macCatalyst)
  public static var headerRefreshControlProvider: ((UIScrollView, @escaping() -> Void) -> RefreshControl)?
  public static var footerRefreshControlProvider: ((UIScrollView, @escaping() -> Void) -> FiniteRefreshControl)?
#endif

  public static var emptyViewImageForEmpty: UIImage?
  public static var emptyViewImageForError: UIImage?
}

extension URLSessionTask: Cancellable { }
