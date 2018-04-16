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

    public private(set) var cacheControlRequestHeaderValue: String?
    public private(set) var cacheControlResponseHeaderValue: String?
    public private(set) var expiresHeaderValue: String?

    // MARK: - Private properties

    private enum TableViewSection: Int {
        case cacheControlRequestParameters
        case cacheControlRequestHeader
        case cacheControlResponseParameters
        case cacheControlResponseHeader
    }
    private static let TableViewSectionCount: Int = 4

    private enum CacheControlRequestParameters: Int {
        case noCache
        case noStore
        case maxAge
        case maxStale
        case minFresh
        case noTransform
        case onlyIfCached
    }
    private static let CacheControlRequestParametersCount: Int = 7
    private var cacheControlRequestSelectedIndex = Array<Int>(repeating: 0, count: ResponseHeaderManipulationController.CacheControlRequestParametersCount)
    private let cacheControlRequestParamNames = [
        "no-cache",
        "no-store",
        "max-age",
        "max-stale",
        "min-fresh",
        "no-transform",
        "only-if-cached"
    ]
    private let cacheControlRequestChoices: [[OperationParameterValue]] = [
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.maxAgeChoices,
        ResponseHeaderManipulationController.maxStaleChoices,
        ResponseHeaderManipulationController.minFreshChoices,
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.booleanChoices
    ]

    private enum CacheControlResponseParameters: Int {
        case publicDirective
        case privateDirective
        case noCache
        case noStore
        case noTransform
        case mustRevalidate
        case proxyRevalidate
        case maxAge
        case sMaxAge
    }
    private static let CacheControlResponseParametersCount: Int = 9
    private var cacheControlResponseSelectedIndex = Array<Int>(repeating: 0, count: ResponseHeaderManipulationController.CacheControlResponseParametersCount)
    private let cacheControlResponseParamNames = [
        "public",
        "private",
        "no-cache",
        "no-store",
        "no-transform",
        "must-revalidate",
        "proxy-revalidate",
        "max-age",
        "s-maxage"
    ]
    private let cacheControlResponseChoices: [[OperationParameterValue]] = [
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.booleanChoices,
        ResponseHeaderManipulationController.maxAgeChoices,
        ResponseHeaderManipulationController.maxAgeChoices
    ]

    private static let maxAgeChoices: [OperationParameterValue] = [
        OperationParameterValue.notSent,
        OperationParameterValue.integer(60),
        OperationParameterValue.integer(600),
        OperationParameterValue.integer(3600)
    ]

    private static let maxStaleChoices: [OperationParameterValue] = [
        OperationParameterValue.notSent,
        OperationParameterValue.integer(60),
        OperationParameterValue.integer(600),
        OperationParameterValue.integer(3600)
    ]

    private static let minFreshChoices: [OperationParameterValue] = [
        OperationParameterValue.notSent,
        OperationParameterValue.integer(60),
        OperationParameterValue.integer(600),
        OperationParameterValue.integer(3600)
    ]

    private static let booleanChoices: [OperationParameterValue] = [
        OperationParameterValue.notSent,
        OperationParameterValue.string("Sent")
    ]

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Alter Cached Headers"
        tableView.register(GPAPIParameterTableViewCell.self, forCellReuseIdentifier: GPAPIParameterTableViewCell.reuseID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return ResponseHeaderManipulationController.TableViewSectionCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows = 0

        guard let tableViewSection = TableViewSection(rawValue: section) else {
            return numRows
        }

        switch tableViewSection {
        case .cacheControlRequestParameters: numRows = ResponseHeaderManipulationController.CacheControlRequestParametersCount
        case .cacheControlRequestHeader: numRows = 1
        case .cacheControlResponseParameters: numRows = ResponseHeaderManipulationController.CacheControlResponseParametersCount
        case .cacheControlResponseHeader: numRows = 1
        }

        return numRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)

        guard let section = TableViewSection(rawValue: indexPath.section) else {
            return cell
        }

        switch section {
        case .cacheControlRequestParameters:
            if indexPath.row < ResponseHeaderManipulationController.CacheControlRequestParametersCount {
                let choices = cacheControlRequestChoices[indexPath.row]
                let selectedIndex = cacheControlRequestSelectedIndex[indexPath.row]
                cell.textLabel?.text = cacheControlRequestParamNames[indexPath.row]
                cell.detailTextLabel?.text = choices[selectedIndex].description
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            }
        case .cacheControlRequestHeader:
            cell.textLabel?.text = cacheControlRequestHeaderValue ?? "Not Sent"
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            cell.selectionStyle = .none
        case .cacheControlResponseParameters:
            if indexPath.row < ResponseHeaderManipulationController.CacheControlResponseParametersCount {
                let choices = cacheControlResponseChoices[indexPath.row]
                let selectedIndex = cacheControlResponseSelectedIndex[indexPath.row]
                cell.textLabel?.text = cacheControlResponseParamNames[indexPath.row]
                cell.detailTextLabel?.text = choices[selectedIndex].description
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            }
        case .cacheControlResponseHeader:
            cell.textLabel?.text = cacheControlResponseHeaderValue ?? "Not Sent"
            cell.detailTextLabel?.text = nil
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
        case .cacheControlRequestParameters:  title = "Cache-Control Request Directives"
        case .cacheControlRequestHeader:      title = "Cache-Control Request Header"
        case .cacheControlResponseParameters: title = "Cache-Control Response Directives"
        case .cacheControlResponseHeader:     title = "Cache-Control Response Header"
        }

        return title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = TableViewSection(rawValue: indexPath.section) else {
            return
        }

        var controller: UIViewController? = nil
        switch section {
        case .cacheControlRequestParameters:
            let selectionController = GPSelectionViewController(title: cacheControlRequestParamNames[indexPath.row],
                                                                choices: cacheControlRequestChoices[indexPath.row],
                                                                selectedIndex: cacheControlRequestSelectedIndex[indexPath.row],
                                                                autoPopOnSelectionChange: true)
            selectionController.onSelectionChanged = { [weak self] (selectedIndex: Int) in
                // Update the selected request parameter index
                self?.cacheControlRequestSelectedIndex[indexPath.row] = selectedIndex
                // Update the Cache-Control header
                self?.updateHeaderValues()
                // Reload the tableview
                self?.tableView.reloadData()
            }
            controller = selectionController
        case .cacheControlResponseParameters:
            let selectionController = GPSelectionViewController(title: cacheControlResponseParamNames[indexPath.row],
                                                                choices: cacheControlResponseChoices[indexPath.row],
                                                                selectedIndex: cacheControlResponseSelectedIndex[indexPath.row],
                                                                autoPopOnSelectionChange: true)
            selectionController.onSelectionChanged = { [weak self] (selectedIndex: Int) in
                // Update the selected request parameter index
                self?.cacheControlResponseSelectedIndex[indexPath.row] = selectedIndex
                // Update the Cache-Control header
                self?.updateHeaderValues()
                // Reload the tableview
                self?.tableView.reloadData()
            }
            controller = selectionController
        default:
            break
        }
        if let controller = controller {
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func updateHeaderValues() {
        cacheControlRequestHeaderValue = cacheControlRequestValue()
        cacheControlResponseHeaderValue = cacheControlResponseValue()
    }

    private func cacheControlRequestValue() -> String? {
        var params = [String]()

        for i in 0..<ResponseHeaderManipulationController.CacheControlRequestParametersCount {
            let choices = cacheControlRequestChoices[i]
            let paramName = cacheControlRequestParamNames[i]
            let selectedIndex = cacheControlRequestSelectedIndex[i]
            let choiceValue = choices[selectedIndex].description
            if choiceValue != "Not Sent" {
                if choiceValue == "Sent" {
                    // This is a binary choice, so we just include the param name
                    params.append(paramName)
                } else {
                    // This is a name-value pair, so we include name=value
                    params.append("\(paramName)=\(choiceValue)")
                }
            }
        }

        return (params.isEmpty ? nil : params.joined(separator: ", "))
    }

    private func cacheControlResponseValue() -> String? {
        var params = [String]()

        for i in 0..<ResponseHeaderManipulationController.CacheControlResponseParametersCount {
            let choices = cacheControlResponseChoices[i]
            let paramName = cacheControlResponseParamNames[i]
            let selectedIndex = cacheControlResponseSelectedIndex[i]
            let choiceValue = choices[selectedIndex].description
            if choiceValue != "Not Sent" {
                if choiceValue == "Sent" {
                    // This is a binary choice, so we just include the param name
                    params.append(paramName)
                } else {
                    // This is a name-value pair, so we include name=value
                    params.append("\(paramName)=\(choiceValue)")
                }
            }
        }

        return (params.isEmpty ? nil : params.joined(separator: ", "))
    }

}
