//
//  GPSelectionViewController.swift
//  MobileAPISampleApp
//
//  Created by Eric Hyche on 10/24/17.
//  Copyright © 2017 Groupon, Inc. All rights reserved.
//

import UIKit

class GPSelectionTableViewCell: UITableViewCell {
    static let reuseID = "GPSelectionTableViewCell"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

typealias GPSelectionDidChangeClosure = (Int) -> Void

class GPSelectionViewController: UITableViewController {

    public let choices: [OperationParameterValue]
    private(set) public var selectedIndex: Int
    private let autoPopOnSelectionChange: Bool
    public var onSelectionChanged: GPSelectionDidChangeClosure?

    init(title: String, choices: [OperationParameterValue], selectedIndex: Int, autoPopOnSelectionChange: Bool) {
        self.choices = choices
        self.selectedIndex = selectedIndex
        self.autoPopOnSelectionChange = autoPopOnSelectionChange
        super.init(style: .plain)

        navigationItem.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(GPSelectionTableViewCell.self, forCellReuseIdentifier: GPSelectionTableViewCell.reuseID)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GPSelectionTableViewCell.reuseID, for: indexPath)

        guard indexPath.row < choices.count else {
            return cell
        }

        cell.textLabel?.text = choices[indexPath.row].description
        cell.accessoryType = (indexPath.row == selectedIndex ? .checkmark : .none)

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.row < choices.count else {
            return
        }

        guard indexPath.row != selectedIndex else {
            return
        }

        let oldIndexPath = IndexPath(row: selectedIndex, section: 0)
        let newIndexPath = IndexPath(row: indexPath.row, section: 0)

        // Update the selected index
        selectedIndex = indexPath.row

        // Reload the old and new rows
        tableView.reloadRows(at: [oldIndexPath, newIndexPath], with: .automatic)

        // Call the selection did change closure
        onSelectionChanged?(selectedIndex)

        // If we are supposed to auto-pop, then do so
        if autoPopOnSelectionChange {
            navigationController?.popViewController(animated: true)
        }
    }

}
