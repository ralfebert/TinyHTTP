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
import UIKit

public protocol EndpointLoading: UIViewController {}

public struct EndpointDefaults {

    public static var defaultErrorHandler: (_ controller: UIViewController?) -> ((Error) -> Void) = {
        { controller in
            { error in
                os_log("%s Error: %s", log: EndpointLogging.log, type: .error, String(describing: error))
                if let controller = controller {
                    let alertController = UIAlertController(title: "", message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default))
                    controller.present(alertController, animated: true)
                }
            }
        }
    }()

    public static var defaultActivityIndicator: (_ controller: UIViewController?) -> ActivityIndicator? = {
        { controller in
            if let controller = controller {
                return OverlayActivityIndicator(parentView: controller.view)
            } else {
                return nil
            }
        }
    }()

}

extension EndpointLoading {

    public func load<T>(endpoint: Endpoint<T>, activityIndicator: ActivityIndicator? = nil, onError: ((Error) -> Void)? = nil, onSuccess: @escaping (T) -> Void) {

        let activityIndicator = activityIndicator ?? EndpointDefaults.defaultActivityIndicator(self)
        let onError = onError ?? EndpointDefaults.defaultErrorHandler(self)

        activityIndicator?.startActivity()
        let token = UUID()
        NetworkActivityIndicator.shared.startActivity(token: token)

        let task = URLSession.shared.dataTask(endpoint: endpoint) { result in
            NetworkActivityIndicator.shared.stopActivity(token: token)
            DispatchQueue.main.async {
                activityIndicator?.stopActivity()
                switch result {
                    case let .success(value):
                        onSuccess(value)
                    case let .failure(error):
                        onError(error)
                }
            }
        }
        task.resume()
    }

    public func observe<T>(endpoint: StatefulEndpoint<T>, activityIndicator: ActivityIndicator? = nil, onError: ((Error) -> Void)? = nil, onSuccess: @escaping (T) -> Void) {

        let refreshControl: UIRefreshControl? = (self as? UITableViewController)?.refreshControl

        let activityIndicator = activityIndicator ?? EndpointDefaults.defaultActivityIndicator(self)
        let onError = onError ?? EndpointDefaults.defaultErrorHandler(self)
        let token = UUID()

        endpoint.observe(owner: self) { state in
            if case .loading = state {
                NetworkActivityIndicator.shared.startActivity(token: token)
                if !(refreshControl?.isRefreshing ?? false) {
                    activityIndicator?.startActivity()
                }
            } else {
                NetworkActivityIndicator.shared.stopActivity(token: token)
                refreshControl?.endRefreshing()
                activityIndicator?.stopActivity()
            }

            switch state {
                case .empty:
                    break
                case .loading:
                    break
                case let .success(result):
                    onSuccess(result)
                case let .failure(error):
                    onError(error)
            }

        }
    }

}
