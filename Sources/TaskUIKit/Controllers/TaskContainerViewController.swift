//
//  TaskContainerViewController.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 12/18/24.
//

import UIKitUtilities

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
          currentViewController?.removeFromParentIncludingView()
          addChildIncludingView(newViewController) { view, childView in
            addView(childView, to: view)
          }
        }
      } else {
        viewController?.removeFromParentIncludingView()
        viewController = nil
      }
    } else {
      viewController?.removeFromParentIncludingView()
      viewController = nil
    }
    completion()
  }

  open func viewController(for contents: Contents, reusingViewController: UIViewController?) -> UIViewController? {
    return nil
  }

  open func addView(_ childView: UIView, to view: UIView) {
    childView.frame = view.bounds
    childView.autoresizingMask = .flexibleSize
    view.insertSubview(childView, at: 0)
  }
}
