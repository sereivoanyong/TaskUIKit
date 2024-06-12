//
//  TaskScrollViewController.swift
//
//  Created by Sereivoan Yong on 2/26/20.
//

import UIKit

/// Subclass must implement these functions:
/// `startTasks(page:cancellables:completion:)`
/// `applyData(_:page:)`
open class TaskScrollViewController<Contents>: TaskViewController<Contents> {

  private var _scrollView: UIScrollView!

  /// `loadScrollView()` is not called if we assign it from nib
  @IBOutlet open weak var scrollView: UIScrollView! {
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
      scrollViewDidLoad()
    }
  }

  open override var refreshingScrollView: UIScrollView? {
    return scrollView
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
    return _scrollView
  }

  open func scrollViewDidLoad() {
  }

  open var isScrollViewLoaded: Bool {
    return _scrollView != nil
  }

  // MARK: View Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    if scrollView.superview == nil {
      scrollView.frame = view.bounds
      scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.insertSubview(scrollView, at: 0)
    }
  }
}
