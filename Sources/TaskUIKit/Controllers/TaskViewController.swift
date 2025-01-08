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

  public enum InitialAction {

    case reload
    case loadFromCacheOrReload
  }

  public enum Source {

    case response
    case cache
  }

  public enum SourcedContents {

    case response(Contents, isInitial: Bool, TaskUserInfo? = nil)
    case cache(Contents)

    public var contents: Contents {
      switch self {
      case .response(let contents, _, _):
        return contents
      case .cache(let contents):
        return contents
      }
    }
  }

  open private(set) var isFirstViewAppear: Bool = true

  func isNilOrEmpty(_ contents: Contents?) -> Bool {
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

  open private(set) var isLoading: Bool = false

  /// The request's paging response.
  open private(set) var currentPaging: Paging?

  open private(set) var currentError: Error?

  open var contents: Contents? {
    fatalError("\(#function) must be overriden")
  }

  open var initialError: Error? {
    return nil
  }

  /// If `initialError` is `nil`, this property is performed.
  /// Set to `nil` to do nothing. We will have to manually reload task.
  open var initialAction: InitialAction? = .reload

  /// Returns the scroll view for pull-to-refresh
  open var refreshingScrollView: UIScrollView? {
    return nil
  }

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
      if initialError != nil {
        emptyView.reload()
      } else {
        if let initialAction {
          switch initialAction {
          case .reload:
            reloadTasks(reset: false, animated: true)
          case .loadFromCacheOrReload:
            if let cachedContents = loadContents(for: .cache), !isNilOrEmpty(cachedContents) {
              applyData(.cache(cachedContents)) { [unowned self] in
                emptyView.reload()

#if !targetEnvironment(macCatalyst)
                if let refreshingScrollView {
                  if headerRefreshControlIfLoaded == nil && automaticallyConfiguresHeaderRefreshControl {
                    configureHeaderRefreshControl(for: refreshingScrollView)
                  }
                }
#endif
              }
            } else {
              reloadTasks(reset: false, animated: true)
            }
          }
        }
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
      resetData()
    }
    emptyView.reload()

    if animated {
      if reset || isNilOrEmpty(contents){
        loadingIndicatorView.startAnimating()
      }
    }

    var newCancellables: [AnyCancellable] = []
    startTasks(cancellables: &newCancellables) { [weak self] result in
      self?.tasks(didCompleteWith: result)
    }
    cancellables = newCancellables
  }

  open func loadTasksForNextPage() {
    assert(isViewLoaded, "`\(#function)` can only be called after view is loaded.")
    guard let currentPaging else { return }

    cancelAllTasks()
    isLoading = true

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
  open func startTasks(nextPageOf paging: Paging? = nil, cancellables: inout [AnyCancellable], completion: @escaping (TaskResult<Contents>) -> Void) {
    fatalError("\(#function) must be overriden")
  }

  open func resetTasks() {
    cancelAllTasks()

    currentPaging = nil
    currentError = nil
    resetData()

    isLoading = false
    emptyView.reload()

    loadingIndicatorViewIfLoaded?.stopAnimating()
#if !targetEnvironment(macCatalyst)
    headerRefreshControlIfLoaded?.endRefreshing()
    footerRefreshControlIfLoaded?.endRefreshing()
#endif
  }

  // MARK: Task Lifecycle

  func canProcess(_ result: TaskResult<Contents>) -> Bool {
    if case .failure(let error) = result, let error = error as? CancelingError {
      return !error.isCancelled
    }
    return true
  }

  open func tasks(nextPageOf pagingForNext: Paging? = nil, didCompleteWith result: TaskResult<Contents>) {
    guard canProcess(result) else { return }

    switch result {
    case .success(let responseContents, let responsePaging, let userInfo):
      currentPaging = responsePaging
      currentError = nil
      applyData(.response(responseContents, isInitial: pagingForNext == nil, userInfo)) { [unowned self] in
        tasksDidEnd(contents: responseContents, paging: responsePaging)
      }

    case .failure(let error):
      currentError = error
      if pagingForNext == nil {
        if let cachedContents = loadContents(for: .cache), !isNilOrEmpty(cachedContents) {
          applyData(.cache(cachedContents)) { [unowned self] in
            tasksDidEnd(contents: cachedContents, paging: nil)
          }
          return
        }
      }
      tasksDidEnd(contents: nil, paging: nil)
    }
  }

  private func tasksDidEnd(contents: Contents?, paging: Paging?) {
    isLoading = false
    emptyView.reload()

    loadingIndicatorViewIfLoaded?.stopAnimating()
#if !targetEnvironment(macCatalyst)
    let hasContents = contents != nil
    if let headerRefreshControlIfLoaded {
      headerRefreshControlIfLoaded.endRefreshing()
    } else {
      if hasContents && automaticallyConfiguresHeaderRefreshControl, let refreshingScrollView {
        configureHeaderRefreshControl(for: refreshingScrollView)
      }
    }

    if let paging, paging.hasNextPage() {
      if let footerRefreshControlIfLoaded {
        if footerRefreshControlIfLoaded.isHidden {
          footerRefreshControlIfLoaded.isHidden = false
        } else {
          footerRefreshControlIfLoaded.endRefreshing()
        }
      } else {
        if hasContents && automaticallyConfiguresFooterRefreshControl, let refreshingScrollView {
          configureFooterRefreshControl(for: refreshingScrollView)
        }
      }
    } else {
      if let footerRefreshControlIfLoaded {
        footerRefreshControlIfLoaded.endRefreshingAndHide()
      }
    }
#endif
  }

  /// This is called with `cache` as source when first page failed
  open func loadContents(for source: Source) -> Contents? {
    return nil
  }

  open func resetData() {
  }

  /// Subclass must call `completion` at the end or asynchronously.
  open func applyData(_ contents: SourcedContents, completion: @escaping () -> Void) {
    fatalError("\(#function) must be overriden")
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

  // MARK: Header / Footer

#if !targetEnvironment(macCatalyst)
  private func configureHeaderRefreshControl(for scrollView: UIScrollView) {
    if let provider = Configuration.shared.headerRefreshControlProvider {
      let header = provider(scrollView, { [weak self] in
        self?.reloadTasks(reset: false, animated: false)
      })
      headerRefreshControlIfLoaded = header
    } else {
      let header = MJRefreshNormalHeader { [weak self] in
        self?.reloadTasks(reset: false, animated: false)
      }
      scrollView.mj_header = header
      headerRefreshControlIfLoaded = header
    }
  }

  private func configureFooterRefreshControl(for scrollView: UIScrollView) {
    if let provider = Configuration.shared.footerRefreshControlProvider {
      let footer = provider(scrollView, { [weak self] in
        self?.loadTasksForNextPage()
      })
      footerRefreshControlIfLoaded = footer
    } else {
      let footer = MJRefreshAutoNormalFooter { [weak self] in
        self?.loadTasksForNextPage()
      }
      footer.stateLabel?.isHidden = true
      footer.isRefreshingTitleHidden = true
      scrollView.mj_footer = footer
      footerRefreshControlIfLoaded = footer
    }
  }
#endif

  // MARK: Empty View

  open func configureEmptyView(_ emptyView: EmptyView, for error: Error) {
    emptyView.image = Configuration.shared.emptyViewImageForError
    emptyView.text = NSLocalizedString("Unable to Load", bundle: Bundle.module, comment: "")
    emptyView.secondaryText = error.localizedDescription
    emptyView.button.setTitle(NSLocalizedString("Reload", bundle: Bundle.module, comment: ""), for: .normal)
    emptyView.button.addTarget(self, action: #selector(didTapReload), for: .touchUpInside)
  }

  open func configureEmptyViewForEmpty(_ emptyView: EmptyView) {
    emptyView.image = Configuration.shared.emptyViewImageForEmpty
    emptyView.text = NSLocalizedString("No Content", bundle: Bundle.module, comment: "")
  }

  // MARK: EmptyViewStateProviding

  open func state(for emptyView: EmptyView) -> EmptyView.State? {
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

  // MARK: EmptyViewDataSource

  open func emptyView(_ emptyView: EmptyView, configureContentFor state: EmptyView.State) {
    switch state {
    case .error(let error):
      configureEmptyView(emptyView, for: error)
    case .empty:
      configureEmptyViewForEmpty(emptyView)
    }
  }
}
