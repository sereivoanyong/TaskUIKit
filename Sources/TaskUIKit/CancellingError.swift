//
//  CancellingError.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 7/19/24.
//

import Foundation

public protocol CancellingError: Error {

  var isCancelled: Bool { get }
}
