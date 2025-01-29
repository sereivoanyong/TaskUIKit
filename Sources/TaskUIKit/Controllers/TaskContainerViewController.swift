//
//  TaskContainerViewController.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 12/18/24.
//

import UIKit

open class TaskContainerViewController<Contents>: TaskViewController<Contents> {

  open private(set) var viewController: UIViewController?

  private var _contents: Contents?
  open override var contents: Contents? {
    get { return _contents }
    set { _contents = newValue }
  }

  open override func applyData(_ contents: SourcedContents, completion: @escaping () -> Void) {
    _contents = contents.contents
    if !isNilOrEmpty(contents.contents) {
      let currentViewController = viewController
      if let newViewController = viewController(for: contents.contents, reusingViewController: currentViewController) {
        viewController = newViewController
        if newViewController != currentViewController {
          currentViewController?.remove()

          addChild(newViewController)
          addView(newViewController.view, to: view)
          newViewController.didMove(toParent: self)
        }
      } else {
        viewController?.remove()
        viewController = nil
      }
    } else {
      viewController?.remove()
      viewController = nil
    }
    completion()
  }

  open func viewController(for contents: Contents, reusingViewController: UIViewController?) -> UIViewController? {
    return nil
  }

  open func addView(_ childView: UIView, to view: UIView) {
    childView.frame = view.bounds
    childView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.insertSubview(childView, at: 0)
  }
}

extension UIViewController {

  fileprivate func remove() {
    willMove(toParent: nil)
    view.removeFromSuperview()
    removeFromParent()
  }
}
