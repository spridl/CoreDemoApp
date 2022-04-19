//
//  TaskListViewController.swift
//  CoreDemoApp
//
//  Created by Alexey Efimov on 18.04.2022.
//

import UIKit

class TaskListViewController: UITableViewController {
    
    private let storageManager = StorageManager.shared
    
    private var taskList: [Task] = []
    private let cellID = "task"
    private var switchAlertConfig = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        view.backgroundColor = .white
        setupNavigationBar()
        fetchData()
    }
    
    private func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(
            red: 21/255,
            green: 101/255,
            blue: 192/255,
            alpha: 194/255
        )
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        navigationController?.navigationBar.tintColor = .white
    }
    
    @objc private func addNewTask() {
        switchAlertConfig = true
        showAlert(with: "New Task", and: "What do you want to do?", andTextField: "")
    }
    
    private func fetchData() {
        let fetchRequest = Task.fetchRequest()
        do {
            taskList = try storageManager.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func showAlert(with title: String, and message: String, andTextField text: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            if self.switchAlertConfig {
                self.save(task)
            } else {
                guard let indexPath = self.tableView.indexPathForSelectedRow else { return }
                self.update(task: self.taskList[indexPath.row], to: task)
            }
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = title
            textField.text = text
        }
        present(alert, animated: true)
    }
    
    private func update(task: Task, to newTaskName: String) {
        guard let index = tableView.indexPathForSelectedRow else { return }
        task.title = newTaskName
        
        tableView.reloadRows(at: [index], with: .automatic)
        storageManager.saveContext()
    }
    
    private func save(_ taskName: String) {
        let task = Task(context: storageManager.persistentContainer.viewContext)
        task.title = taskName
        taskList.append(task)
        
        let cellIndex = IndexPath(row: taskList.count - 1, section: 0)
        tableView.insertRows(at: [cellIndex], with: .automatic)
        storageManager.saveContext()
    }
}

extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let task = taskList[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let text = taskList[indexPath.row].title else { return }
        switchAlertConfig = false
        showAlert(with: "Update Task", and: "What do you want to do?", andTextField: text)
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = taskList[indexPath.row]
            
            taskList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            storageManager.persistentContainer.viewContext.delete(task)
            
            storageManager.saveContext()
        }
    }
}
