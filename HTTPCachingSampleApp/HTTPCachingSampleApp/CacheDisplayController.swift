//
//  CacheDisplayController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/4/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class CacheDisplayController: UITableViewController {

    // MARK: - Private properties

    private var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    private var appDelegateCache: URLCache? {
        return appDelegate?.sessionCache
    }

    private enum TableViewSection: Int {
        case status
        case clearButton
        case cacheStatusForFixedURLs
    }

    private enum CacheStatusRow: Int {
        case diskCapacity
        case diskUsage
        case memoryCapacity
        case memoryUsage
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "HTTP Cache Contents"
        tableView.register(GPAPIParameterTableViewCell.self, forCellReuseIdentifier: GPAPIParameterTableViewCell.reuseID)
        tableView.register(GPButtonTableViewCell.self, forCellReuseIdentifier: GPButtonTableViewCell.reuseID)
        tableView.register(GPAPIResponseTableViewCell.self, forCellReuseIdentifier: GPAPIResponseTableViewCell.reuseID)
        tableView.register(TextViewTableViewCell.self, forCellReuseIdentifier: TextViewTableViewCell.reuseID)
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: TextFieldTableViewCell.reuseID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows: Int = 0

        guard let section = TableViewSection(rawValue: section) else {
            return numRows
        }

        switch section {
            case .status: numRows = 4
            case .clearButton: numRows = 1
            case .cacheStatusForFixedURLs:
                let urlsCount = appDelegate?.urls.count ?? 0
                let headersCount = appDelegate?.headers.count ?? 0
                numRows = urlsCount * headersCount
        }

        return numRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(frame: .zero)

        guard let section = TableViewSection(rawValue: indexPath.section) else {
            return cell
        }

        switch section {
            case .status:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)
                if let statusRow = CacheStatusRow(rawValue: indexPath.row) {
                    switch statusRow {
                    case .diskCapacity:
                        cell.textLabel?.text = "Disk Capacity"
                        let diskCapacity = appDelegateCache?.diskCapacity ?? 0
                        cell.detailTextLabel?.text = "\(diskCapacity)"
                    case .diskUsage:
                        cell.textLabel?.text = "Disk Usage"
                        let diskUsage = appDelegateCache?.currentDiskUsage ?? 0
                        cell.detailTextLabel?.text = "\(diskUsage)"
                    case .memoryCapacity:
                        cell.textLabel?.text = "Memory Capacity"
                        let memoryCapacity = appDelegateCache?.memoryCapacity ?? 0
                        cell.detailTextLabel?.text = "\(memoryCapacity)"
                    case .memoryUsage:
                        cell.textLabel?.text = "Memory Usage"
                        let memoryUsage = appDelegateCache?.currentMemoryUsage ?? 0
                        cell.detailTextLabel?.text = "\(memoryUsage)"
                    }
                }
            case .clearButton:
                cell = tableView.dequeueReusableCell(withIdentifier: GPButtonTableViewCell.reuseID, for: indexPath)
                if let buttonCell = cell as? GPButtonTableViewCell {
                    buttonCell.buttonText = "Clear Cache"
                }
            case .cacheStatusForFixedURLs:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)
                let result = cachedResponse(forIndexPath: indexPath)
                let isCached = result.cachedResponse != nil
                cell.textLabel?.text = result.name
                cell.detailTextLabel?.text = (isCached ? "Cached" : "Not Cached")
                cell.accessoryType = (isCached ? .disclosureIndicator : .none)
                cell.selectionStyle = (isCached ? .default : .none)
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil

        guard let section = TableViewSection(rawValue: section) else {
            return title
        }

        switch section {
        case .status: title = "Cache Statistics"
        case .cacheStatusForFixedURLs: title = "Cache Status"
        default: break
        }

        return title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = TableViewSection(rawValue: indexPath.section) else {
            return
        }

        switch section {
        case .clearButton:
            clearCache()
            updateUI()
        case .cacheStatusForFixedURLs:
            let result = cachedResponse(forIndexPath: indexPath)
            if let cachedResponse = result.cachedResponse {
                let controller = CachedURLResponseController(cachedURLResponse: cachedResponse)
                navigationController?.pushViewController(controller, animated: true)
            }
        default:
            break
        }
    }

    // MARK: - Private methods
    
    private func cachedResponse(forIndexPath indexPath: IndexPath) -> (name: String, cachedResponse: CachedURLResponse?) {
        var name = ""
        var cachedResponse: CachedURLResponse? = nil
        
        let headersCount = appDelegate?.headers.count ?? 1
        let urlIndex = indexPath.row / headersCount
        let headerIndex = indexPath.row % headersCount
        if let urlInfo = appDelegate?.urls[urlIndex], let url = urlInfo.url,
            let headerInfo = appDelegate?.headers[headerIndex] {
            name = "URL=\(urlInfo.name),Header=\(headerInfo.displayName)"
            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
            if let headerName = headerInfo.headerName,
               let headerValue = headerInfo.headerValue?(),
               !headerName.isEmpty, !headerValue.isEmpty {
                request.setValue(headerValue, forHTTPHeaderField: headerName)
            }
            cachedResponse = appDelegate?.sessionCache?.cachedResponse(for: request)
        }
        return (name: name, cachedResponse: cachedResponse)
    }

    private func clearCache() {
        appDelegateCache?.removeAllCachedResponses()
    }

    private func updateUI() {
        tableView.reloadData()
    }

}
