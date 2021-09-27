//
//  TaskScrollViewController.swift
//
//  Created by Sereivoan Yong on 2/26/20.
//

import UIKit

/// Subclass must implement these functions:
/// `responseConfiguration`
/// `urlRequest(for:)`
/// `store(_:for:)`
/// `reloadData(_:for:)` (Optional)

open class TaskScrollViewController<Response, Content>: TaskViewController<Response, Content> {

  private var _scrollView: UIScrollView!
  open var scrollView: UIScrollView {
    get {
      if _scrollView == nil {
        loadScrollView()
        scrollViewDidLoad()
      }
      return _scrollView
    }
    set {
      precondition(_scrollView == nil, "Scroll view can only be set before it is loaded.")
      _scrollView = newValue
    }
  }

  open override var refreshingScrollView: UIScrollView? {
    scrollView
  }

  // MARK: View Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    scrollView.frame = view.bounds
    scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(scrollView)
  }

  // MARK: Scroll View Lifecycle

  open func loadScrollView() {
    let scrollView = UIScrollView(frame: UIScreen.main.bounds)
    scrollView.preservesSuperviewLayoutMargins = true
    scrollView.alwaysBounceHorizontal = false
    scrollView.alwaysBounceVertical = true
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = true
    scrollView.delegate = self as? UIScrollViewDelegate
    self.scrollView = scrollView
  }

  open var scrollViewIfLoaded: UIScrollView? {
    _scrollView
  }

  open func scrollViewDidLoad() {

  }

  open var isScrollViewLoaded: Bool {
    _scrollView != nil
  }
}
