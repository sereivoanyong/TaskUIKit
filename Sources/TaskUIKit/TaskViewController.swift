//
//  TaskViewController.swift
//
//  Created by Sereivoan Yong on 2/4/20.
//

import UIKit
import DZNEmptyDataSet

public protocol TaskReloadable: AnyObject {
  
  func reloadTask(animated: Bool)
}

@available(iOS 11.0, *)
open class TaskViewController<Response, Contents>: UIViewController, TaskReloadable {
  
  /// A failure that is used to give users useful information.
  public enum Failure: Error {
    
    /// Request failed locally (e.g. no internet connection). Check`URLError.Code` to see all possible errors
    case url(URLError)
    /// Request succeded but server returns status code that is not in `validResponseStatusCodeRange` (e.g. unauthorized, server busy, not found...).
    case invalid(ValidationError)
    /// Request succeded  with valid `statusCode` but response value could not be transform to `Response`.
    case transforming(Error)
  }
  
  open private(set) var currentTask: URLSessionDataTask?
  open private(set) var currentFailure: Failure?
  open var emptyDataSetAdapter: DZNEmptyDataSetAdapter? {
    didSet {
      if let scrollView = pullToRefreshScrollView {
        scrollView.emptyDataSetSource = emptyDataSetAdapter
        scrollView.emptyDataSetDelegate = emptyDataSetAdapter
        scrollView.reloadEmptyDataSet()
      }
    }
  }
  
  open var session: URLSession = .shared
  
  /// Only `ValidationError` can be thrown
  open var responseValidationHandler: (HTTPURLResponse) throws -> Void = { response in
    if 200...299 ~= response.statusCode {
      return
    }
    throw ValidationError(response: response)
  }
  
  public let responseTransformer: ResponseTransformer<Response, Contents>
  open var emptyDataSetAdapterProvider: ((Failure) -> DZNEmptyDataSetAdapter?)?
  
  open var loadsTaskOnViewDidLoad: Bool = true
  
  open var pullToRefreshScrollView: UIScrollView? {
    return nil
  }
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
  
  public init(responseTransformer: ResponseTransformer<Response, Contents>) {
    self.responseTransformer = responseTransformer
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    currentTask?.cancel()
  }
  
