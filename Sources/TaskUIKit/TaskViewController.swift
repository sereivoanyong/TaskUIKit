//
//  TaskViewController.swift
//
//  Created by Sereivoan Yong on 2/4/20.
//

import UIKitUtilities
import Combine
import MJRefresh

/// Subclass must implement these functions:
/// `startTasks(page:completion:)`
/// `contents`
/// `store(_:page:)`
/// `reloadData(_:page:)`
open class TaskViewController<Contents>: UIViewController, EmptyViewStateProviding, EmptyViewDataSource {

  private var isFirstViewAppear: Bool = true

  private var isContentsNilOrEmpty: Bool {
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

  open private(set) var isLoading: Bool = false

  /// Setting this property after `viewIsAppearing(_:)` has no effect
  open var loadsTaskOnViewAppear: Bool = true

  /// Returns the scroll view for pull-to-refresh
  open var refreshingScrollView: UIScrollView? {
    return nil
  }

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
    let style: UIActivityIndicatorView.Style
    if #available(iOS 13.0, *) {
      style = .medium
    } else {
      style = .gray
    }
    let indicatorView = UIActivityIndicatorView(style: style)
    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    loadingIndicatorViewIfLoaded = indicatorView
    view.addSubview(indicatorView)

    NSLayoutConstraint.activate([
      indicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      indicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
    ])
    return indicatorView
  }()

  // MARK: Init / Deinit

  deinit {
    cancelAllTasks()
  }

  // MARK: View Lifecycle

  open override func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)

    if isFirstViewAppear {
      isFirstViewAppear = false
      if isContentsNilOrEmpty {
        if loadsTaskOnViewAppear {
          // We do not need to reset as this is an initial load.
          reloadTasks(reset: false, animated: true)
        }
      } else {
        if let refreshingScrollView {
          configureRefreshControl(for: refreshingScrollView)
        }
      }
    }
  }

  // MARK: Networking

  @objc open func resetAndReloadTasksWithAnimation() {
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
      store(nil, page: 1)
      reloadData(nil, page: 1)
    }
    if animated {
      loadingIndicatorView.startAnimating()
    }
    startTasks()
  }

  final public func startTasks(page: Int = 1) {
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
    let refreshingScrollView = refreshingScrollView
    refreshingScrollView?.refreshControl?.endRefreshing()

    switch result {
    case .success(let (content, paging)):
      currentPaging = paging
      if let refreshingScrollView {
        configureRefreshControl(for: refreshingScrollView)

        if let paging, paging.hasNextPage() {
          if let footer = refreshingScrollView.mj_footer {
            footer.endRefreshing()
            footer.isHidden = true
          } else {
            let footer = MJRefreshAutoNormalFooter { [unowned self] in
              startTasks(page: paging.page + 1)
            }
            footer.stateLabel?.isHidden = true
            footer.isRefreshingTitleHidden = true
            refreshingScrollView.mj_footer = footer
          }
        } else {
          if let footer = refreshingScrollView.mj_footer {
            footer.endRefreshingWithNoMoreData()
            footer.isHidden = true
          }
        }
      }

      currentError = nil
      store(content, page: page)
      emptyView.reload()
      reloadData(content, page: page)

    case .failure(let error):
      refreshingScrollView?.mj_footer?.endRefreshing()

      currentError = error
      store(nil, page: page)
      emptyView.reload()
      reloadData(nil, page: page)
    }
  }

  open func cancelAllTasks() {
    for cancellable in cancellables {
      cancellable.cancel()
    }
  }

  private func configureRefreshControl(for scrollView: UIScrollView) {
#if targetEnvironment(macCatalyst)
#else
    guard scrollView.refreshControl == nil else { return }
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
    scrollView.refreshControl = refreshControl
#endif
  }

  @objc private func didPullToRefresh(_ sender: UIRefreshControl) {
    reloadTasks(reset: false, animated: false)
  }

  // MARK: Data

  open func store(_ contents: Contents?, page: Int) {
    fatalError("\(#function) has not been implemented")
  }

  open func reloadData(_ contents: Contents?, page: Int) {
    if let contents {
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
        viewController = nil
      }
    } else {
      viewController?.removeFromParentIncludingView()
    }
  }

  open func viewController(for contents: Contents, reusingViewController: UIViewController?) -> UIViewController? {
    return nil
  }

  // MARK: Empty View

  open func configureEmptyView(_ emptyView: EmptyView, for error: Error) {
    emptyView.title = NSLocalizedString("Unable to Load", bundle: Bundle.module, comment: "")
    emptyView.message = error.localizedDescription
    emptyView.button.setTitle(NSLocalizedString("Reload", bundle: Bundle.module, comment: ""), for: .normal)
    emptyView.button.addTarget(self, action: #selector(resetAndReloadTasksWithAnimation), for: .touchUpInside)
  }

  open func configureEmptyViewForEmpty(_ emptyView: EmptyView) {
    emptyView.title = NSLocalizedString("No Content", bundle: Bundle.module, comment: "")
  }

  // MARK:

  public func state(for emptyView: EmptyView) -> EmptyView.State? {
    if isLoading {
      return nil
    }
    if !isContentsNilOrEmpty {
      return nil
    }
    if let currentError {
      return .error(currentError)
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
