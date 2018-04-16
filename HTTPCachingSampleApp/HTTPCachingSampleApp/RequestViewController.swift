//
//  RequestViewController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/9/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class RequestViewController: UITableViewController {

    // MARK: - Private properties

    private struct RowData {
        var name: String
        var value: String
    }

    private struct SectionData {
        var title: String
        var rows: [RowData]
    }

    private var request: URLRequest
    private var data: [SectionData]

    // MARK: - Public methods

    public class func string(forCachePolicy cachePolicy: URLRequest.CachePolicy?) -> String? {
        guard let cachePolicy = cachePolicy else {
            return nil
        }

        switch cachePolicy {
        case .useProtocolCachePolicy: return "useProtocolCachePolicy"
        case .reloadIgnoringLocalCacheData: return "reloadIgnoringLocalCacheData"
        case .reloadIgnoringLocalAndRemoteCacheData: return "reloadIgnoringLocalAndRemoteCacheData"
        case .returnCacheDataElseLoad: return "returnCacheDataElseLoad"
        case .returnCacheDataDontLoad: return "returnCacheDataDontLoad"
        case .reloadRevalidatingCacheData: return "reloadRevalidatingCacheData"
        }
    }

    public class func string(forNetworkServiceType serviceType: URLRequest.NetworkServiceType?) -> String? {
        guard let serviceType = serviceType else {
            return nil
        }

        switch serviceType {
        case .background: return "Background"
        case .default: return "Default"
        case .networkServiceTypeCallSignaling: return "Call Signaling"
        case .video: return "Video"
        case .voice: return "Voice"
        case .voip: return "VOIP"
        }
    }


    // MARK: - Initializers

    public init(request: URLRequest) {
        self.request = request
        self.data = RequestViewController.sectionData(forRequest: request)
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Request"
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

        let numHeaders = request.allHTTPHeaderFields?.count ?? 0
        if name == "URL" || name == "Main Document URL" || (name == "Headers" && numHeaders > 0) {
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }

        return cell
    }

    // MARK: - UITableViewDelegate methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.section < data.count,
            indexPath.row < data[indexPath.section].rows.count else {
            return
        }

        let numHeaders = request.allHTTPHeaderFields?.count ?? 0
        let rowName = data[indexPath.section].rows[indexPath.row].name
        guard rowName == "URL" || rowName == "Main Document URL" || (rowName == "Headers" && numHeaders > 0) else {
            return
        }

        if rowName == "URL" || rowName == "Main Document URL" {
            if let url = URL(string: data[indexPath.section].rows[indexPath.row].value) {
                let controller = URLDisplayViewController(url: url)
                navigationController?.pushViewController(controller, animated: true)
            }
        } else if rowName == "Headers" {
            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                let controller = DictionaryDisplayController(withDictionary: headers)
                navigationController?.pushViewController(controller, animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil

        switch section {
        case 0: title = "Request Info"
        case 1: title = "Request Headers"
        default: break
        }

        return title
    }

    // MARK: - Private methods

    private class func sectionData(forRequest request: URLRequest) -> [SectionData] {
        var sections = [SectionData]()

        sections.append(requestInfoSection(forRequest: request))

        return sections
    }

    private class func requestInfoSection(forRequest request: URLRequest) -> SectionData {
        var rows = [RowData]()

        let method = request.httpMethod ?? "GET"
        rows.append(RowData(name: "HTTP Method", value: method))
        if let url = request.url {
            rows.append(RowData(name: "URL", value: url.absoluteString))
        }
        if let cachePolicy = RequestViewController.string(forCachePolicy: request.cachePolicy) {
            rows.append(RowData(name: "Cache Policy", value: cachePolicy))
        }
        if let body = request.httpBody {
            rows.append(RowData(name: "HTTP Body", value: "\(body.count) Bytes"))
        }
        if let bodyStream = request.httpBodyStream {
            rows.append(RowData(name: "HTTP Body Stream", value: "\(bodyStream)"))
        }
        if let mainDocumentURL = request.mainDocumentURL {
            rows.append(RowData(name: "Main Document URL", value: mainDocumentURL.absoluteString))
        }
        rows.append(RowData(name: "Timeout Interval", value: "\(request.timeoutInterval)"))
        let shouldHandleCookies = request.httpShouldHandleCookies ? "Yes" : "No"
        rows.append(RowData(name: "HTTP Should Handle Cookies", value: shouldHandleCookies))
        let shouldUsePipelining = request.httpShouldUsePipelining ? "Yes" : "No"
        rows.append(RowData(name: "HTTP Should Use Pipelining", value: shouldUsePipelining))
        let allowsCellularAccess = request.allowsCellularAccess ? "Yes" : "No"
        rows.append(RowData(name: "Allow Cellular Access", value: allowsCellularAccess))
        if let serviceType = RequestViewController.string(forNetworkServiceType: request.networkServiceType) {
            rows.append(RowData(name: "Network Service Type", value: serviceType))
        }
        let numHeaders = request.allHTTPHeaderFields?.count ?? 0
        rows.append(RowData(name: "Headers", value: "\(numHeaders) Headers"))

        return SectionData(title: "Request Info", rows: rows)
    }

}
