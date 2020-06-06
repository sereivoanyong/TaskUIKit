//
//  TaskPagingPickerController.swift
//
//  Created by Sereivoan Yong on 6/9/20.
//

import UIKit
import SwiftKit
import DiffableDataSources

open class TaskPagingPickerController<Response, Section, Item>: TaskPagingTableViewController<Response, Section, Item>, UISearchResultsUpdating where Section: Hashable, Item: Hashable {
  
  private var isSelectedRowScrollTo: Bool = false
  
  open private(set) var filteredDataSource: TableViewDiffableDataSource<AnyHashable, Item>?
  
  open var filterHandler: ((Item, String) -> Bool)?
  
  open var selectedItem: Item?
  open var selectionHandler: ((Item) -> Void)?
  
  open var showsSearchController: Bool = false {
    didSet {
      if showsSearchController {
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = defaultSearchController()
      } else {
        navigationItem.searchController = nil
      }
    }
  }
  
  open override func willMove(toParent parent: UIViewController?) {
    if let navigationController = parent as? UINavigationController, navigationController.viewControllers.count == 1 {
      navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismiss(_:)))
    }
    super.willMove(toParent: parent)
  }
  
  #if DEBUG
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    assert(tableView.delegate != nil)
  }
  #endif
  
  open override func reloadData(_ newItems: [Item], page: Int) {
    super.reloadData(newItems, page: page)
    
    if !isSelectedRowScrollTo {
      isSelectedRowScrollTo = true
      if let selectedItem = selectedItem, let indexPath = dataSource.indexPath(for: selectedItem) {
        tableView.layer.removeAllAnimations()
        tableView.layoutIfNeeded()
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
      }
    }
  }
  
  // MARK: UISearchResultsUpdating
  
  open func defaultSearchController() -> UISearchController {
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    return searchController
  }
  
  open func updateSearchResults(for searchController: UISearchController) {
    let searchText = searchController.searchBar.text.nonEmpty?.lowercased() ?? ""
    
    if searchText.isEmpty {
      tableView.dataSource = dataSource
      tableView.reloadData()
      filteredDataSource = nil
    } else {
      guard let filterHandler = filterHandler else {
        fatalError("`filterHandler` must not be nil if `showsSearchController` is true")
      }
      if filteredDataSource == nil {
        filteredDataSource = .init(tableView: tableView, cellProvider: cellProvider)
        filteredDataSource?.defaultRowAnimation = .fade
        tableView.reloadData()
      }
      var snapshot = DiffableDataSourceSnapshot<AnyHashable, Item>()
      snapshot.appendSections([AnyHashable(0)])
      snapshot.appendItems(items.filter { filterHandler($0, searchText) })
      filteredDataSource!.apply(snapshot, animatingDifferences: true)
    }
  }
  
  // MARK: UITableViewDelegate
  
  @objc(tableView:didSelectRowAtIndexPath:)
  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let selectedItem = filteredDataSource?.itemIdentifier(for: indexPath) ?? dataSource.itemIdentifier(for: indexPath)!
    selectionHandler?(selectedItem)
    if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
      navigationController.popViewController(animated: true)
    } else {
      (presentingViewController ?? self).dismiss(animated: true, completion: nil)
    }
  }
}
