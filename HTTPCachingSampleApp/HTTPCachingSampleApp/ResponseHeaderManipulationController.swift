//
//  ResponseHeaderManipulationController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/4/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class ResponseHeaderManipulationController: UITableViewController {

    // MARK: - Public properties

    public private(set) var cacheControlHeaderValue: String?
    public private(set) var expiresHeaderValue: String?

    // MARK: - Private properties

    private enum TableViewSection: Int {
        case cacheControlParameters
        case cacheControlHeader
    }

    private enum CacheControlParameters: Int {
        case maxAge
        case maxStale
    }

    private let maxAgeChoices: [OperationParameterValue] = [
        OperationParameterValue.notSent,
        OperationParameterValue.integer(60),
        OperationParameterValue.integer(600),
        OperationParameterValue.integer(3600)
    ]

    private let maxStaleChoices: [OperationParameterValue] = [
        OperationParameterValue.notSent,
        OperationParameterValue.integer(60),
        OperationParameterValue.integer(600),
        OperationParameterValue.integer(3600)
    ]

    private var selectedMaxAgeIndex = 0
    private var selectedMaxStaleIndex = 0

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Alter Response Headers"
        tableView.register(GPAPIParameterTableViewCell.self, forCellReuseIdentifier: GPAPIParameterTableViewCell.reuseID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows = 0

        guard let tableViewSection = TableViewSection(rawValue: section) else {
            return numRows
        }

        switch tableViewSection {
        case .cacheControlParameters: numRows = 2
        case .cacheControlHeader: numRows = 1
        }

        return numRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)

        guard let section = TableViewSection(rawValue: indexPath.section) else {
            return cell
        }

        switch section {
        case .cacheControlParameters:
            if let cacheControlParam = CacheControlParameters(rawValue: indexPath.row) {
                switch cacheControlParam {
                case .maxAge:
                    cell.textLabel?.text = "Max-Age"
                    cell.detailTextLabel?.text = maxAgeChoices[selectedMaxAgeIndex].description
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                case .maxStale:
                    cell.textLabel?.text = "Max-Stale"
                    cell.detailTextLabel?.text = maxStaleChoices[selectedMaxStaleIndex].description
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }
            }
        case .cacheControlHeader:
            var cellText = ""
            if let headerValue = cacheControlHeaderValue {
                cellText = "Cache-Control: \(headerValue)"
            } else {
                cellText = "Not Sent"
            }
            cell.textLabel?.text = cellText
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }

        return cell
    }

    // MARK: - UITableViewDelegate methods

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil

        guard let tableViewSection = TableViewSection(rawValue: section) else {
            return title
        }

        switch tableViewSection {
        case .cacheControlParameters: title = "Cache-Control Response Directives"
        case .cacheControlHeader: title = "Inserted Cache-Control Header"
        }

        return title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = TableViewSection(rawValue: indexPath.section) else {
            return
        }

        switch section {
        case .cacheControlParameters:
            if let cacheControlParam = CacheControlParameters(rawValue: indexPath.row) {
                switch cacheControlParam {
                case .maxAge:
                    let controller = GPSelectionViewController(title: "Max-Age",
                                                               choices: maxAgeChoices,
                                                               selectedIndex: selectedMaxAgeIndex,
                                                               autoPopOnSelectionChange: true)
                    controller.onSelectionChanged = { [weak self] (selectedIndex: Int) in
                        // Update the selected request parameter index
                        self?.selectedMaxAgeIndex = selectedIndex
                        // Update the Cache-Control header
                        self?.updateHeaderValues()
                        // Reload the tableview
                        self?.tableView.reloadData()
                    }
                    navigationController?.pushViewController(controller, animated: true)
                case .maxStale:
                    let controller = GPSelectionViewController(title: "Max-Stale",
                                                               choices: maxStaleChoices,
                                                               selectedIndex: selectedMaxStaleIndex,
                                                               autoPopOnSelectionChange: true)
                    controller.onSelectionChanged = { [weak self] (selectedIndex: Int) in
                        // Update the selected request parameter index
                        self?.selectedMaxStaleIndex = selectedIndex
                        // Update the Cache-Control header
                        self?.updateHeaderValues()
                        // Reload the tableview
                        self?.tableView.reloadData()
                    }
                    navigationController?.pushViewController(controller, animated: true)
                }
            }
        default:
            break
        }
    }

    private func updateHeaderValues() {
        cacheControlHeaderValue = cacheControlValue()
    }

    private func cacheControlValue() -> String? {
        var params = [String]()

        if let maxAge = maxAgeValue() {
            params.append("max-age=\(maxAge)")
        }
        if let maxStale = maxStaleValue() {
            params.append("max-stale=\(maxStale)")
        }

        return (params.isEmpty ? nil : params.joined(separator: ", "))
    }

    private func maxAgeValue() -> Int? {
        var value: Int? = nil

        guard selectedMaxAgeIndex < maxAgeChoices.count else {
            return value
        }

        switch maxAgeChoices[selectedMaxAgeIndex] {
        case .integer(let intValue): value = intValue
        default: break
        }

        return value
    }

    private func maxStaleValue() -> Int? {
        var value: Int? = nil

        guard selectedMaxStaleIndex < maxStaleChoices.count else {
            return value
        }

        switch maxStaleChoices[selectedMaxStaleIndex] {
        case .integer(let intValue): value = intValue
        default: break
        }

        return value
    }

}
