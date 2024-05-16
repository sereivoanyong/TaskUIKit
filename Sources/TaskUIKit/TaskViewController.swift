//
//  TaskViewController.swift
//
//  Created by Sereivoan Yong on 2/4/20.
//

import UIKitUtilities
import EmptyUIKit
import Combine
import MJRefresh

/// Subclass must implement these functions:
/// `startTasks(page:completion:)`
/// `applyData(_:page:)`
open class TaskViewController<Contents>: UIViewController, EmptyViewStateProviding, EmptyViewDataSource {

  open private(set) var isFirstViewAppear: Bool = true

  private func isNilOrEmpty(_ contents: Contents?) -> Bool {
    if let contents {
      if let contents = contents as? any Collection, contents.isEmpty {
        return true
      }
      return false
    }
    return true
  }

  open private(set) var cancellables: Set<AnyCancellable> = [] {
    willSet {
      cancelAllTasks()
    }
  }

  open private(set) var currentPaging: PagingProtocol?
  open private(set) var currentError: Error?

  open var contents: Contents? {
    fatalError()
  }

  // This is used when first page failed
  open var cachedContents: Contents? {
    return nil
  }

  open var initialError: Error? {
    return nil
  }

  open private(set) var isLoading: Bool = false

  /// If `contents` isn't nil nor empty, this property is ignored. Setting this property after `viewIsAppearing(_:)` has no effect.
  open var loadsTaskOnViewAppear: Bool = true

  /// Returns the scroll view for pull-to-refresh
  open var refreshingScrollView: UIScrollView? {
    return nil
  }

  open var automaticallyConfiguresHeaderRefreshControl: Bool = true
  open var automaticallyConfiguresFooterRefreshControl: Bool = true

  open private(set) var viewController: UIViewController?

