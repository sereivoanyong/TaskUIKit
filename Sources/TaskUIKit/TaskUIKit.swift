//
//  TaskUIKit.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 11/24/23.
//

@_exported import UIKit
@_exported import EmptyUIKit
@_exported import Combine
import MJRefresh

final public class Configuration {

  public static let shared = Configuration()

#if !targetEnvironment(macCatalyst)
  public var headerRefreshControlProvider: ((UIScrollView, @escaping() -> Void) -> RefreshControl)?
  public var footerRefreshControlProvider: ((UIScrollView, @escaping() -> Void) -> FiniteRefreshControl)?
#endif

  public var emptyViewImageForEmpty: UIImage?
  public var emptyViewImageForError: UIImage?
}

public enum TaskResult<Contents> {

  case success(Contents, Paging? = nil, TaskUserInfo? = nil)
  case failure(Error)
}

open class TaskUserInfo {

  public init() {
  }
}

extension URLSessionTask: @retroactive Cancellable { }
