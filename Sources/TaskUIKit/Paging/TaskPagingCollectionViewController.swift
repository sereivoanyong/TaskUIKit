//
//  TaskPagingCollectionViewController.swift
//
//  Created by Sereivoan Yong on 6/2/20.
//

import UIKit
import SwiftKit
import MJRefresh
import DiffableDataSources
import DZNEmptyDataSet

open class TaskPagingCollectionViewController<Response, Section, Item>: TaskViewController<Response, [Item]> where Section: Hashable, Item: Hashable {
  
  public typealias DataSource = CollectionViewDiffableDataSource<Section, Item>
  public typealias DataSourceSnapshot = DiffableDataSourceSnapshot<Section, Item>
  
  open override var pullToRefreshScrollView: UIScrollView? {
    return collectionView
  }
  
  private let collectionViewLayout: UICollectionViewLayout
  
  lazy open private(set) var collectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    if #available(iOS 13.0, *) {
      collectionView.backgroundColor = .systemBackground
    } else {
      collectionView.backgroundColor = .white
    }
    collectionView.alwaysBounceHorizontal = false
    collectionView.alwaysBounceVertical = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.showsVerticalScrollIndicator = true
    collectionView.keyboardDismissMode = .interactive
    collectionView.preservesSuperviewLayoutMargins = true
    collectionView.isPrefetchingEnabled = false
    collectionView.delegate = self as? UICollectionViewDelegate
    return collectionView
  }()
  
  open var cellProvider: DataSource.CellProvider! {
    didSet {
      assert(oldValue == nil && cellProvider != nil, "`cellProvider` can only be set exactly once and before task succeeded.")
    }
  }
  final lazy public private(set) var dataSource: DataSource = defaultDataSource(collectionView: collectionView, cellProvider: cellProvider)
  
  open var initialPage: Int = 1
  open private(set) var currentPage: Int
  open var hasNextPageProvider: (Response, Int) -> Bool = { response, page in
    if let response = response as? PagingResponse {
      return response.hasNext(page: page)
    }
    return false
  }
  
  open private(set) var items: [Item] = []
  
  // MARK: Init / Deinit
  
  public init(responseTransformer: ResponseTransformer<Response, [Item]>, collectionViewLayout: UICollectionViewLayout) {
    self.collectionViewLayout = collectionViewLayout
    currentPage = initialPage
    super.init(responseTransformer: responseTransformer)
  }
  
  final public func register<Cell>(_ cellClass: Cell.Type) where Cell: UICollectionViewCell & ObjectConfigurable, Cell.Object == Item {
    collectionView.register(cellClass)
    cellProvider = { collectionView, indexPath, item in
      let cell = collectionView.dequeue(cellClass, for: indexPath)
      cell.configure(item)
      return cell
    }
  }
  
  // MARK: View Lifecycle
  
  open override func loadView() {
    super.loadView()
    
    collectionView.frame = view.bounds
    collectionView.autoresizingMask = .flexibleSize
    view.addSubview(collectionView)
  }
  
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    collectionViewLayout.invalidateLayout()
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
      if collectionView.mj_footer == nil && hasNextPage {
        let footer = MJRefreshAutoNormalFooter() { [unowned self] in
          self.startTask(page: page + 1)
        }
        footer.stateLabel?.isHidden = true
        footer.isRefreshingTitleHidden = true
        collectionView.mj_footer = footer
      }
      if let footer = collectionView.mj_footer {
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
    let adapter = EmptyDataSetAdapter()
    adapter.title = NSAttributedString(string: NSLocalizedString("Nothing is here.", comment: ""), attributes: nil)
    return adapter
  }
  
  open func defaultDataSource(collectionView: UICollectionView, cellProvider: @escaping DataSource.CellProvider) -> DataSource {
    return DataSource(collectionView: collectionView, cellProvider: cellProvider)
  }
}
