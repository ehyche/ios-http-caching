//
//  SessionTaskMetricsViewController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/9/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class SessionTaskMetricsViewController: UITableViewController {

    // MARK: - Public properties

    var taskMetrics: URLSessionTaskMetrics? {
        didSet {
            buildSectionData()
        }
    }

    // MARK: - Private properties

    private struct RowData {
        var name: String
        var value: String
    }

    private struct SectionData {
        var title: String
        var rows: [RowData]
    }

    private var data = [SectionData]()
    private var dateFormatter = SessionTaskMetricsViewController.dateFormatterToUse()

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Session Task Metrics"
        tableView.register(GPAPIResponseTableViewCell.self, forCellReuseIdentifier: GPAPIResponseTableViewCell.reuseID)
    }

    // MARK: - UITableViewDataSource

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

        if name == "Request" || name == "Response" {
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
        if name == "Request" {
            let transactionIndex = indexPath.section - 1
            if let request = taskMetrics?.transactionMetrics[transactionIndex].request {
                let controller = RequestViewController(request: request)
                navigationController?.pushViewController(controller, animated: true)
            }
        } else if name == "Response" {
            let transactionIndex = indexPath.section - 1
            if let response = taskMetrics?.transactionMetrics[transactionIndex].response {
                let controller = ResponseViewController(response: response)
                navigationController?.pushViewController(controller, animated: true)
            }
        }
    }

    // MARK: - Private methods

    public class func string(forResourceFetchType fetchType: URLSessionTaskMetrics.ResourceFetchType?) -> String? {
        guard let fetchType = fetchType else {
            return nil
        }

        var fetchTypeString = ""
        switch fetchType {
        case .unknown: fetchTypeString = "Unknown"
        case .localCache: fetchTypeString = "Local Cache"
        case .serverPush: fetchTypeString = "Server Push"
        case .networkLoad: fetchTypeString = "Network Load"
        }
        return fetchTypeString
    }

    private class func dateFormatterToUse() -> DateFormatter {
        let formatter = DateFormatter()

        formatter.dateFormat = "HH:mm:ss.SSS"

        return formatter
    }

    private func buildSectionData() {
        data.removeAll()

        guard let taskMetrics = taskMetrics else {
            return
        }

        // Build the section for the task metrics
        data.append(sectionData(forTaskMetrics: taskMetrics))

        // Build a section for each transaction
        for (index, transactionMetrics) in taskMetrics.transactionMetrics.enumerated() {
            data.append(sectionData(forTaskTransactionMetrics: transactionMetrics, index: index))
        }
    }

    private func sectionData(forTaskMetrics metrics: URLSessionTaskMetrics) -> SectionData {
        var rows = [RowData]()

        rows.append(RowData(name: "Redirect Count", value: "\(metrics.redirectCount)"))
        rows.append(RowData(name: "Task Start", value: dateFormatter.string(from: metrics.taskInterval.start)))
        rows.append(RowData(name: "Task End", value: dateFormatter.string(from: metrics.taskInterval.end)))
        rows.append(RowData(name: "Duration", value: "\(metrics.taskInterval.duration)"))
        rows.append(RowData(name: "Number Of Transactions", value: "\(metrics.transactionMetrics.count)"))

        return SectionData(title: "Task Metrics", rows: rows)
    }

    private func sectionData(forTaskTransactionMetrics metrics: URLSessionTaskTransactionMetrics, index: Int) -> SectionData {
        var rows = [RowData]()

        rows.append(RowData(name: "Request", value: "\(metrics.request)"))
        if let response = metrics.response {
            var responseString = "Length: \(response.expectedContentLength)"
            if let httpResponse = response as? HTTPURLResponse {
                responseString = "Status: \(httpResponse.statusCode)"
            }
            rows.append(RowData(name: "Response", value: responseString))
        }
        if let fetchStartDate = metrics.fetchStartDate {
            rows.append(RowData(name: "Fetch Start", value: dateFormatter.string(from: fetchStartDate)))
        }
        if let domainLookupStartDate = metrics.domainLookupStartDate {
            rows.append(RowData(name: "Domain Lookup Start", value: dateFormatter.string(from: domainLookupStartDate)))
        }
        if let domainLookupEndDate = metrics.domainLookupEndDate {
            rows.append(RowData(name: "Domain Lookup End", value: dateFormatter.string(from: domainLookupEndDate)))
        }
        if let connectStartDate = metrics.connectStartDate {
            rows.append(RowData(name: "Connect Start", value: dateFormatter.string(from: connectStartDate)))
        }
        if let secureConnectionStartDate = metrics.secureConnectionStartDate {
            rows.append(RowData(name: "Secure Connection Start", value: dateFormatter.string(from: secureConnectionStartDate)))
        }
        if let secureConnectionEndDate = metrics.secureConnectionEndDate {
            rows.append(RowData(name: "Secure Connection End", value: dateFormatter.string(from: secureConnectionEndDate)))
        }
        if let connectEndDate = metrics.connectEndDate {
            rows.append(RowData(name: "Connect End", value: dateFormatter.string(from: connectEndDate)))
        }
        if let requestStartDate = metrics.requestStartDate {
            rows.append(RowData(name: "Request Start", value: dateFormatter.string(from: requestStartDate)))
        }
        if let requestEndDate = metrics.requestEndDate {
            rows.append(RowData(name: "Request End", value: dateFormatter.string(from: requestEndDate)))
        }
        if let responseStartDate = metrics.responseStartDate {
            rows.append(RowData(name: "Response Start", value: dateFormatter.string(from: responseStartDate)))
        }
        if let responseEndDate = metrics.responseEndDate {
            rows.append(RowData(name: "Response End", value: dateFormatter.string(from: responseEndDate)))
        }
        if let networkProtocolName = metrics.networkProtocolName {
            rows.append(RowData(name: "Network Protocol", value: networkProtocolName))
        }
        rows.append(RowData(name: "Proxy Connection", value: (metrics.isProxyConnection ? "Yes" : "No")))
        rows.append(RowData(name: "Reused Connection", value: (metrics.isReusedConnection ? "Yes" : "No")))
        rows.append(RowData(name: "Resource Fetch Type", value: SessionTaskMetricsViewController.string(forResourceFetchType: metrics.resourceFetchType) ?? ""))

        return SectionData(title: "Task Transaction \(index)", rows: rows)
    }

}
