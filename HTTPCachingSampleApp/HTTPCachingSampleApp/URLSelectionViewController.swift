//
//  URLSelectionViewController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/6/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class URLSelectionTableViewCell: UITableViewCell {
    static let reuseID = "URLSelectionTableViewCell"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        textLabel?.numberOfLines = 0
        detailTextLabel?.numberOfLines = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

typealias URLSelectionDidChangeClosure = (Int) -> Void

class URLSelectionViewController: UITableViewController {

    private var urls: [AppDelegate.URLInfo]
    private var selectedURLIndex: Int
    private var onSelectionChanged: URLSelectionDidChangeClosure?

    init(urls: [AppDelegate.URLInfo], selectedURLIndex: Int, onSelectionChanged: URLSelectionDidChangeClosure?) {
        self.urls = urls
        self.selectedURLIndex = selectedURLIndex
        self.onSelectionChanged = onSelectionChanged
        super.init(style: .plain)

        navigationItem.title = "Select URL"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(URLSelectionTableViewCell.self, forCellReuseIdentifier: URLSelectionTableViewCell.reuseID)
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urls.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: URLSelectionTableViewCell.reuseID, for: indexPath)

        guard indexPath.row < urls.count else {
            return cell
        }

        cell.textLabel?.text = urls[indexPath.row].name
        cell.detailTextLabel?.text = urls[indexPath.row].url?.absoluteString
        cell.accessoryType = (indexPath.row == selectedURLIndex ? .checkmark : .none)

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.row < urls.count else {
            return
        }

        guard indexPath.row != selectedURLIndex else {
            return
        }

        let oldIndexPath = IndexPath(row: selectedURLIndex, section: 0)
        let newIndexPath = IndexPath(row: indexPath.row, section: 0)

        // Update the selected index
        selectedURLIndex = indexPath.row

        // Reload the old and new rows
        tableView.reloadRows(at: [oldIndexPath, newIndexPath], with: .automatic)

        // Call the selection did change closure
        onSelectionChanged?(selectedURLIndex)
    }
}
