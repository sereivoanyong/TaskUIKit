//
//  EmptyDataSetAdapter.swift
//
//  Created by Sereivoan Yong on 2/4/20.
//

import UIKit
import DZNEmptyDataSet

extension UIControl.State: Hashable {
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public typealias DZNEmptyDataSetAdapter = DZNEmptyDataSetSource & DZNEmptyDataSetDelegate

open class EmptyDataSetAdapter: NSObject {
  
  open var title: NSAttributedString?
  open var description_: NSAttributedString?
  open var image: UIImage?
  open var imageTintColor: UIColor?
  open var imageAnimation: CAAnimation?
  open var buttonTitles: [UIControl.State: NSAttributedString]?
  open var buttonImages: [UIControl.State: UIImage]?
  open var buttonBackgroundImages: [UIControl.State: UIImage]?
  open var backgroundColor: UIColor?
  open var customView: UIView?
  open var verticalOffset: CGFloat?
  open var spaceHeight: CGFloat?
  
  open var shouldFadeIn: Bool?
  open var shouldBeForcedToDisplay: Bool?
  open var shouldDisplay: Bool?
  open var shouldAllowTouch: Bool?
  open var shouldAllowScroll: Bool?
  open var shouldAnimateImageView: Bool?
  open var viewActionHandler: ((UIView) -> Void)?
  open var buttonActionHandler: ((UIButton) -> Void)?
  open var willAppear: (() -> Void)?
  open var didAppear: (() -> Void)?
  open var willDisappear: (() -> Void)?
  open var didDisappear: (() -> Void)?
}

extension EmptyDataSetAdapter: DZNEmptyDataSetSource {
  
  open func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    return title
  }
  
  open func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    return description_
  }
  
  open func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
    return image
  }
  
  open func imageTintColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
    return imageTintColor
  }
  
  open func imageAnimation(forEmptyDataSet scrollView: UIScrollView) -> CAAnimation? {
    return imageAnimation
  }
  
  open func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
    return buttonTitles?[state]
  }
  
  open func buttonImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> UIImage? {
    return buttonImages?[state]
  }
  
  open func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> UIImage? {
    return buttonBackgroundImages?[state]
  }
  
  open func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
    return backgroundColor
  }
  
  open func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
    return customView
  }
  
  open func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
    return verticalOffset ?? 0.0
  }
  
  open func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
    return spaceHeight ?? 11.0
  }
}

extension EmptyDataSetAdapter: DZNEmptyDataSetDelegate {
  
  open func emptyDataSetShouldFadeIn(_ scrollView: UIScrollView) -> Bool {
    return shouldFadeIn ?? true
  }
  
  open func emptyDataSetShouldBeForcedToDisplay(_ scrollView: UIScrollView) -> Bool {
    return shouldBeForcedToDisplay ?? false
  }
  
  open func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
    return shouldDisplay ?? true
  }
  
  open func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
    return shouldAllowTouch ?? true
  }
  
  open func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
    return shouldAllowScroll ?? false
  }
  
  open func emptyDataSetShouldAnimateImageView(_ scrollView: UIScrollView) -> Bool {
    return shouldAnimateImageView ?? false
  }
  
  open func emptyDataSet(_ scrollView: UIScrollView, didTap view: UIView) {
    viewActionHandler?(view)
  }
  
  open func emptyDataSet(_ scrollView: UIScrollView, didTap button: UIButton) {
    buttonActionHandler?(button)
  }
  
  open func emptyDataSetWillAppear(_ scrollView: UIScrollView) {
    willAppear?()
  }
  
  open func emptyDataSetDidAppear(_ scrollView: UIScrollView) {
    didAppear?()
  }
  
  open func emptyDataSetWillDisappear(_ scrollView: UIScrollView) {
    willDisappear?()
  }
  
  open func emptyDataSetDidDisappear(_ scrollView: UIScrollView) {
    didDisappear?()
  }
}
