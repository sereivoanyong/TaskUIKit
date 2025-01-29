//
//  TaskRealmUIKit.swift
//  TaskRealmUIKit
//
//  Created by Sereivoan Yong on 1/8/25.
//

@_exported import TaskUIKit
@_exported import RealmSwift
import SwiftKit

extension TaskUIKit.Configuration {

  private static var willWriteObjectHandlerKey: Void?
  public var willWriteObjectHandler: ((RealmSwift.Object, TaskUserInfo?, Realm) -> Void)? {
    get { return associatedValue(forKey: &Self.willWriteObjectHandlerKey, with: self) }
    set { setAssociatedValue(newValue, forKey: &Self.willWriteObjectHandlerKey, with: self) }
  }
}

public enum TaskRealmCollectionStore {

  case list
  case results
}

extension NSSortDescriptor {

  public convenience init<T: ObjectBase, Value>(keyPath: KeyPath<T, Value>, ascending: Bool) {
    self.init(key: _name(for: keyPath), ascending: ascending)
  }
}
