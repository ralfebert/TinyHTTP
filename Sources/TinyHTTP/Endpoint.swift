// MIT License
//
// Copyright (c) 2019 Ralf Ebert
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import os

struct EndpointLogging {

    static let log = OSLog(subsystem: "URLSession.Endpoints", category: "Endpoints")

}

public struct Endpoint<T>: CustomStringConvertible {

    public typealias ValidateResponse = (HTTPURLResponse) throws -> Void
    public typealias DecodeResponse = (_ data: Data?, _ response: HTTPURLResponse) throws -> T

    public var request: URLRequest
    public var validateResponse: ValidateResponse
    public var decodeResponse: DecodeResponse

    public init(request: URLRequest, validateResponse: @escaping ValidateResponse = EndpointExpectation.successStatusCode, decodeResponse: @escaping DecodeResponse) {
        self.request = request
        self.validateResponse = validateResponse
        self.decodeResponse = decodeResponse
    }

    public var description: String {
        "[\(self.request.httpMethod ?? "") \(self.request.url?.absoluteString ?? "")]"
    }

}

public struct EndpointExpectation {

    public static func successStatusCode(response: HTTPURLResponse) throws {
        let code = response.statusCode
        guard (200 ..< 300).contains(code) else {
            throw EndpointError.httpStatusErrorCode(code: code)
        }
    }

    public static func emptyResponse(_ data: Data?, _: HTTPURLResponse) throws {
        guard let data = data else { return }
        guard data.count == 0 else { throw EndpointError.invalidResponse }
    }

    public static func ignoreResponse(_: Data?, _: HTTPURLResponse) throws {}

}

public enum EndpointError: Error {
    case notAHttpResponse
    case noData
    case httpStatusErrorCode(code: Int)
    case invalidResponse
}
