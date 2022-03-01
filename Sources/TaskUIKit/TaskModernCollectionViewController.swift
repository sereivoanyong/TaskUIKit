//
//  TaskModernCollectionViewController.swift
//
//  Created by Sereivoan Yong on 3/1/22.
//

import UIKit

/// Subclass must implement these functions:
/// `responseConfiguration`
/// `urlRequest(for:)`
/// `store(_:for:)`
/// `reloadData(_:for:)` (Optional)

open class TaskModernCollectionViewController<Response, Content>: TaskViewController<Response, Content> {

  private var _collectionView: UICollectionView!
  open var collectionView: UICollectionView {
    get {
      if _collectionView == nil {
        loadCollectionView()
        collectionViewDidLoad()
      }
      return _collectionView
    }
    set {
      precondition(_collectionView == nil, "Collection view can only be set before it is loaded.")
      _collectionView = newValue
    }
  }

  lazy open private(set) var collectionViewLayout: UICollectionViewLayout = makeCollectionViewLayout()

  open override var refreshingScrollView: UIScrollView? {
    collectionView
  }

  // MARK: Collection View Lifecycle

  open func makeCollectionViewLayout() -> UICollectionViewLayout {
    fatalError()
  }

  open func loadCollectionView() {
    let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: collectionViewLayout)
    collectionView.backgroundColor = .clear
    collectionView.preservesSuperviewLayoutMargins = true
    collectionView.alwaysBounceHorizontal = false
    collectionView.alwaysBounceVertical = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.showsVerticalScrollIndicator = true
    collectionView.dataSource = self as? UICollectionViewDataSource
    collectionView.delegate = self as? UICollectionViewDelegate
    collectionView.prefetchDataSource = self as? UICollectionViewDataSourcePrefetching
    collectionView.dragDelegate = self as? UICollectionViewDragDelegate
    collectionView.dropDelegate = self as? UICollectionViewDropDelegate
    self.collectionView = collectionView
  }

  open var collectionViewIfLoaded: UICollectionView? {
    _collectionView
  }

  open func collectionViewDidLoad() {

  }

  open var isCollectionViewLoaded: Bool {
    _collectionView != nil
  }

  // MARK: View Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.frame = view.bounds
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.insertSubview(collectionView, at: 0)
  }

  // MARK: Data

  open override func reloadData(_ content: Content?, for page: Int) {
    collectionView.reloadData()
  }
}
