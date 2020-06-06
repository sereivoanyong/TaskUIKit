//
//  TaskCollectionViewController.swift
//
//  Created by Sereivoan Yong on 2/6/20.
//

import UIKit
import SwiftKit

open class TaskCollectionViewController<Response, Item>: TaskViewController<Response, Item> {
  
  open override var pullToRefreshScrollView: UIScrollView? {
    return collectionView
  }
  
  public let collectionViewLayout: UICollectionViewLayout
  
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
    collectionView.dataSource = self as? UICollectionViewDataSource
    collectionView.delegate = self as? UICollectionViewDelegate
    return collectionView
  }()
  
  open private(set) var item: Item!
  
  public init(responseTransformer: ResponseTransformer<Response, Item>, collectionViewLayout: UICollectionViewLayout) {
    self.collectionViewLayout = collectionViewLayout
    super.init(responseTransformer: responseTransformer)
  }
  
  // MARK: View Lifecycle
  
  open override func loadView() {
    super.loadView()
    
    collectionView.frame = view.bounds
    collectionView.autoresizingMask = .flexibleSize
    view.addSubview(collectionView)
  }
  
  // MARK: Networking
  
  open override func reloadData(_ newItem: Item) {
    item = newItem
    collectionView.reloadData()
  }
  
  open override func resetData(animated: Bool = false) {
    item = nil
    collectionView.reloadData()
  }
}
