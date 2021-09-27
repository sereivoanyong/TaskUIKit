//
//  TaskViewController.swift
//
//  Created by Sereivoan Yong on 2/4/20.
//

import UIKit
import UIKitExtra
import MJRefresh

/// Subclass must implement these functions:
/// `isContentNilOrEmpty`
/// `responseConfiguration`
/// `urlRequest(for:)`
/// `store(_:for:)`
/// `reloadData(_:for:)`

@available(iOS 11.0, *)
open class TaskViewController<Response, Content>: UIViewController, EmptyViewStateProviding, EmptyViewDataSource {

  open private(set) var currentTask: URLSessionDataTask?
  open private(set) var currentPaging: PagingProtocol?
  open private(set) var currentFailure: Failure?

  /**
   ```
   // For non-list
   object == nil
   // For list
   objects.isEmpty
   ```
   */
  open var isContentNilOrEmpty: Bool {
    fatalError()
  }

  open var session: URLSession = .shared

  open var loadsTaskOnViewDidLoad: Bool = true

  open var responseConfiguration: ResponseConfiguration<Response, Content> {
    fatalError()
  }

  /// Returns the scroll view for pull-to-refresh
  open var refreshingScrollView: UIScrollView? {
    nil
  }

  /// Returns the scroll view for load-more (paging)
  open var pagingScrollView: UIScrollView? {
    refreshingScrollView
  }

