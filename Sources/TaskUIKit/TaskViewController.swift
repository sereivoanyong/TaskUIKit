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
/// `startTasks(of:cancellables:completion:)`
/// `applyData(_:source:)`
open class TaskViewController<Contents>: UIViewController, EmptyViewStateProviding, EmptyViewDataSource {

  public enum SourcedContents {

    case response(Contents, isInitial: Bool)
    case cache(Contents)

    public var contents: Contents {
      switch self {
      case .response(let contents, _):
        return contents
      case .cache(let contents):
        return contents
      }
    }
  }

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

  open private(set) var cancellables: [AnyCancellable] = [] {
    willSet {
      cancelAllTasks()
    }
  }

  /// The request's paging response.
  open private(set) var currentPaging: Paging?

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

  open private(set) var viewController: UIViewController?

  open private(set) var emptyViewIfLoaded: EmptyView?
  lazy open private(set) var emptyView: EmptyView = {
    let emptyView = EmptyView()
    emptyViewIfLoaded = emptyView
    emptyView.stateProvider = self
    emptyView.dataSource = self
    if let loadingIndicatorView = loadingIndicatorViewIfLoaded {
      view.insertSubview(emptyView, belowSubview: loadingIndicatorView)
    } else {
      view.addSubview(emptyView)
    }

    emptyView.translatesAutoresizingMaskIntoConstraints = false
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

#if !targetEnvironment(macCatalyst)
  open private(set) var headerRefreshControlIfLoaded: RefreshControl?

  open private(set) var footerRefreshControlIfLoaded: FiniteRefreshControl?

  open var automaticallyConfiguresHeaderRefreshControl: Bool = true

  open var automaticallyConfiguresFooterRefreshControl: Bool = true
#endif

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
          reloadTasks(reset: true, animated: true)
        } else {
          emptyView.reload()
        }
      } else {
        emptyView.reload()
      }
    }
  }

  // MARK: Networking

  /// Reload tasks.
  ///
  /// - Parameters:
  ///   - reset: A flag whether to reset content and failure
  ///   - animated: Apply to loading indicator view (not refresh control nor load-more control)
  open func reloadTasks(reset: Bool, animated: Bool) {
    assert(isViewLoaded, "`\(#function)` can only be called after view is loaded.")

    cancelAllTasks()
    isLoading = true

    if reset {
      currentPaging = nil
      currentError = nil
      applyData(nil)
    }
    emptyView.reload()

    if animated {
      if reset {
        loadingIndicatorView.startAnimating()
      } else {
#if !targetEnvironment(macCatalyst)
        headerRefreshControlIfLoaded?.beginRefreshing()
#endif
      }
    }

    var newCancellables: [AnyCancellable] = []
    startTasks(cancellables: &newCancellables) { [weak self] result in
      self?.tasks(didCompleteWith: result)
    }
    cancellables = newCancellables
  }

  open func loadTasksForNextPage(animated: Bool) {
    assert(isViewLoaded, "`\(#function)` can only be called after view is loaded.")
    guard let currentPaging else { return }

    cancelAllTasks()
    isLoading = true

    if animated {
#if !targetEnvironment(macCatalyst)
      footerRefreshControlIfLoaded?.beginRefreshing()
#endif
    }

    var newCancellables: [AnyCancellable] = []
    startTasks(nextPageOf: currentPaging, cancellables: &newCancellables) { [weak self] result in
      self?.tasks(nextPageOf: currentPaging, didCompleteWith: result)
    }
    cancellables = newCancellables
  }

  /// - Parameters:
  ///   - pagingForNext: the paging is used as reference to load next page. This is `nil` for initial page (1)
  ///   - cancellables: a disposable bag to store chainable requests.
  ///   - completion: must be called on main queue.
  open func startTasks(nextPageOf paging: Paging? = nil, cancellables: inout [AnyCancellable], completion: @escaping (Result<(Contents, Paging?), Error>) -> Void) {
    fatalError("Subclass must override")
  }

  // MARK: Task Lifecycle

  open func tasks(nextPageOf pagingForNext: Paging? = nil, didCompleteWith result: Result<(Contents, Paging?), Error>) {
    isLoading = false
    loadingIndicatorViewIfLoaded?.stopAnimating()
#if !targetEnvironment(macCatalyst)
    headerRefreshControlIfLoaded?.endRefreshing()
#endif

    switch result {
    case .success(let (responseContents, responsePaging)):
      currentPaging = responsePaging
      currentError = nil
      applyData(.response(responseContents, isInitial: pagingForNext == nil))
      emptyView.reload()

#if !targetEnvironment(macCatalyst)
      if let refreshingScrollView {
        if automaticallyConfiguresHeaderRefreshControl {
          configureHeaderRefreshControl(for: refreshingScrollView)
        }

        if let responsePaging, responsePaging.hasNextPage() {
          if let footerRefreshControlIfLoaded {
            footerRefreshControlIfLoaded.endRefreshing()
          } else {
            if automaticallyConfiguresFooterRefreshControl {
              configureFooterRefreshControl(for: refreshingScrollView)
            }
          }
        } else {
          if let footerRefreshControlIfLoaded {
            footerRefreshControlIfLoaded.endRefreshingWithNoMoreData()
            footerRefreshControlIfLoaded.isHidden = true
          }
        }
      }
#endif

    case .failure(let error):
      currentError = error
      if pagingForNext == nil {
        if let cachedContents {
          applyData(.cache(cachedContents))
        }
      }

      emptyView.reload()
#if !targetEnvironment(macCatalyst)
      footerRefreshControlIfLoaded?.endRefreshing()
#endif
    }
  }

  open func applyData(_ contents: SourcedContents?) {
    if let contents, !isNilOrEmpty(contents.contents) {
      let currentViewController = viewController
      if let newViewController = viewController(for: contents.contents, reusingViewController: currentViewController) {
        viewController = newViewController
        if newViewController != currentViewController {
          currentViewController?.removeFromParentIncludingView()
          addChildIncludingView(newViewController) { view, childView in
            addView(childView, to: view)
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

  open func viewController(for newContents: Contents, reusingViewController: UIViewController?) -> UIViewController? {
    return nil
  }

  open func addView(_ childView: UIView, to view: UIView) {
    childView.frame = view.bounds
    childView.autoresizingMask = .flexibleSize
    view.insertSubview(childView, at: 0)
  }

  open func cancelAllTasks() {
    for cancellable in cancellables {
      cancellable.cancel()
    }
  }

  // MARK: Actions

  @objc private func didTapReload(_ sender: UIButton) {
    reloadTasks(reset: true, animated: true)
  }

#if !targetEnvironment(macCatalyst)
  @objc private func didPullToRefresh() {
    reloadTasks(reset: false, animated: false)
  }

  @objc private func didPullToLoadMore() {
    loadTasksForNextPage(animated: false)
  }
#endif

  // MARK: Header / Footer

#if !targetEnvironment(macCatalyst)
  private func configureHeaderRefreshControl(for scrollView: UIScrollView) {
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

  }

  private func configureFooterRefreshControl(for scrollView: UIScrollView) {
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
      didPullToLoadMore()
    }
    footer.stateLabel?.isHidden = true
    footer.isRefreshingTitleHidden = true
    scrollView.mj_footer = footer
    footerRefreshControlIfLoaded = footer
  }
#endif

  // MARK: Empty View

  open func configureEmptyView(_ emptyView: EmptyView, for error: Error) {
    emptyView.image = TaskUIKitConfiguration.emptyViewImageForError
    emptyView.text = NSLocalizedString("Unable to Load", bundle: Bundle.module, comment: "")
    emptyView.secondaryText = error.localizedDescription
    emptyView.button.setTitle(NSLocalizedString("Reload", bundle: Bundle.module, comment: ""), for: .normal)
    emptyView.button.addTarget(self, action: #selector(didTapReload), for: .touchUpInside)
  }

  open func configureEmptyViewForEmpty(_ emptyView: EmptyView) {
    emptyView.image = TaskUIKitConfiguration.emptyViewImageForEmpty
    emptyView.text = NSLocalizedString("No Content", bundle: Bundle.module, comment: "")
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
