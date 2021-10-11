//
//  ResponseConfiguration.swift
//
//  Created by Sereivoan Yong on 5/11/20.
//

import Foundation

public struct ResponseConfiguration<Response, Content> {

  public let transform: (Data, HTTPURLResponse) throws -> Response
  public let contentProvider: (Response) -> Content
  public let pagingProvider: (Response) -> PagingProtocol?

  public var acceptableStatusCodes: Range<Int> = 200..<300

  public init(transform: @escaping (Data, HTTPURLResponse) throws -> Response, contentProvider: @escaping (Response) -> Content, pagingProvider: @escaping (Response) -> PagingProtocol? = { _ in nil }) {
    self.transform = transform
    self.contentProvider = contentProvider
    self.pagingProvider = pagingProvider
  }

  public init(decoder: JSONDecoder, contentProvider: @escaping (Response) -> Content, pagingProvider: @escaping (Response) -> PagingProtocol? = { _ in nil }) where Response: Decodable {
    self.init(transform:  { data, _ in try decoder.decode(Response.self, from: data) }, contentProvider: contentProvider, pagingProvider: pagingProvider)
  }

  public init<Paging: PagingProtocol>(decoder: JSONDecoder, contentAt contentKeyPath: KeyPath<Response, Content>, pagingAt pagingKeyPath: KeyPath<Response, Paging?>) where Response: Decodable {
    self.init(transform:  { data, _ in try decoder.decode(Response.self, from: data) }, contentProvider: { $0[keyPath: contentKeyPath] }, pagingProvider: { $0[keyPath: pagingKeyPath] })
  }

  public func response(_ data: Data, _ response: HTTPURLResponse) throws -> Response {
    try transform(data, response)
  }
}
