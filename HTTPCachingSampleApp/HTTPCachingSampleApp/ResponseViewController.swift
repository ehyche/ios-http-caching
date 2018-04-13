//
//  ResponseViewController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/9/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class ResponseViewController: UITableViewController {

    // MARK: - Private properties

    private struct RowData {
        var name: String
        var value: String
    }

    private struct SectionData {
        var title: String
        var rows: [RowData]
    }
    private var response: URLResponse
    private var data: [SectionData]

    // MARK: - Initializers

    public init(response: URLResponse) {
        self.response = response
        self.data = ResponseViewController.data(forResponse: response)
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Response"
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

        let name = data[indexPath.section].rows[indexPath.row].name
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = data[indexPath.section].rows[indexPath.row].value

        if name == "URL" || (name == "Headers" && hasHeaders()) {
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }

        return cell
    }

    // MARK: - UITableViewDelegate methods

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < data.count else {
            return nil
        }

        return data[section].title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.section < data.count, indexPath.row < data[indexPath.section].rows.count else {
            return
        }

        let name = data[indexPath.section].rows[indexPath.row].name

        var controller: UIViewController? = nil
        if name == "URL" {
            if let url = URL(string: data[indexPath.section].rows[indexPath.row].value) {
                controller = URLDisplayViewController(url: url)
            }
        } else if name == "Headers" {
            if let httpUrlResponse = response as? HTTPURLResponse, !httpUrlResponse.allHeaderFields.isEmpty {
                controller = DictionaryDisplayController(withDictionary: httpUrlResponse.allHeaderFields)
            }
        }
        if let controller = controller {
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    // MARK: - Private methods

    private class func data(forResponse response: URLResponse) -> [SectionData] {
        var sections = [SectionData]()

        sections.append(ResponseViewController.urlResponseSection(forResponse: response))

        return sections
    }

    private class func urlResponseSection(forResponse response: URLResponse) -> SectionData {
        var rows = [RowData]()

        rows.append(RowData(name: "Expected Content Length", value: "\(response.expectedContentLength)"))
        if let suggestedFilename = response.suggestedFilename {
            rows.append(RowData(name: "Suggested Filename", value: suggestedFilename))
        }
        if let mimeType = response.mimeType {
            rows.append(RowData(name: "Mime Type", value: mimeType))
        }
        if let textEncodingName = response.textEncodingName {
            rows.append(RowData(name: "Text Encoding Name", value: textEncodingName))
        }
        if let url = response.url {
            rows.append(RowData(name: "URL", value: url.absoluteString))
        }

        if let httpResponse = response as? HTTPURLResponse {
            rows.append(RowData(name: "Status Code", value: "\(httpResponse.statusCode)"))
            rows.append(RowData(name: "Localized Status", value: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)))
            rows.append(RowData(name: "Headers", value: "\(httpResponse.allHeaderFields.count) Headers"))
        }

        return SectionData(title: "Response Info", rows: rows)
    }

    private func hasHeaders() -> Bool {
        guard let httpUrlResponse = response as? HTTPURLResponse else {
            return false
        }

        return !httpUrlResponse.allHeaderFields.isEmpty
    }

}
