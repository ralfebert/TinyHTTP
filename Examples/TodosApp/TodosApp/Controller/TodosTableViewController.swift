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

import TinyHTTP
import UIKit

private let cellReuseIdentifier = "LabelCell"

class TodosTableViewController: UITableViewController, EndpointLoading {

    let todosAPI = TodosAPI.shared
    let allTodosEndpoint = TodosAPI.shared.allTodos
    var todos = [Todo]()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupViews()

        observe(endpoint: self.allTodosEndpoint) { todos in
            self.todos = todos
            self.tableView.reloadData()
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.allTodosEndpoint.loadIfNeeded()
    }

    // MARK: - Additional UI

    private func setupViews() {
        self.setupNavigation()
        self.setupTableView()
        self.setupRefreshControl()
        self.setupAddButton()
    }

    private func setupNavigation() {
        self.navigationItem.title = "Todos"
    }

    private func setupTableView() {
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }

    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.loadTodos), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
    }

    private func setupAddButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.add))
    }

    // MARK: - Loading

    @objc private func loadTodos() {
        self.allTodosEndpoint.load()
    }

    // MARK: - Editing

    @objc private func add() {
        self.edit(todo: Todo())
    }

    fileprivate func edit(todo: Todo) {
        let alertController = UIAlertController(title: "Todo", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = todo.title
        }
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            var editedTodo = todo
            editedTodo.title = alertController.textFields?.first?.text ?? ""

            self.load(endpoint: self.todosAPI.put(todo: editedTodo)) { [weak self] _ in
                self?.loadTodos()
            }
        }))
        self.present(alertController, animated: true)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.todos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)

        let todo = self.todos[indexPath.row]
        cell.textLabel?.text = todo.title

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let todo = self.todos[indexPath.row]
            self.load(endpoint: self.todosAPI.delete(todo: todo)) { [weak self] _ in
                self?.loadTodos()
            }
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let todo = self.todos[indexPath.row]
        self.edit(todo: todo)
    }

}
