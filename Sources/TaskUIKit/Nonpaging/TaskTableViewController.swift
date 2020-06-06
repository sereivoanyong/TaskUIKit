//
//  TaskTableViewController.swift
//
//  Created by Sereivoan Yong on 6/5/20.
//

import UIKit
import SwiftKit

open class TaskTableViewController<Response, Item>: TaskViewController<Response, Item> {
  
  open override var pullToRefreshScrollView: UIScrollView? {
    return tableView
  }
  
  public let style: UITableView.Style
  
  lazy open private(set) var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: style)
    switch style {
    case .grouped, .insetGrouped:
      if #available(iOS 13.0, *) {
        tableView.backgroundColor = .systemGroupedBackground
      } else {
        tableView.backgroundColor = .groupTableViewBackground
      }
    case .plain:
      if #available(iOS 13.0, *) {
        tableView.backgroundColor = .systemBackground
      } else {
        tableView.backgroundColor = .white
      }
    default:
      break
    }
    tableView.alwaysBounceHorizontal = false
    tableView.alwaysBounceVertical = true
    tableView.showsHorizontalScrollIndicator = false
    tableView.showsVerticalScrollIndicator = true
    tableView.keyboardDismissMode = .interactive
    tableView.preservesSuperviewLayoutMargins = true
    tableView.tableFooterView = UIView()
    tableView.dataSource = self as? UITableViewDataSource
    tableView.delegate = self as? UITableViewDelegate
    return tableView
  }()
  
  open private(set) var item: Item!
  
  public init(responseTransformer: ResponseTransformer<Response, Item>, style: UITableView.Style) {
    self.style = style
    super.init(responseTransformer: responseTransformer)
  }
  
  // MARK: View Lifecycle
  
  open override func loadView() {
    super.loadView()
    
    tableView.frame = view.bounds
    tableView.autoresizingMask = .flexibleSize
    view.addSubview(tableView)
  }
  
  // MARK: Networking
  
  open override func reloadData(_ newItem: Item) {
    item = newItem
    tableView.reloadData()
  }
  
  open override func resetData(animated: Bool = false) {
    item = nil
    tableView.reloadData()
  }
}
