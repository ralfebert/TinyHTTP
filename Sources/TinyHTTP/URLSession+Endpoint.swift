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

extension URLSession {

    public func dataTask<T>(endpoint: Endpoint<T>, completionHandler: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask {

        os_log("Created URLSessionTask for %s", log: EndpointLogging.log, type: .debug, endpoint.description)

        return self.dataTask(with: endpoint.request) { data, response, error in

            os_log("Got response for %s - %i bytes", log: EndpointLogging.log, type: .debug, endpoint.description, data?.count ?? 0)

            if let error = error {
                completionHandler(.failure(error))
                return
            }

            guard let response = response as? HTTPURLResponse else {
                completionHandler(.failure(EndpointError.notAHttpResponse))
                return
            }

            do {
                try endpoint.validateResponse(response)
                completionHandler(.success(try endpoint.decodeResponse(data, response)))
            } catch {
                completionHandler(.failure(error))
                return
            }
        }
    }

}
