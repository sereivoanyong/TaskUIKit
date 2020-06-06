//
//  TaskScrollViewController.swift
//
//  Created by Sereivoan Yong on 2/26/20.
//

import UIKit
import SwiftKit

open class TaskScrollViewController<Response, Item>: TaskViewController<Response, Item> {
  
  open override var pullToRefreshScrollView: UIScrollView? {
    return scrollView
  }
  
  lazy open private(set) var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    if #available(iOS 13.0, *) {
      scrollView.backgroundColor = .systemBackground
    } else {
      scrollView.backgroundColor = .white
    }
    scrollView.alwaysBounceHorizontal = false
    scrollView.alwaysBounceVertical = true
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = true
    scrollView.keyboardDismissMode = .interactive
    scrollView.preservesSuperviewLayoutMargins = true
    return scrollView
  }()
  
  open private(set) var item: Item!
  
  // MARK: View Lifecycle
  
  open override func loadView() {
    super.loadView()
    
    scrollView.frame = view.bounds
    scrollView.autoresizingMask = .flexibleSize
    view.addSubview(scrollView)
  }
  
  // MARK: Networking
  
  open override func reloadData(_ newItem: Item) {
    item = newItem
  }
  
  open override func resetData(animated: Bool = false) {
    item = nil
  }
}
