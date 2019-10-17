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
import TinyHTTP

struct Todo: Codable {
    var id: Int?
    var title: String?
}

struct TodoBody: Codable {
    let todo: Todo
}

class TodosAPI {

    let url = URL(string: "https://jsonplaceholder.typicode.com/todos/")!
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()

    static let shared = TodosAPI()

    private init() {}

    lazy var all: StatefulEndpoint<[Todo]> = {
        StatefulEndpoint(endpoint: self.get())
    }()

    private func get() -> Endpoint<[Todo]> {
        var request = URLRequest(method: .get, url: self.url)
        request.setHeaderAccept(.json)
        return Endpoint(request: request, decodeResponse: self.jsonDecoder.decodeResponse)
    }

    func get(id: Int) -> Endpoint<Todo> {
        var request = URLRequest(method: .get, url: urlFor(id: id))
        request.setHeaderAccept(.json)
        return Endpoint(request: request, decodeResponse: self.jsonDecoder.decodeResponse)
    }

    func put(todo: Todo) -> Endpoint<Todo> {
        var request: URLRequest
        if let id = todo.id {
            request = URLRequest(method: .put, url: self.urlFor(id: id))
        } else {
            request = URLRequest(method: .post, url: self.url)
        }
        request.setHeaderAccept(.json)
        request.setHeaderContentType(.json)
        request.httpBody = try! self.jsonEncoder.encode(TodoBody(todo: todo))

        return Endpoint(request: request, decodeResponse: self.jsonDecoder.decodeResponse)
    }

    func delete(todo: Todo) -> Endpoint<Void> {
        var request = URLRequest(method: .delete, url: urlFor(id: todo.id!))
        request.setHeaderAccept(.json)
        return Endpoint(request: request, decodeResponse: EndpointExpectation.ignoreResponse)
    }

    private func urlFor(id: Int) -> URL {
        self.url.appendingRelative(String(id))
    }

}
