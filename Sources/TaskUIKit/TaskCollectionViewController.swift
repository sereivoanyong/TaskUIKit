//
//  TaskCollectionViewController.swift
//
//  Created by Sereivoan Yong on 2/6/20.
//

import UIKit

/// Subclass must implement these functions:
/// `responseConfiguration`
/// `urlRequest(for:)`
/// `store(_:for:)`
/// `reloadData(_:for:)` (Optional)

open class TaskCollectionViewController<Response, Content>: TaskViewController<Response, Content> {

  /// Default is `UICollectionView.self`. Custom class must implement `init(frame:collectionViewLayout:)`.
  open class var collectionViewClass: UICollectionView.Type {
    UICollectionView.self
  }

  /// Default is `UICollectionViewFlowLayout.self`.
  open class var collectionViewLayoutClass: UICollectionViewLayout.Type {
    UICollectionViewFlowLayout.self
  }

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

  public let collectionViewLayout: UICollectionViewLayout

  open override var refreshingScrollView: UIScrollView? {
    collectionView
  }

  // MARK: Initializers

  public init(collectionViewLayout: UICollectionViewLayout) {
    self.collectionViewLayout = collectionViewLayout
    super.init(nibName: nil, bundle: nil)
  }

  public override init(nibName: String?, bundle: Bundle?) {
    self.collectionViewLayout = Self.collectionViewLayoutClass.init()
    super.init(nibName: nibName, bundle: bundle)
  }

  public required init?(coder: NSCoder) {
    self.collectionViewLayout = Self.collectionViewLayoutClass.init()
    super.init(coder: coder)
  }

  // MARK: View Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.frame = view.bounds
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.insertSubview(collectionView, at: 0)
  }

  // MARK: Collection View Lifecycle

  open func loadCollectionView() {
    let collectionView = Self.collectionViewClass.init(frame: UIScreen.main.bounds, collectionViewLayout: collectionViewLayout)
    collectionView.backgroundColor = .clear
    collectionView.preservesSuperviewLayoutMargins = true
    collectionView.alwaysBounceHorizontal = false
    collectionView.alwaysBounceVertical = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.showsVerticalScrollIndicator = true
    collectionView.dataSource = self as? UICollectionViewDataSource
    collectionView.delegate = self as? UICollectionViewDelegate
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

  // MARK: Data

  open override func reloadData(_ content: Content?, for page: Int) {
    collectionView.reloadData()
  }
}
