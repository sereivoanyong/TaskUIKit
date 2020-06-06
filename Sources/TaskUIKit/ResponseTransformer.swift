//
//  ResponseTransformer.swift
//
//  Created by Sereivoan Yong on 5/11/20.
//

import Foundation

public struct ResponseTransformer<Response, Contents> {
  
  private let responseTransform: (Data, HTTPURLResponse) throws -> Response
  private let contentsTransform: (Response) -> Contents
  
  public init(responseTransform: @escaping (Data, HTTPURLResponse) throws -> Response, contentsTransform: @escaping (Response) -> Contents) {
    self.responseTransform = responseTransform
    self.contentsTransform = contentsTransform
  }
  
  public func transform(_ data: Data, _ response: HTTPURLResponse) throws -> (Response, Contents) {
    let response = try responseTransform(data, response)
    let contents = contentsTransform(response)
    return (response, contents)
  }
}

extension ResponseTransformer where Response: Decodable {
  
  public static func decoded(by decoder: JSONDecoder, contentsTransform: @escaping (Response) -> Contents) -> Self {
    return ResponseTransformer(responseTransform: { data, _ in try decoder.decode(Response.self, from: data) }, contentsTransform: contentsTransform)
  }
  
  public static func decoded(by decoder: JSONDecoder, contentsAt keyPath: KeyPath<Response, Contents>) -> Self {
    return decoded(by: decoder, contentsTransform: { response in response[keyPath: keyPath] })
  }
}

public protocol PagingResponse {
  
  func hasNext(page: Int) -> Bool
}
