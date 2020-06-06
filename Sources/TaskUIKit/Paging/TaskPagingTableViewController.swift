//
//  TaskPagingTableViewController.swift
//
//  Created by Sereivoan Yong on 6/4/20.
//

import UIKit
import SwiftKit
import MJRefresh
import DiffableDataSources
import DZNEmptyDataSet

open class TaskPagingTableViewController<Response, Section, Item>: TaskViewController<Response, [Item]> where Section: Hashable, Item: Hashable {
  
  public typealias DataSource = TableViewDiffableDataSource<Section, Item>
  public typealias DataSourceSnapshot = DiffableDataSourceSnapshot<Section, Item>
  
  open override var pullToRefreshScrollView: UIScrollView? {
    return tableView
  }
  
  private let style: UITableView.Style
  
  lazy open private(set) var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: style)
    switch tableView.style {
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
    tableView.delegate = self as? UITableViewDelegate
    return tableView
  }()
  
  open var cellProvider: DataSource.CellProvider! {
    didSet {
      assert(oldValue == nil && cellProvider != nil, "`cellProvider` can only be set exactly once and before task succeeded.")
    }
  }
  final lazy public private(set) var dataSource: DataSource = defaultDataSource(tableView: tableView, cellProvider: cellProvider)
  
  open var initialPage: Int = 1
  open private(set) var currentPage: Int = 1
  open var hasNextPageProvider: (Response, Int) -> Bool = { response, page in
    if let response = response as? PagingResponse {
      return response.hasNext(page: page)
    }
    return false
  }
  
  open private(set) var items: [Item] = []
  
  // MARK: Init / Deinit
  
  public init(responseTransformer: ResponseTransformer<Response, [Item]>, style: UITableView.Style) {
    self.style = style
    super.init(responseTransformer: responseTransformer)
  }
  
  final public func register<Cell>(_ cellClass: Cell.Type) where Cell: UITableViewCell & ObjectConfigurable, Cell.Object == Item {
    tableView.register(cellClass)
    cellProvider = { tableView, indexPath, item in
      let cell = tableView.dequeue(cellClass, for: indexPath)
      cell.configure(item)
      return cell
    }
  }
  
  // MARK: View Lifecycle
  
  open override func loadView() {
    super.loadView()
    
    tableView.frame = view.bounds
    tableView.autoresizingMask = .flexibleSize
    view.addSubview(tableView)
  }
  
  // MARK: Networking
  
  final public override func urlRequest() -> URLRequest {
    return urlRequest(page: initialPage)
  }
  
  final public override func taskDidComplete(result: Result<(Response, [Item]), Failure>) {
    taskDidComplete(result: result, page: initialPage)
  }
  
  final public override func reloadData(_ newItems: [Item]) {
    reloadData(newItems, page: initialPage)
  }
  
  // Paging
  
  open func urlRequest(page: Int) -> URLRequest {
    fatalError("\(#function) has not been implemented")
  }
  
  final private func startTask(page: Int) {
    assert(page > initialPage)
    taskWillStart()
    startTask(with: urlRequest(page: page), transformer: responseTransformer) { [weak self] result in
      guard let self = self else { return }
      self.taskDidComplete(result: result, page: page)
    }
    taskDidStart()
  }
  
  open func taskDidComplete(result: Result<(Response, [Item]), Failure>, page: Int) {
    switch result {
    case .success(let (response, items)):
      currentPage = page
      let hasNextPage = hasNextPageProvider(response, page)
      if tableView.mj_footer == nil && hasNextPage {
        let footer = MJRefreshAutoNormalFooter() { [unowned self] in
          self.startTask(page: page + 1)
        }
        footer.stateLabel?.isHidden = true
        footer.isRefreshingTitleHidden = true
        tableView.mj_footer = footer
      }
      if let footer = tableView.mj_footer {
        if hasNextPage {
          footer.endRefreshing()
          footer.isHidden = false
        } else {
          footer.endRefreshingWithNoMoreData()
          footer.isHidden = true
        }
      }
      if page == initialPage {
        super.taskDidComplete(result: .success((response, items)))
      } else {
        reloadData(items, page: page)
      }
    case .failure(let failure):
      if page == initialPage {
        super.taskDidComplete(result: .failure(failure))
      }
    }
  }
  
  open func reloadData(_ newItems: [Item], page: Int) {
    if page == initialPage {
      items.removeAll()
      if newItems.isEmpty {
        emptyDataSetAdapter = emptyDataSetAdapterWhenEmpty()
      } else {
        items.append(contentsOf: newItems)
      }
    } else {
      items.append(contentsOf: newItems)
    }
    dataSource.apply(dataSourceSnapshot(newItems, page: page), animatingDifferences: true, completion: nil)
  }
  
  open override func resetData(animated: Bool = false) {
    items.removeAll()
    dataSource.apply(dataSourceSnapshot([], page: initialPage), animatingDifferences: animated, completion: nil)
  }
  
  open func dataSourceSnapshot(_ newItems: [Item], page: Int) -> DataSourceSnapshot {
    precondition(Section.self == AnyHashable.self, "\(#function) must be overriden without calling super if `Section` is not `AnyHashable`")
    var snapshot: DataSourceSnapshot
    if page == initialPage {
      snapshot = DataSourceSnapshot()
      snapshot.appendSections([AnyHashable(0) as! Section])
    } else {
      snapshot = dataSource.snapshot()
    }
    snapshot.appendItems(newItems)
    return snapshot
  }
  
  open func emptyDataSetAdapterWhenEmpty() -> EmptyDataSetAdapter {
    let adapter = EmptyDataSetAdapter(reloadable: self)
    adapter.title = NSAttributedString(string: NSLocalizedString("Nothing is here.", comment: ""), attributes: nil)
    return adapter
  }
  
  open func defaultDataSource(tableView: UITableView, cellProvider: @escaping DataSource.CellProvider) -> DataSource {
    let dataSource = DataSource(tableView: tableView, cellProvider: cellProvider)
    dataSource.defaultRowAnimation = .fade
    return dataSource
  }
}
