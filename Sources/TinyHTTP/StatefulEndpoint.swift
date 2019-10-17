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

public class StatefulEndpoint<T: Decodable> {

    public let endpoint: Endpoint<T>
    let urlSession: URLSession

    private(set) var state = LoadingResult.empty {
        didSet {
            self.notifyObservers()
        }
    }

    private var observers = [ResourceObserver]()
    private let lock = NSRecursiveLock()

    public enum LoadingResult: CustomStringConvertible {

        case empty
        case loading(URLSessionTask)
        case success(T)
        case failure(Error)

        public var description: String {
            switch self {
                case .empty: return "empty"
                case .loading: return "loading"
                case let .success(value): return "success(\(type(of: value)))"
                case let .failure(error): return "failure(\(error))"
            }
        }

    }

    public typealias Observer = (LoadingResult) -> Void

    private struct ResourceObserver {
        weak var owner: AnyObject?
        let queue: DispatchQueue
        let observer: Observer
    }

    public init(endpoint: Endpoint<T>, urlSession: URLSession = .shared) {
        self.endpoint = endpoint
        self.urlSession = urlSession
    }

    public func loadIfNeeded() {
        self.lock.synchronized {
            switch state {
                case .loading, .success:
                    return
                case .empty, .failure:
                    let task = createTask()
                    self.state = .loading(task)
                    task.resume()
            }
        }
    }

    public func load() {
        self.lock.synchronized {
            self.clear()
            self.loadIfNeeded()
        }
    }

    private func notifyObservers() {
        self.lock.synchronized {
            os_log("%s state: %s", log: EndpointLogging.log, type: .debug, endpoint.description, state.description)
            self.observers.removeAll { observer in observer.owner == nil }
            for observer in self.observers {
                observer.queue.async {
                    observer.observer(self.state)
                }
            }
        }
    }

    public func clear() {
        self.state = .empty
    }

    public func removeObservers(owner: AnyObject) {
        self.lock.synchronized {
            self.observers.removeAll { observer in observer.owner === owner || observer.owner == nil }
        }
    }

    public func observe(owner: AnyObject, queue: DispatchQueue = .main, observeCurrent: Bool = true, observer: @escaping Observer) {
        self.lock.synchronized {
            if observeCurrent {
                observer(state)
            }
            self.observers.append(ResourceObserver(owner: owner, queue: queue, observer: observer))
            self.loadIfNeeded()
        }
    }

    private func createTask() -> URLSessionTask {
        return self.urlSession.dataTask(endpoint: self.endpoint) { result in
            switch result {
                case let .success(value):
                    self.state = .success(value)
                case let .failure(error):
                    self.state = .failure(error)
            }
        }
    }

    deinit {
        os_log("%s deinit", log: EndpointLogging.log, type: .debug, endpoint.description)
    }

}
