//
//  TaskTableViewController.swift
//
//  Created by Sereivoan Yong on 6/5/20.
//

import UIKit

/// Subclass must implement these functions:
/// `responseConfiguration`
/// `urlRequest(for:)`
/// `store(_:for:)`
/// `reloadData(_:for:)` (Optional)

open class TaskTableViewController<Response, Content>: TaskViewController<Response, Content> {

  /// Default is `UITableView.self`. Custom class must implement `init(frame:style:)`.
  open class var tableViewClass: UITableView.Type {
    UITableView.self
  }

  /// Default is `.plain`.
  open class var style: UITableView.Style {
    .plain
  }

  private var _tableView: UITableView!
  open var tableView: UITableView {
    get {
      if _tableView == nil {
        loadTableView()
        tableViewDidLoad()
      }
      return _tableView
    }
    set {
      precondition(_tableView == nil, "Table view can only be set before it is loaded.")
      _tableView = newValue
    }
  }

  public let style: UITableView.Style

  open override var refreshingScrollView: UIScrollView? {
    tableView
  }

  // MARK: Initializer

  public init(style: UITableView.Style) {
    self.style = style
    super.init(nibName: nil, bundle: nil)
  }

  public override init(nibName: String?, bundle: Bundle?) {
    self.style = Self.style
    super.init(nibName: nibName, bundle: bundle)
  }

  public required init?(coder: NSCoder) {
    self.style = Self.style
    super.init(coder: coder)
  }

  // MARK: View Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    tableView.frame = view.bounds
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.insertSubview(tableView, at: 0)
  }

  // MARK: Table View Lifecycle

  open func loadTableView() {
    let tableView = Self.tableViewClass.init(frame: UIScreen.main.bounds, style: style)
    tableView.preservesSuperviewLayoutMargins = true
    tableView.alwaysBounceHorizontal = false
    tableView.alwaysBounceVertical = true
    tableView.showsHorizontalScrollIndicator = false
    tableView.showsVerticalScrollIndicator = true
    tableView.tableFooterView = UIView()
    tableView.dataSource = self as? UITableViewDataSource
    tableView.delegate = self as? UITableViewDelegate
    self.tableView = tableView
  }

  open var tableViewIfLoaded: UITableView? {
    _tableView
  }

  open func tableViewDidLoad() {

  }

  open var isTableViewLoaded: Bool {
    _tableView != nil
  }

  // MARK: Data

  open override func reloadData(_ content: Content?, for page: Int) {
    tableView.reloadData()
  }
}
