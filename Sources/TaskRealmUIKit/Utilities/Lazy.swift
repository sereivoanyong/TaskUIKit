//
//  Lazy.swift
//  TaskUIKit
//
//  Created by Sereivoan Yong on 2/12/25.
//

public enum Lazy<Value> {

  case uninitialized
  case initialized(Value)

  public mutating func value(or provider: @autoclosure () -> Value) -> Value {
    switch self {
    case .uninitialized:
      let value = provider()
      self = .initialized(value)
      return value
    case .initialized(let value):
      return value
    }
  }
}
