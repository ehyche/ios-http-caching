//
//  RequestResponseController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/4/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class RequestResponseController: UITableViewController {

    // MARK: - Private properties

    private enum TableViewSection: Int {
        case requestSelection
        case requestInfo
        case sendButton
        case clearButton
        case responseInfo
    }
    private static let TableViewSectionCount: Int = 5

    private struct ResponseHeader {
        var name: String
        var value: String
    }
    private var urlRequest: URLRequest?
    private var urlResponse: HTTPURLResponse?
    private var urlResponseHeaders = [ResponseHeader]()
    private var urlResponseData: Data?
    private var urlResponseDataString: String?
    private var loadingView = GPLoadingView(frame: .zero)
    private var selectedURLIndex: Int = 0
    private var selectedHeaderIndex: Int = 0
    private var cachePolicyChoices: [URLRequest.CachePolicy] = [
        URLRequest.CachePolicy.useProtocolCachePolicy,
        URLRequest.CachePolicy.reloadIgnoringLocalCacheData,
        URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData,
        URLRequest.CachePolicy.returnCacheDataElseLoad,
        URLRequest.CachePolicy.returnCacheDataDontLoad,
        URLRequest.CachePolicy.reloadRevalidatingCacheData
    ]
    private var selectedCachePolicyIndex: Int = 0
    private var timeoutChoices: [OperationParameterValue] = [
        OperationParameterValue.number(5.0),
        OperationParameterValue.number(10.0),
        OperationParameterValue.number(30.0),
        OperationParameterValue.number(60.0)

    ]
    private var selectedTimeoutIndex: Int = 2

    private var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    private var urlSession: URLSession? {
        return appDelegate?.session
    }

    private var urls: [AppDelegate.URLInfo] {
        return appDelegate?.urls ?? [AppDelegate.URLInfo]()
    }
    
    private var requestHeaders: [AppDelegate.RequestHeaderInfo] {
        return appDelegate?.headers ?? [AppDelegate.RequestHeaderInfo]()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "HTTP Request and Response"
        tableView.register(GPAPIParameterTableViewCell.self, forCellReuseIdentifier: GPAPIParameterTableViewCell.reuseID)
        tableView.register(GPButtonTableViewCell.self, forCellReuseIdentifier: GPButtonTableViewCell.reuseID)
        tableView.register(GPAPIResponseTableViewCell.self, forCellReuseIdentifier: GPAPIResponseTableViewCell.reuseID)
        tableView.register(TextViewTableViewCell.self, forCellReuseIdentifier: TextViewTableViewCell.reuseID)
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: TextFieldTableViewCell.reuseID)
        tableView.register(URLTableViewCell.self, forCellReuseIdentifier: URLTableViewCell.reuseID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        rebuildRequest()
        updateUI()
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return RequestResponseController.TableViewSectionCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows: Int = 0

        guard let section = TableViewSection(rawValue: section) else {
            return numRows
        }

        switch section {
            case .requestSelection: numRows = 4
            case .requestInfo: numRows = 2
            case .sendButton: numRows = 1
            case .clearButton: numRows = 1
            case .responseInfo: numRows = (urlResponse != nil ? 4 : 0)
        }

        return numRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(frame: .zero)

        guard let section = TableViewSection(rawValue: indexPath.section) else {
            return cell
        }

        switch section {
        case .requestSelection:
            switch indexPath.row {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "URL"
                cell.detailTextLabel?.text = urls[selectedURLIndex].name
                cell.accessoryType = .disclosureIndicator
            case 1:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "Header"
                cell.detailTextLabel?.text = requestHeaders[selectedHeaderIndex].displayName
                cell.accessoryType = .disclosureIndicator
            case 2:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "Cache Policy"
                cell.detailTextLabel?.text = RequestViewController.string(forCachePolicy: cachePolicyChoices[selectedCachePolicyIndex])
                cell.accessoryType = .disclosureIndicator
            case 3:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "Timeout"
                var timeout: Double = 0.0
                switch timeoutChoices[selectedTimeoutIndex] {
                case .number(let doubleValue):
                    timeout = doubleValue
                default:
                    break
                }
                cell.detailTextLabel?.text = "\(timeout)"
                cell.accessoryType = .disclosureIndicator
            default:
                break
            }
        case .requestInfo:
            switch indexPath.row {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "Request"
                cell.detailTextLabel?.text = urlRequest?.url?.absoluteString
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            case 1:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "URLCache.cachedResponse"
                cell.detailTextLabel?.text = doesCacheContainResponseForCurrentRequest() ? "Non-nil" : "Nil"
            default:
                break
            }
        case .sendButton:
            cell = tableView.dequeueReusableCell(withIdentifier: GPButtonTableViewCell.reuseID, for: indexPath)
            if let buttonCell = cell as? GPButtonTableViewCell {
                buttonCell.buttonText = "Send Request"
            }
        case .clearButton:
            cell = tableView.dequeueReusableCell(withIdentifier: GPButtonTableViewCell.reuseID, for: indexPath)
            if let buttonCell = cell as? GPButtonTableViewCell {
                buttonCell.buttonText = "Clear Response"
            }
        case .responseInfo:
            switch indexPath.row {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "Response"
                let statusCode = urlResponse?.statusCode ?? 0
                let responseString = "Status: \(statusCode)"
                cell.detailTextLabel?.text = responseString
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            case 1:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "Response Data"
                let responseDataSize = urlResponseData?.count ?? 0
                cell.detailTextLabel?.text = "\(responseDataSize) Bytes"
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            case 2:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "Fetch Type"
                cell.detailTextLabel?.text = SessionTaskMetricsViewController.string(forResourceFetchType: sessionTaskMetrics(forRequest: urlRequest)?.transactionMetrics.last?.resourceFetchType) ?? ""
                cell.accessoryType = .none
                cell.selectionStyle = .none
            case 3:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "Task Metrics Loaded"
                if sessionTaskMetrics(forRequest: urlRequest) != nil {
                    cell.detailTextLabel?.text = "Yes"
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                } else {
                    cell.detailTextLabel?.text = "No"
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                }
            default:
                break
            }
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
            case .requestSelection: title = "Select Request Parameters"
            case .requestInfo: title = "Request Info"
            case .responseInfo: title = "Response Info"
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
            case .requestSelection:
                switch indexPath.row {
                case 0:
                    // The user wants to change the selected URL
                    let controller = URLSelectionViewController(urls: urls,
                                                                selectedURLIndex: selectedURLIndex,
                                                                onSelectionChanged: { (index) in
                                                                    self.handleURLSelection(urlIndex: index)
                    })
                    navigationController?.pushViewController(controller, animated: true)
                case 1:
                    var choices = [OperationParameterValue]()
                    for requestHeader in requestHeaders {
                        choices.append(OperationParameterValue.string(requestHeader.displayName))
                    }
                    let controller = GPSelectionViewController(title: "Request Header",
                                                               choices: choices,
                                                               selectedIndex: selectedHeaderIndex,
                                                               autoPopOnSelectionChange: true)
                    controller.onSelectionChanged = { [weak self] (selectedIndex: Int) in
                        self?.handleRequestHeaderSelection(index: selectedIndex)
                    }
                    navigationController?.pushViewController(controller, animated: true)
                case 2:
                    var choices = [OperationParameterValue]()
                    for policy in cachePolicyChoices {
                        let cachePolicyChoiceString = RequestViewController.string(forCachePolicy: policy) ?? ""
                        choices.append(OperationParameterValue.string(cachePolicyChoiceString))
                    }
                    let controller = GPSelectionViewController(title: "Cache Policy",
                                                               choices: choices,
                                                               selectedIndex: selectedCachePolicyIndex,
                                                               autoPopOnSelectionChange: true)
                    controller.onSelectionChanged = { [weak self] (selectedIndex: Int) in
                        self?.handleCachePolicySelection(index: selectedIndex)
                    }
                    navigationController?.pushViewController(controller, animated: true)
                case 3:
                    // The user wants to change the timeout
                    let controller = GPSelectionViewController(title: "Timeout",
                                                               choices: timeoutChoices,
                                                               selectedIndex: selectedTimeoutIndex,
                                                               autoPopOnSelectionChange: true)
                    controller.onSelectionChanged = { [weak self] (selectedIndex: Int) in
                        self?.handleTimeoutSelection(index: selectedIndex)
                    }
                    navigationController?.pushViewController(controller, animated: true)
                default:
                    break
                }
            case .requestInfo:
                switch indexPath.row {
                case 0:
                    if let request = urlRequest {
                        let controller = RequestViewController(request: request)
                        navigationController?.pushViewController(controller, animated: true)
                    }
                default:
                    break
                }
            case .sendButton:
                sendRequest()
            case .clearButton:
                clearResponse()
                updateUI()
            case .responseInfo:
                switch indexPath.row {
                case 0:
                    if let response = urlResponse {
                        let controller = ResponseViewController(response: response)
                        navigationController?.pushViewController(controller, animated: true)
                    }
                case 1:
                    if let data = urlResponseData {
                        let controller = DataDisplayViewController(data: data, mimeType: urlResponse?.mimeType)
                        navigationController?.pushViewController(controller, animated: true)
                    }
                case 3:
                    if let request = urlRequest,
                        let taskMetrics = sessionTaskMetrics(forRequest: request)  {
                        let controller = SessionTaskMetricsViewController(style: .grouped)
                        controller.taskMetrics = taskMetrics
                        navigationController?.pushViewController(controller, animated: true)
                    }
                default:
                    break
                }
        }
    }

    // MARK: - Private methods

    private func sendRequest() {
        // Get the URLSession
        guard let session = urlSession,
              let request = urlRequest else {
            return
        }

        // Show the loading view
        showLoadingView()

        // Create the data task
        let dataTask = session.dataTask(with: request)
        appDelegate?.setCompletion(forTask: dataTask, completion: { [weak self] (data, response, error) in
            self?.urlResponse = response as? HTTPURLResponse
            if let error = error {
                self?.urlResponseDataString = error.localizedDescription
            } else {
                self?.urlResponseData = data
                self?.updateResponseHeaders()
                self?.updateResponseDataString()
            }
            DispatchQueue.main.async {
                self?.appDelegate?.clearCompletion(forTask: dataTask)
                self?.updateUI()
                self?.hideLoadingView()
            }
        })

        // Start the data task
        dataTask.resume()
    }

    private func showLoadingView() {
        if loadingView.superview == nil {
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            tableView.addSubview(loadingView)

            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            loadingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

            loadingView.isAnimating = true
        }
    }

    private func hideLoadingView() {
        if loadingView.superview != nil {
            loadingView.isAnimating = false
            loadingView.removeFromSuperview()
        }
    }

    private func updateResponseHeaders() {
        urlResponseHeaders.removeAll()
        if let headers = urlResponse?.allHeaderFields, !headers.isEmpty {
            for (name, value) in headers {
                if let nameString = name as? String,
                   let valueString = value as? String {
                    urlResponseHeaders.append(ResponseHeader(name: nameString, value: valueString))
                }
            }
        }
    }

    private func updateResponseDataString() {
        urlResponseDataString = nil
        guard let mimeType = urlResponse?.mimeType, !mimeType.isEmpty else {
            return
        }

        // For now, we only support application/json
        guard mimeType == "application/json" else {
            return
        }

        // Decode into a JSON object
        urlResponseDataString = prettyJSONDataString(fromData: urlResponseData)
    }

    private func prettyJSONDataString(fromData data: Data?) -> String? {
        guard let data = data, !data.isEmpty else {
            return nil
        }

        var dataString: String?
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
            let prettyJSONData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.prettyPrinted)
            dataString = String(data: prettyJSONData, encoding: .utf8)
        } catch {
            dataString = nil
        }
        return dataString
    }

    private func updateUI() {
        tableView.reloadData()
    }

    private func clearResponse() {
        urlResponse = nil
        urlResponseHeaders.removeAll()
        urlResponseData = nil
        urlResponseDataString = nil
    }

    private func handleURLSelection(urlIndex: Int) {
        if urlIndex != selectedURLIndex {
            clearResponse()
        }
        selectedURLIndex = urlIndex
        rebuildRequest()
        updateUI()
    }
    
    private func handleRequestHeaderSelection(index: Int) {
        if index != selectedHeaderIndex {
            clearResponse()
        }
        selectedHeaderIndex = index
        rebuildRequest()
        updateUI()
    }

    private func handleCachePolicySelection(index: Int) {
        if index != selectedCachePolicyIndex {
            clearResponse()
        }
        selectedCachePolicyIndex = index
        rebuildRequest()
        updateUI()
    }

    private func handleTimeoutSelection(index: Int) {
        if index != selectedTimeoutIndex {
            clearResponse()
        }
        selectedTimeoutIndex = index
        rebuildRequest()
        updateUI()
    }

    private func rebuildRequest() {
        // Sanity checks
        guard selectedURLIndex < urls.count,
              let url = urls[selectedURLIndex].url,
              selectedHeaderIndex < requestHeaders.count,
              selectedCachePolicyIndex < cachePolicyChoices.count,
              selectedTimeoutIndex < timeoutChoices.count else {
            return
        }

        urlRequest = URLRequest(url: url,
                                cachePolicy: cachePolicyChoices[selectedCachePolicyIndex],
                                timeoutInterval: timeoutInterval())

        if let cacheControlHeader = appDelegate?.cacheControlRequestHeaderValue, !cacheControlHeader.isEmpty {
            urlRequest?.setValue(cacheControlHeader, forHTTPHeaderField: "Cache-Control")
        }

        if let headerName = requestHeaders[selectedHeaderIndex].headerName,
           let headerValue = requestHeaders[selectedHeaderIndex].headerValue?(),
           !headerName.isEmpty, !headerValue.isEmpty {
            urlRequest?.setValue(headerValue, forHTTPHeaderField: headerName)
        }

    }

    private func doesCacheContainResponseForCurrentRequest() -> Bool {
        guard let request = urlRequest else {
            return false
        }
        let cachedResponse = appDelegate?.sessionCache?.cachedResponse(for: request)
        return cachedResponse != nil
    }

    private func sessionTaskMetrics(forRequest request: URLRequest?) -> URLSessionTaskMetrics? {
        guard let request = request else {
            return nil
        }
        return appDelegate?.taskMetrics[request]
    }

    private func timeoutInterval() -> TimeInterval {
        var interval: TimeInterval = 30.0

        guard selectedTimeoutIndex < timeoutChoices.count else {
            return interval
        }

        switch timeoutChoices[selectedTimeoutIndex] {
        case .number(let doubleValue): interval = doubleValue
        default: break
        }

        return interval
    }

}

