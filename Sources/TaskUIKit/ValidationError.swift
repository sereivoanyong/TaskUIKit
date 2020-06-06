//
//  ValidationError.swift
//
//  Created by Sereivoan Yong on 6/3/20.
//

import Foundation

public struct ValidationError: LocalizedError {
  
  public let response: HTTPURLResponse
  public var localizedDescriptionTransform: (HTTPURLResponse) -> String = { $0._statusCode.localizedString }
  public var description: String?
  
  public var errorDescription: String? {
    return description ?? localizedDescriptionTransform(response)
  }
  
  public init(response: HTTPURLResponse, description: String? = nil) {
    self.response = response
    self.description = description
  }
}
