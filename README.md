# TinyHTTP

TinyHTTP is lightweight library for making network calls with URLSession. Its designed to make JSON/REST calls in iOS apps in a controller-owned-networking style easy and straightforward. It comes with an UIKit integration that provides customizable defaults for common tasks like activity indication and error handling out of the box:

<img src="https://raw.githubusercontent.com/ralfebert/TinyHTTP/master/Docs/todos-loading.png" width="250">

It's very lightweight and simple and it will stay that way (less that 1000 lines of code).

Available via Swift Package Manager at the following clone URL:

```
https://github.com/ralfebert/TinyHTTP.git
```

The easiest way to try it out is to clone the repository and run the example project from `Examples/TodosApp/TodosApp.xcodeproj` (please note that the jsonplaceholder.com API that's used for the example doesn't persist your changes).

Inspired by [TinyNetworking](https://github.com/objcio/tiny-networking) and [Siesta](https://bustoutsolutions.github.io/siesta/).

## Declaring API endpoints

TinyHTTP comes with a type `Endpoint` for describing a request and how the response is decoded.
Let's say you want to make JSON/REST call to your favorite Todos API. Declare a class for the API and declare a method for every endpoint, for example:

```swift
struct Todo: Codable {
    var id: Int?
    var title: String?
}

class TodosAPI {

    private let url = URL(string: "https://jsonplaceholder.typicode.com/todos/")!
    
    private let jsonDecoder = JSONDecoder()

    static let shared = TodosAPI()
    private init() {}

    func get() -> Endpoint<[Todo]> {
        // TinyHTTP provides extensions for common tasks around configuring a URLRequest:
        var request = URLRequest(method: .get, url: self.url)
        request.setHeaderAccept(.json)
        
        // pass in a function to decode the response to the actual type
        // JSONDecoder is extended with a function decodeResponse for easy JSON Codable support:
        return Endpoint(request: request, decodeResponse: self.jsonDecoder.decodeResponse)
    }

}
```

## Making API calls

TinyHTTP provides an extension to `URLSession` to load an endpoint. HTTP status codes are automatically checked, when the response is available, you get called with a Result value:

```swift
let endpoint = TodosAPI.shared.get()
let task = URLSession.shared.dataTask(endpoint: endpoint) { (result) in
    switch(result) {
    case .success(let todos):
        print("Yay, got todos: ", todos)
    case .failure(let error):
        print("Oh no, an error: ", error)
    }
}
task.resume()
```

## UIKit integration - Making calls in UIViewController classes

To make calls from a `UIViewController` make the controller conform to the `EndpointLoading` protocol that extends the class with a `load` method that allows to load an endpoint - with a default behavior for activity indication and error handling. For example:

```swift
import UIKit
import TinyHTTP

class TodosTableViewController: UITableViewController, EndpointLoading {

    var todos = [Todo]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.load(endpoint: TodosAPI.shared.get()) { (todos) in
            self.todos = todos
            self.tableView.reloadData()
        }
    }

    // ...

}
```

You can configure the app-wide default by setting `EndpointDefaults.defaultActivityIndicator` and `EndpointDefaults.defaultErrorHandler` functions or you can customize it per controller via parameters to the call to load.

## Using the same endpoint from multiple places in the app

`StatefulEndpoint` allows to share and observe an endpoint from multiple places in a thread-safe way. You might want to declare it in your API class, f.e.:

```swift
class TodosAPI {

    // ...

    lazy var allTodos: StatefulEndpoint<[Todo]> = {
        return StatefulEndpoint(endpoint: self.get())
    }()

    private func get() -> Endpoint<[Todo]> {
        var request = URLRequest(method: .get, url: self.url)
        request.setHeaderAccept(.json)
        return Endpoint(request: request, decodeResponse: self.jsonDecoder.decodeResponse)
    }
    
}
```

You can observe a stateful endpoint instance:

```swift
TodosAPI.shared.allTodos.observe(owner: self) { (state) in
    switch(state) {
    case .empty:
        print("not yet")
    case .loading(_):
        print("loading")
    case .success(let todos):
        print("got todos: ", todos)
    case .failure(let error):
        print("oh no: ", error)
    }
}
```

Or use the `EndpointLoading` extension which provides an `observe(endpoint:)` method which again adds default activity and error handling:

```swift
class TodosTableViewController: UITableViewController, EndpointLoading {

    // ...
    let todosResource = TodosAPI.shared.all

    // ...

    override func viewDidLoad() {
        // ...

        observe(endpoint: self.todosResource) { todos in
            self.todos = todos
            self.tableView.reloadData()
        }

    }

}
```

## Wrapping a full REST API

The example project contains an example for a full typical CRUD REST API, see [TodosAPI.swift](https://github.com/ralfebert/TinyHTTP/blob/master/Examples/TodosApp/TodosApp/API/TodosAPI.swift#L35).
