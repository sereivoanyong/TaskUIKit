//
//  TaskTableViewController.swift
//
//  Created by Sereivoan Yong on 6/5/20.
//

import UIKit

/// Subclass must implement these functions:
/// `startTasks(page:completion:)`
/// `contents`
/// `store(_:page:)`
open class TaskTableViewController<Contents>: TaskViewController<Contents> {

  /// Default is `UITableView.self`. Custom class must implement `init(frame:style:)`.
  open class var tableViewClass: UITableView.Type {
    return UITableView.self
  }

  /// Default is `.plain`.
  open class var style: UITableView.Style {
    return .plain
  }

  private var _tableView: UITableView!
  @IBOutlet open weak var tableView: UITableView! {
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

  private var _style: UITableView.Style!
  open var style: UITableView.Style {
    if let _style {
      return _style
    }
    if let _tableView {
      _style = _tableView.style
    } else {
      _style = Self.style
    }
    return _style
  }

  open override var refreshingScrollView: UIScrollView? {
    return tableView
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
    tableView.prefetchDataSource = self as? UITableViewDataSourcePrefetching
    tableView.dragDelegate = self as? UITableViewDragDelegate
    tableView.dropDelegate = self as? UITableViewDropDelegate
    self.tableView = tableView
  }

  open var tableViewIfLoaded: UITableView? {
    return _tableView
  }

  open func tableViewDidLoad() {
  }

  open var isTableViewLoaded: Bool {
    return _tableView != nil
  }

  // MARK: View Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    if tableView.superview == nil {
      tableView.frame = view.bounds
      tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.insertSubview(tableView, at: 0)
    }
  }

  // MARK: Data

  open override func reloadData(_ contents: Contents?, page: Int?) {
    tableView.reloadData()
  }
}
