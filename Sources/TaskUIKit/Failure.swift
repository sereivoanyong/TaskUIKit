//
//  Failure.swift
//
//  Created by Sereivoan Yong on 9/23/21.
//

import Foundation

/// A failure that is used to give users useful information.
public enum Failure: LocalizedError {

  /// Request failed locally (e.g. no internet connection). Check`URLError.Code` to see all possible errors
  case url(URLError)
  /// Unacceptable response. Currently based on status code (e.g. unauthorized, server busy, not found...).
  case unacceptance(Data, HTTPURLResponse)
  /// Request succeded but failed on validation.
  case validation(Data, HTTPURLResponse, Error)
  /// Request succeded  with valid `statusCode` but response data could not be serialized to `Response`.
  case serialization(Error)

  public var errorDescription: String? {
    switch self {
    case .url(let error):
      return error.localizedDescription
    case .unacceptance(_, let response):
      return HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    case .validation(_, _, let error):
      return error.localizedDescription
    case .serialization(let error):
      return error.localizedDescription
    }
  }
}