  private var _emptyView: EmptyView?
  lazy open private(set) var emptyView: EmptyView = {
    let emptyView = EmptyView()
    emptyView.stateProvider = self
    emptyView.dataSource = self
    emptyView.translatesAutoresizingMaskIntoConstraints = false
    if let loadingIndicatorView = _loadingIndicatorView {
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

  private var _loadingIndicatorView: UIActivityIndicatorView?
  lazy open private(set) var loadingIndicatorView: UIActivityIndicatorView = {
    let style: UIActivityIndicatorView.Style
    if #available(iOS 13.0, *) {
      style = .medium
    } else {
      style = .gray
    }
    let indicatorView = UIActivityIndicatorView(style: style)
    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(indicatorView)

    NSLayoutConstraint.activate([
      indicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      indicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
    ])
    return indicatorView
  }()

  // MARK: Init / Deinit

  deinit {
    currentTask?.cancel()
  }

  // MARK: View Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    if loadsTaskOnViewDidLoad {
      // We do not need to reset as this is an initial load.
      reloadTask(reset: false, animated: true)
    }
  }

  // MARK: Networking

  open func urlRequest(for page: Int) -> URLRequest {
    fatalError("\(#function) has not been implemented")
  }

  @objc private func resetAndReloadTaskWithAnimation() {
    reloadTask(reset: true, animated: true)
  }

  /// Reload task.
  ///
  /// - Parameters:
  ///   - reset: A flag whether to reset content and failure
  ///   - animated: Apply to loading indicator view (not refresh control nor load more control)
  open func reloadTask(reset: Bool, animated: Bool) {
    if reset {
      currentFailure = nil
      store(nil, for: 1)
      reloadData(nil, for: 1)
    }
    if animated {
      loadingIndicatorView.startAnimating()
    }
    startTask(page: 1)
  }

  final private func startTask(page: Int) {
    assert(isViewLoaded, "startTask can only be called after view is loaded.")
    currentTask?.cancel()
    let task = session.dataTask(with: urlRequest(for: page)) { [weak self] result in
      guard let self = self else {
        return
      }
      switch result {
      case .success(let (data, response)):
        let result: Result<(Response, Content), Failure>
        if self.responseConfiguration.acceptableStatusCodes.contains(response.statusCode) {
          do {
            try self.validate(data, response)
            do {
              let response = try self.responseConfiguration.transform(data, response)
              let content = self.responseConfiguration.contentProvider(response)
              result = .success((response, content))
            } catch {
              result = .failure(.serialization(error))
            }
          } catch {
            result = .failure(.validation(data, response, error))
          }
        } else {
          result = .failure(.unacceptance(data, response))
        }
        DispatchQueue.main.async {
          self.taskDidComplete(page: page, result: result)
        }

      case .failure(let error):
        if error.code != .cancelled {
          DispatchQueue.main.async {
            self.taskDidComplete(page: page, result: .failure(.url(error)))
          }
        }
      }
    }
    task.resume()
    currentTask = task
  }

  open func validate(_ data: Data, _ response: HTTPURLResponse) throws {

  }

  // MARK: Task Lifecycle

  open func taskDidComplete(page: Int, result: Result<(Response, Content), Failure>) {
    loadingIndicatorView.stopAnimating()
    refreshingScrollView?.refreshControl?.endRefreshing()

    switch result {
    case .success(let (response, content)):
      if let scrollView = refreshingScrollView, scrollView.refreshControl == nil {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        scrollView.refreshControl = refreshControl
      }

      currentPaging = responseConfiguration.pagingProvider(response)
      if let scrollView = pagingScrollView {
        let hasNextPage = currentPaging?.hasNext() ?? false
        if hasNextPage && scrollView.mj_footer == nil {
          let footer = MJRefreshAutoNormalFooter() { [unowned self] in
            startTask(page: page + 1)
          }
          footer.stateLabel?.isHidden = true
          footer.isRefreshingTitleHidden = true
          scrollView.mj_footer = footer
        }

        if let footer = scrollView.mj_footer {
          if hasNextPage {
            footer.endRefreshing()
            footer.isHidden = false
          } else {
            footer.endRefreshingWithNoMoreData()
            footer.isHidden = true
          }
        }
      }

      currentFailure = nil
      store(content, for: page)
      reloadData(content, for: page)

    case .failure(let failure):
      currentFailure = failure
      store(nil, for: page)
      reloadData(nil, for: page)
    }
  }

  @objc private func didPullToRefresh(_ sender: UIRefreshControl) {
    reloadTask(reset: false, animated: false)
  }

  // MARK: Data

  open func store(_ content: Content?, for page: Int) {
    fatalError("\(#function) has not been implemented")
  }

  open func reloadData(_ content: Content?, for page: Int) {
    fatalError("\(#function) has not been implemented")
  }

  // MARK: Empty View

  open func configureEmptyView(_ emptyView: EmptyView, for failure: Failure) {
    emptyView.title = NSLocalizedString("Unable to Load", comment: "")
    emptyView.message = failure.errorDescription
    emptyView.button.setTitle(NSLocalizedString("Reload", comment: ""), for: .normal)
    emptyView.button.addTarget(self, action: #selector(resetAndReloadTaskWithAnimation), for: .touchUpInside)
  }

  open func configureEmptyViewForEmpty(_ emptyView: EmptyView) {
    emptyView.title = NSLocalizedString("No Content", comment: "")
  }

  // MARK:

  final public func state(for emptyView: EmptyView) -> EmptyView.State? {
    if !isContentNilOrEmpty {
      return nil
    }
    if let currentFailure = currentFailure {
      return .error(currentFailure)
    }
    return .empty
  }

  final public func emptyView(_ emptyView: EmptyView, configureContentFor state: EmptyView.State) {
    switch state {
    case .error(let error):
      configureEmptyView(emptyView, for: error as! Failure)
    case .empty:
      configureEmptyViewForEmpty(emptyView)
    }
  }
}

extension TaskViewController {

  final public func store<Objects>(_ content: Content?, for page: Int, in objects: inout Objects) where Content: Sequence, Objects: RangeReplaceableCollection, Content.Element == Objects.Element {
    if page == 1 {
      objects = content.map { $0 as? Objects ?? Objects.init($0) } ?? .init()
    } else {
      if let content = content {
        objects.append(contentsOf: content)
      }
    }
  }
}

extension URLSession {

  final fileprivate func dataTask(with request: URLRequest, completion: @escaping (Result<(Data, HTTPURLResponse), URLError>) -> Void) -> URLSessionDataTask {
    return dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error as! URLError))
      } else {
        completion(.success((data!, response as! HTTPURLResponse)))
      }
    }
  }
}
