//
//  ResponseTransformer+JSON.swift
//
//  Created by Sereivoan Yong on 5/11/20.
//

import Foundation
import TaskUIKit
import SwiftyJSON

extension ResponseTransformer where Response == JSON {
  
  public static func json(options: JSONSerialization.ReadingOptions = [], contentsTransform: @escaping (Response) -> Contents) -> Self {
    return ResponseTransformer(responseTransform: { data, _ in try JSON(data: data, options: options) }, contentsTransform: contentsTransform)
  }
  
  public static func json(options: JSONSerialization.ReadingOptions = [], contentsAt keyPath: KeyPath<Response, Contents>) -> Self {
    return json(options: options, contentsTransform: { response in response[keyPath: keyPath] })
  }
}