  // MARK: View Lifecycle
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    if let defaultEmptyDataSetAdapter = defaultEmptyDataSetAdapter() {
      emptyDataSetAdapter = defaultEmptyDataSetAdapter
    } else if loadsTaskOnViewDidLoad {
      reloadTask(animated: true)
    }
  }
  
  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    view.endEditing(true)
  }
  
  // MARK: Networking
  
  open func urlRequest() -> URLRequest {
    fatalError("\(#function) has not been implemented")
  }
  
  /// Reload task
  /// - Parameters:
  ///   - animated: Apply to loading indicator view (not refresh control nor load more control)
  open func reloadTask(animated: Bool) {
    if animated {
      loadingIndicatorView.startAnimating()
    }
    emptyDataSetAdapter = nil
    startTask()
  }
  
  final private func startTask() {
    taskWillStart()
    startTask(with: urlRequest(), transformer: responseTransformer) { [unowned self] result in
      self.taskDidComplete(result: result)
    }
    taskDidStart()
  }
  
  final internal func startTask(with urlRequest: URLRequest, transformer: ResponseTransformer<Response, Contents>, completion: @escaping (Result<(Response, Contents), Failure>) -> Void) {
    assert(isViewLoaded, "startTask can only be called after view is loaded.")
    let task = session.dataTask(with: urlRequest) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let (data, response)):
          do {
            try self.responseValidationHandler(response)
            do {
              let (response, contents) = try transformer.transform(data, response)
              completion(.success((response, contents)))
            } catch {
              completion(.failure(.transforming(error)))
            }
          } catch {
            assert(error is ValidationError, "Only `ValidationError` can be thrown")
            completion(.failure(.invalid(error as! ValidationError)))
          }
          
        case .failure(let error):
          if error.code != .cancelled {
            completion(.failure(.url(error)))
          }
        }
      }
    }
    task.resume()
    currentTask = task
  }
  
  // MARK: Task Lifecycle
  
  open func taskWillStart() {
    currentTask?.cancel()
  }
  
  open func taskDidStart() {
    
  }
  
  open func taskDidComplete(result: Result<(Response, Contents), Failure>) {
    loadingIndicatorView.stopAnimating()
    pullToRefreshScrollView?.refreshControl?.endRefreshing()
    
    switch result {
    case .success(let (_, contents)):
      if let scrollView = pullToRefreshScrollView, scrollView.refreshControl == nil {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        scrollView.refreshControl = refreshControl
      }
      reloadData(contents)
      
    case .failure(let failure):
      reloadEmptyDataSet(failure)
    }
  }
  
  @objc private func didPullToRefresh(_ sender: UIRefreshControl) {
    reloadTask(animated: false)
  }
  
  // MARK: Data
  
  /// Reload data (optionally store `contents`) then update the UI
  open func reloadData(_ contents: Contents) {
    fatalError("\(#function) has not been implemented")
  }
  
  /// Reset data then update the UI
  open func resetData(animated: Bool = false) {
    fatalError("\(#function) has not been implemented")
  }
  
  open func reloadEmptyDataSet(_ failure: Failure) {
    currentFailure = failure
    emptyDataSetAdapter = emptyDataSetAdapter(for: failure)
  }
  
  open func emptyDataSetAdapter(for failure: Failure) -> DZNEmptyDataSetAdapter {
    if let adapter = emptyDataSetAdapterProvider?(failure) {
      return adapter
    }
    let buttonTitleColor = UIApplication.shared.keyWindow?.tintColor ?? view.tintColor ?? .systemBlue
    switch failure {
    case .url(let error):
      if let error = error as? DZNEmptyDataSetAdapter {
        return error
      }
      let adapter = EmptyDataSetAdapter(reloadable: self)
      adapter.title = NSAttributedString(string: error.localizedDescription, attributes: nil)
      adapter.buttonTitles = [.normal: NSAttributedString(string: NSLocalizedString("Reload", comment: ""), attributes: [.foregroundColor: buttonTitleColor])]
      adapter.buttonActionHandler = { [unowned self] _ in
        self.reloadTask(animated: true)
      }
      return adapter
      
    case .invalid(let error):
      if let error = error as? DZNEmptyDataSetAdapter {
        return error
      }
      let adapter = EmptyDataSetAdapter(reloadable: self)
      adapter.title = NSAttributedString(string: error.localizedDescription, attributes: nil)
      adapter.buttonTitles = [.normal: NSAttributedString(string: NSLocalizedString("Reload", comment: ""), attributes: [.foregroundColor: buttonTitleColor])]
      adapter.buttonActionHandler = { [unowned self] _ in
        self.reloadTask(animated: true)
      }
      return adapter
      
    case .transforming(let error):
      let adapter = EmptyDataSetAdapter(reloadable: self)
      adapter.title = NSAttributedString(string: NSLocalizedString("Invalid Response", comment: ""), attributes: nil)
      #if !RELEASE
      adapter.description_ = NSAttributedString(string: error.localizedDescription, attributes: nil)
      #endif
      adapter.buttonTitles = [.normal: NSAttributedString(string: NSLocalizedString("Reload", comment: ""), attributes: [.foregroundColor: buttonTitleColor])]
      adapter.buttonActionHandler = { [unowned self] _ in
        self.reloadTask(animated: true)
      }
      return adapter
    }
  }
  
  // MARK: DefaultEmptyDataSetAdapter
  
  /// Task will only load if this function return nil.
  open func defaultEmptyDataSetAdapter() -> EmptyDataSetAdapter? {
    return nil
  }
  
  open func reloadDefaultEmptyDataSetOrTask() {
    if let defaultEmptyDataSetAdapter = defaultEmptyDataSetAdapter() {
      resetData()
      emptyDataSetAdapter = defaultEmptyDataSetAdapter
    } else {
      reloadTask(animated: true)
    }
  }
}
