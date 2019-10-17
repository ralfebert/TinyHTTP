# TinyHTTP

TinyHTTP is minimalistic abstraction for making network calls with URLSession designed for making JSON/REST calls in iOS apps in a controller-owned-networking style design.

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
    
    // JSONDecoder is declared manually so you can configure it however needed for the API
    private let jsonDecoder = JSONDecoder()

    // The easiest way to share a common API instance is to use a `shared` singleton
    static let shared = TodosAPI()
    private init() {}

    func get() -> Endpoint<[Todo]> {
        
        // TinyHTTP provides extensions for common tasks around configuring a URLRequest:
        var request = URLRequest(method: .get, url: self.url)
        request.httpAccept(.json)
        
        // pass in any function to decode the response to the actual type
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

## UIKit convenience - Making calls in UIViewController classes

To make calls from a `UIViewController` make the controller conform to the `EndpointLoading` protocol that extends the class with a `load` method that allows to load an endpoint - with a proper default behavior for activity indication and error handling. For example:

```swift
import UIKit
import TinyHTTP

class TodosTableViewController: UITableViewController, EndpointLoading {

    var todos = [Todo]()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Todos"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LabelCell")

        self.load(endpoint: TodosAPI.shared.get()) { (todos) in
            self.todos = todos
            self.tableView.reloadData()
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.todos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)

        let todo = self.todos[indexPath.row]
        cell.textLabel?.text = todo.title

        return cell
    }

}
```

You can configure the app-wide default by setting `EndpointDefaults.defaultActivityIndicator` and `EndpointDefaults.defaultErrorHandler` functions or you can customize it per controller via parameters to the call to load.

## Using the same endpoint from multiple places in the app

A class `StatefulEndpoint` for sharing and observing one endpoint from multiple places in a thread-safe way is provided. You might want to declare it in your API class, f.e.:

```swift
class TodosAPI {

    // ...

    lazy var all: StatefulEndpoint<[Todo]> = {
        return StatefulEndpoint(endpoint: self.get())
    }()

    private func get() -> Endpoint<[Todo]> {
        var request = URLRequest(method: .get, url: self.url)
        request.httpAccept(.json)
        return Endpoint(request: request, decodeResponse: self.jsonDecoder.decodeResponse)
    }
    
}
```

You can observe a stateful endpoint instance:

```swift
TodosAPI.shared.all.observe(owner: self) { (state) in
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

Or use the `EndpointLoading` extension again which provides an `observe(endpoint:)` method which again adds default activity and error handling:

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

## What about other HTTP methods?

Sure thing, here is an example for a typical CRUD REST API:

```
class TodosAPI {

    let url = URL(string: "https://jsonplaceholder.typicode.com/todos/")!
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()

    static let shared = TodosAPI()

    private init() {}

    lazy var all: StatefulEndpoint<[Todo]> = {
        return StatefulEndpoint(endpoint: self.get())
    }()

    private func get() -> Endpoint<[Todo]> {
        var request = URLRequest(method: .get, url: self.url)
        request.httpAccept(.json)
        return Endpoint(request: request, decodeResponse: self.jsonDecoder.decodeResponse)
    }

    func get(id: Int) -> Endpoint<Todo> {
        var request = URLRequest(method: .get, url: urlFor(id: id))
        request.httpAccept(.json)
        return Endpoint(request: request, decodeResponse: self.jsonDecoder.decodeResponse)
    }

    func put(todo: Todo) -> Endpoint<Todo> {

        var request: URLRequest
        if let id = todo.id {
            request = URLRequest(method: .put, url: self.urlFor(id: id))
        } else {
            request = URLRequest(method: .post, url: self.url)
        }
        request.httpAccept(.json)
        request.httpContentType(.json)
        request.httpBody = try! self.jsonEncoder.encode(TodoBody(todo: todo))

        return Endpoint(request: request, decodeResponse: self.jsonDecoder.decodeResponse)
    }

    func delete(todo: Todo) -> Endpoint<Void> {
        var request = URLRequest(method: .delete, url: urlFor(id: todo.id!))
        request.httpAccept(.json)
        return Endpoint(request: request, decodeResponse: EndpointExpectation.ignoreResponse)
    }

    private func urlFor(id: Int) -> URL {
        self.url.appendingRelative(String(id))
    }

}
```


You can use these manually using `URLSession` or call them using the `EndpointLoading` extension again:

```swift
self.load(endpoint: self.todosAPI.delete(todo: todo)) { result in
    print("Todo was deleted")
}
```
