//
//  URLDisplayViewController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/9/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class URLDisplayViewController: UITableViewController {

    // MARK: - Private properties

    private var url: URL
    private struct RowData {
        var name: String
        var value: String
        var indentationLevel: Int
    }
    private struct SectionData {
        var title: String
        var rows: [RowData]
    }
    private var data = [SectionData]()
    private var pathExpanded = false


    // MARK: - Initializers

    public init(url: URL) {
        self.url = url
        super.init(style: .grouped)
        rebuildData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "URL Display"
        tableView.register(GPAPIResponseTableViewCell.self, forCellReuseIdentifier: GPAPIResponseTableViewCell.reuseID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < data.count else {
            return 0
        }

        return data[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)

        guard indexPath.section < data.count, indexPath.row < data[indexPath.section].rows.count else {
            return cell
        }

        cell.textLabel?.text = data[indexPath.section].rows[indexPath.row].name
        cell.detailTextLabel?.text = data[indexPath.section].rows[indexPath.row].value
        cell.indentationLevel = data[indexPath.section].rows[indexPath.row].indentationLevel
        cell.selectionStyle = .none

        if data[indexPath.section].rows[indexPath.row].name == "Path" {
            cell.accessoryType = .detailButton
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    // MARK: - UITableViewDelegate methods

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil

        switch section {
        case 0: title = "URL Info"
        case 1: title = "Query Parameters"
        default:
            break
        }

        return title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < data.count, indexPath.row < data[indexPath.section].rows.count else {
            return
        }

        if data[indexPath.section].rows[indexPath.row].name == "Path" {
            pathExpanded = !pathExpanded
            rebuildData()
            tableView.reloadData()
        }
    }

    // MARK: - Private methods

    private func rebuildData() {
        data.removeAll()

        data.append(urlInfoSection())
        data.append(queryParametersSection())
    }

    private func urlInfoSection() -> SectionData {
        var rows = [RowData]()

        if let scheme = url.scheme {
            rows.append(RowData(name: "Scheme", value: scheme, indentationLevel: 0))
        }
        if let host = url.host {
            rows.append(RowData(name: "Host", value: host, indentationLevel: 0))
        }
        if let user = url.user {
            rows.append(RowData(name: "User", value: user, indentationLevel: 0))
        }
        if let password = url.password {
            rows.append(RowData(name: "Password", value: password, indentationLevel: 0))
        }
        rows.append(RowData(name: "Path", value: url.path, indentationLevel: 0))
        if pathExpanded {
            for (index, pathComponent) in url.pathComponents.enumerated() {
                rows.append(RowData(name: "\(index)", value: pathComponent, indentationLevel: 1))
            }
        }
        if let fragment = url.fragment {
            rows.append(RowData(name: "Fragment", value: fragment, indentationLevel: 0))
        }

        return SectionData(title: "URL Info", rows: rows)
    }

    private func queryParametersSection() -> SectionData {
        var rows = [RowData]()

        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            for queryItem in queryItems {
                rows.append(RowData(name: queryItem.name, value: queryItem.value ?? "", indentationLevel: 0))
            }
        }

        return SectionData(title: "Query Parameters", rows: rows)
    }

}
