//
//  TaskCollectionViewController.swift
//
//  Created by Sereivoan Yong on 3/1/22.
//

import UIKit

/// Subclass must implement these functions:
/// `startTasks(page:cancellables:completion:)`
/// `applyData(_:page:)`
open class TaskCollectionViewController<Contents>: TaskViewController<Contents> {

  private var _collectionView: UICollectionView!

  /// `loadCollectionView()` and `makeCollectionViewLayout()` are not called if we assign it from nib
  @IBOutlet open weak var collectionView: UICollectionView! {
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
      collectionViewDidLoad()
    }
  }

  private var _collectionViewLayout: UICollectionViewLayout!
  open var collectionViewLayout: UICollectionViewLayout {
    if let _collectionViewLayout {
      return _collectionViewLayout
    }
    if let _collectionView {
      _collectionViewLayout = _collectionView.collectionViewLayout
    } else {
      _collectionViewLayout = makeCollectionViewLayout()
    }
    return _collectionViewLayout
  }

  open override var refreshingScrollView: UIScrollView? {
    return collectionView
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
    return _collectionView
  }

  open func collectionViewDidLoad() {
  }

  open var isCollectionViewLoaded: Bool {
    return _collectionView != nil
  }

  // MARK: View Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    if collectionView.superview == nil {
      collectionView.frame = view.bounds
      collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.insertSubview(collectionView, at: 0)
    }
  }
}