  open private(set) var emptyViewIfLoaded: EmptyView?
  lazy open private(set) var emptyView: EmptyView = {
    let emptyView = EmptyView()
    emptyView.stateProvider = self
    emptyView.dataSource = self
    emptyView.translatesAutoresizingMaskIntoConstraints = false
    emptyViewIfLoaded = emptyView
    if let loadingIndicatorView = loadingIndicatorViewIfLoaded {
      view.insertSubview(emptyView, belowSubview: loadingIndicatorView)
    } else {
      view.addSubview(emptyView)
    }

    NSLayoutConstraint.activate([
      emptyView.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
      emptyView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
      emptyView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor),
    ])
    return emptyView
  }()

  open private(set) var loadingIndicatorViewIfLoaded: UIActivityIndicatorView?
  lazy open private(set) var loadingIndicatorView: UIActivityIndicatorView = {
    let indicatorView = UIActivityIndicatorView(style: .medium)
    loadingIndicatorViewIfLoaded = indicatorView
    view.addSubview(indicatorView)

    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      indicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      indicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
    ])
    return indicatorView
  }()

  open private(set) var headerRefreshControlIfLoaded: RefreshControl?
  open private(set) var footerRefreshControlIfLoaded: RefreshControl?

  // MARK: Init / Deinit

  deinit {
    cancelAllTasks()
  }

  // MARK: View Lifecycle

  open override func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)

    if isFirstViewAppear {
      isFirstViewAppear = false
      if initialError == nil {
        if loadsTaskOnViewAppear {
          // We do not need to reset as this is an initial load.
          reloadTasks(reset: false, animated: true)
        }
      } else {
        emptyView.reload()
      }
    }
  }

  // MARK: Networking

  @objc private func reloadTasks(_ sender: UIButton) {
    reloadTasks(reset: true, animated: true)
  }

  /// Reload tasks.
  ///
  /// - Parameters:
  ///   - reset: A flag whether to reset content and failure
  ///   - animated: Apply to loading indicator view (not refresh control nor load-more control)
  open func reloadTasks(reset: Bool, animated: Bool) {
    if reset {
      currentPaging = nil
      currentError = nil
      applyData(nil, page: 1)
    }
    if animated {
      loadingIndicatorView.startAnimating()
    }
    startTasks()
  }

  private func startTasks(page: Int = 1) {
    assert(isViewLoaded, "`\(#function)` can only be called after view is loaded.")
    cancelAllTasks()
    isLoading = true
    emptyView.reload()
    cancellables = startTasks(page: page) { [weak self] result in
      guard let self else { return }
      isLoading = false
      tasksDidComplete(result: result, page: page)
    }
  }

  /// `completionHandler` must be called on main queue.
  @discardableResult
  open func startTasks(page: Int, completion: @escaping (Result<(Contents, PagingProtocol?), Error>) -> Void) -> Set<AnyCancellable> {
    fatalError("Subclass must override")
  }

  // MARK: Task Lifecycle

  open func tasksDidComplete(result: Result<(Contents, PagingProtocol?), Error>, page: Int) {
    loadingIndicatorView.stopAnimating()
    if let loadingIndicatorViewIfLoaded {
      loadingIndicatorViewIfLoaded.stopAnimating()
    }

    headerRefreshControlIfLoaded?.endRefreshing()

    switch result {
    case .success(let (content, paging)):
      currentPaging = paging
      currentError = nil
      applyData(content, page: page)
      emptyView.reload()

      if let refreshingScrollView {
        if automaticallyConfiguresHeaderRefreshControl {
          configureHeaderRefreshControl(for: refreshingScrollView)
        }

        if let paging, paging.hasNextPage() {
          if let footerRefreshControlIfLoaded {
            footerRefreshControlIfLoaded.endRefreshing()
          } else {
            if automaticallyConfiguresFooterRefreshControl {
              configureFooterRefreshControl(for: refreshingScrollView)
            }
          }
        } else {
          if let footerRefreshControlIfLoaded {
            if let footerRefreshControlIfLoaded = footerRefreshControlIfLoaded as? FiniteRefreshControl {
              footerRefreshControlIfLoaded.endRefreshingWithNoMoreData()
              footerRefreshControlIfLoaded.isHidden = true
            } else {
              footerRefreshControlIfLoaded.endRefreshing()
            }
          }
        }
      }

    case .failure(let error):
      var isHandled: Bool = false
      if page == 1 && currentPaging == nil {
        let cachedContents = cachedContents
        if !isNilOrEmpty(cachedContents) {
          currentError = error
          applyData(cachedContents, page: nil)
          emptyView.reload()
          isHandled = true
        }
      }
      if !isHandled {
        currentError = error
        emptyView.reload()
      }

      footerRefreshControlIfLoaded?.endRefreshing()
    }
  }

  open func cancelAllTasks() {
    for cancellable in cancellables {
      cancellable.cancel()
    }
  }

  private func configureHeaderRefreshControl(for scrollView: UIScrollView) {
#if targetEnvironment(macCatalyst)
#else
    guard headerRefreshControlIfLoaded == nil else { return }

    if let refreshControlProvider = TaskUIKitConfiguration.headerRefreshControlProvider {
      let refreshControl = refreshControlProvider(scrollView, { [weak self] in
        guard let self else { return }
        didPullToRefresh()
      })
      headerRefreshControlIfLoaded = refreshControl
      return
    }

    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
    scrollView.refreshControl = refreshControl
    headerRefreshControlIfLoaded = refreshControl
#endif
  }

  private func configureFooterRefreshControl(for scrollView: UIScrollView) {
#if targetEnvironment(macCatalyst)
#else
    guard footerRefreshControlIfLoaded == nil else { return }

    if let refreshControlProvider = TaskUIKitConfiguration.footerRefreshControlProvider {
      let refreshControl = refreshControlProvider(scrollView, { [weak self] in
        guard let self else { return }
        didPullToLoadMore()
      })
      footerRefreshControlIfLoaded = refreshControl
      return
    }

    let footer = MJRefreshAutoNormalFooter { [unowned self] in
      startTasks(page: currentPaging.map { $0.page + 1 } ?? 1)
    }
    footer.stateLabel?.isHidden = true
    footer.isRefreshingTitleHidden = true
    scrollView.mj_footer = footer
    footerRefreshControlIfLoaded = footer
#endif
  }

  @objc private func didPullToRefresh() {
    reloadTasks(reset: false, animated: false)
  }

  @objc private func didPullToLoadMore() {
    startTasks(page: currentPaging.map { $0.page + 1 } ?? 1)
  }

  // MARK: Data

  /// When `contents` is loaded from cache via `cachedContents`, `page` is `nil`.
  open func applyData(_ contents: Contents?, page: Int?) {
    if let contents, !isNilOrEmpty(contents) {
      let currentViewController = viewController
      if let newViewController = viewController(for: contents, reusingViewController: currentViewController) {
        viewController = newViewController
        if newViewController != currentViewController {
          currentViewController?.removeFromParentIncludingView()
          addChildIncludingView(newViewController) { view, childView in
            childView.frame = view.bounds
            childView.autoresizingMask = .flexibleSize
            view.insertSubview(childView, at: 0)
          }
        }
      } else {
        viewController?.removeFromParentIncludingView()
        viewController = nil
      }
    } else {
      viewController?.removeFromParentIncludingView()
      viewController = nil
    }
  }

  open func viewController(for contents: Contents, reusingViewController: UIViewController?) -> UIViewController? {
    return nil
  }

  // MARK: Empty View

  open func configureEmptyView(_ emptyView: EmptyView, for error: Error) {
    emptyView.image = TaskUIKitConfiguration.emptyViewImageForError
    emptyView.title = NSLocalizedString("Unable to Load", bundle: Bundle.module, comment: "")
    emptyView.message = error.localizedDescription
    emptyView.button.setTitle(NSLocalizedString("Reload", bundle: Bundle.module, comment: ""), for: .normal)
    emptyView.button.addTarget(self, action: #selector(reloadTasks(_:)), for: .touchUpInside)
  }

  open func configureEmptyViewForEmpty(_ emptyView: EmptyView) {
    emptyView.image = TaskUIKitConfiguration.emptyViewImageForEmpty
    emptyView.title = NSLocalizedString("No Content", bundle: Bundle.module, comment: "")
  }

  // MARK:

  public func state(for emptyView: EmptyView) -> EmptyView.State? {
    if isLoading {
      return nil
    }
    if !isNilOrEmpty(contents) {
      return nil
    }
    if let currentError {
      return .error(currentError)
    }
    if let initialError {
      return .error(initialError)
    }
    return .empty
  }

  public func emptyView(_ emptyView: EmptyView, configureContentFor state: EmptyView.State) {
    switch state {
    case .error(let error):
      configureEmptyView(emptyView, for: error)
    case .empty:
      configureEmptyViewForEmpty(emptyView)
    }
  }
}
