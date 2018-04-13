//
//  DictionaryDisplayController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/12/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class DictionaryDisplayController: UITableViewController {

    // MARK: - Private properties

    private struct Entry {
        var name: AnyHashable
        var value: Any
    }
    private var entries = [Entry]()

    // MARK: - Initializers

    init(withDictionary dict: [AnyHashable:Any]) {
        super.init(style: .grouped)
        for (name,value) in dict {
            entries.append(Entry(name: name, value: value))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(GPAPIResponseTableViewCell.self, forCellReuseIdentifier: GPAPIResponseTableViewCell.reuseID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)

        guard indexPath.row < entries.count else {
            return cell
        }

        cell.textLabel?.text = "\(entries[indexPath.row].name)"
        cell.detailTextLabel?.text = "\(entries[indexPath.row].value)"
        cell.accessoryType = .none
        cell.selectionStyle = .none

        return cell
    }

    // MARK: - UITableViewDelegate methods

}
