//
//  OperationViewController.swift
//  MobileAPISampleApp
//
//  Created by Eric Hyche on 1/23/18.
//  Copyright © 2018 Groupon, Inc. All rights reserved.
//

import UIKit

public enum OperationParameterValue {
    case notSent
    case string(String)
    case number(Double)
    case integer(Int)
    case boolean(Bool)

    public var description: String {
        get {
            switch self {
                case .notSent:
                    return "Not Sent"
                case .string(let str):
                    return str.description
                case .boolean(let bool):
                    return bool.description
                case .integer(let enumInt):
                    return enumInt.description
                case .number(let enumDouble):
                    return enumDouble.description
            }
        }
    }
}

public enum OperationParameterRequestLocation: String {
    case path = "Path"
    case query = "Query"
    case header = "Header"
    case body = "Body"
}

public struct OperationParameter {
    var name: String
    var values: [OperationParameterValue]
    var selectedValueIndex: Int
    var location: OperationParameterRequestLocation
}

public enum OperationResult {
    case success(HTTPURLResponse, Data)
    case failure(HTTPURLResponse?, Data?, Error?)
}

public typealias OperationCompletionClosure = (OperationResult) -> Void

public typealias OperationActionClosure = ([OperationParameter], @escaping OperationCompletionClosure) -> Void

public class OperationViewController: UITableViewController {

    // MARK: - Public properties

    public var path = ""
    public var httpMethod = "GET"
    public var parameters = [OperationParameter]()
    public var operationAction: OperationActionClosure?

    // MARK: - Private properties

    private enum OperationSection: Int {
        case requestInfo
        case requestParameters
        case sendButton
        case responseInfo
        case responseHeaders
        case responseData
    }

    private struct ResponseHeader {
        var name: String
        var value: String
    }
    private var responseStatusCode: Int?
    private var responseHeaders = [ResponseHeader]()
    private var responseDataString: String?
    private var loadingView = GPLoadingView(frame: .zero)

    // MARK: - UIViewController overrides

    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(GPAPIParameterTableViewCell.self, forCellReuseIdentifier: GPAPIParameterTableViewCell.reuseID)
        tableView.register(GPButtonTableViewCell.self, forCellReuseIdentifier: GPButtonTableViewCell.reuseID)
        tableView.register(GPAPIResponseTableViewCell.self, forCellReuseIdentifier: GPAPIResponseTableViewCell.reuseID)
        tableView.register(TextViewTableViewCell.self, forCellReuseIdentifier: TextViewTableViewCell.reuseID)
    }

    // MARK: - UITableViewDataSource methods

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows: Int = 0

        guard let sectionEnum = OperationSection(rawValue: section) else {
            return numRows
        }

        switch sectionEnum {
            case .requestInfo:
                numRows = 2
            case .requestParameters:
                numRows = parameters.count
            case .sendButton:
                numRows = 1
            case .responseInfo:
                numRows = (responseStatusCode != nil ? 1 : 0)
            case .responseHeaders:
                numRows = responseHeaders.count
            case .responseData:
                numRows = (responseDataString != nil ? 1 : 0)
        }

        return numRows
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(frame: .zero)

        guard let sectionEnum = OperationSection(rawValue: indexPath.section) else {
            return cell
        }

        switch sectionEnum {
            case .requestInfo:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = (indexPath.row == 0 ? "HTTP Method" : "Path")
                cell.detailTextLabel?.text = (indexPath.row == 0 ? httpMethod : path)
                cell.accessoryType = .none
                cell.selectionStyle = .none
            case .requestParameters:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIParameterTableViewCell.reuseID, for: indexPath)
                configureParameterCell(cell, indexPath: indexPath, parameters: parameters)
            case .sendButton:
                cell = tableView.dequeueReusableCell(withIdentifier: GPButtonTableViewCell.reuseID, for: indexPath)
            case .responseInfo:
                cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)
                cell.textLabel?.text = "Status Code"
                let statusCode = responseStatusCode ?? 0
                cell.detailTextLabel?.text = "\(statusCode)"
            case .responseHeaders:
                if indexPath.row < responseHeaders.count {
                    cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)
                    cell.textLabel?.text = responseHeaders[indexPath.row].name
                    cell.detailTextLabel?.text = responseHeaders[indexPath.row].value
                }
            case .responseData:
                cell = tableView.dequeueReusableCell(withIdentifier: TextViewTableViewCell.reuseID, for: indexPath)
                if let textViewCell = cell as? TextViewTableViewCell {
                    textViewCell.cellText = responseDataString
                }
        }

        return cell
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil

        guard let sectionEnum = OperationSection(rawValue: section) else {
            return title
        }

        switch sectionEnum {
            case .requestInfo:
                title = "Request Info"
            case .requestParameters:
                title = "Request Parameters"
            case .responseInfo:
                title = "Response Info"
            case .responseHeaders:
                title = "Response Headers"
            case .responseData:
                title = "Response JSON"
            default:
                break
        }

        return title
    }

    // MARK: - UITableViewDelegate methods

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let sectionEnum = OperationSection(rawValue: indexPath.section) else {
            return
        }

        switch sectionEnum {
            case .requestParameters:
                if indexPath.row < parameters.count && parameters[indexPath.row].values.count > 1 {
                    let rowData = parameters[indexPath.row]
                    let controller = GPSelectionViewController(title: rowData.name,
                                                               choices: rowData.values,
                                                               selectedIndex: rowData.selectedValueIndex,
                                                               autoPopOnSelectionChange: true)
                    controller.onSelectionChanged = { [weak self] (selectedIndex: Int) in
                        // Update the selected request parameter index
                        self?.parameters[indexPath.row].selectedValueIndex = selectedIndex
                        // Reload the row
                        self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                    navigationController?.pushViewController(controller, animated: true)
                }
            case .sendButton:
                sendRequest()
            default:
                break
        }

    }

    override public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 44.0

        guard let sectionEnum = OperationSection(rawValue: indexPath.section) else {
            return height
        }

        switch sectionEnum {
            case .responseData:
                height = 400.0
            default:
                break
        }

        return height
    }

    // MARK: - Private methods

    private func configureParameterCell(_ cell: UITableViewCell, indexPath: IndexPath, parameters: [OperationParameter]) {
        if indexPath.row < parameters.count {
            let rowData = parameters[indexPath.row]
            cell.textLabel?.text = rowData.name
            cell.detailTextLabel?.text = rowData.values[rowData.selectedValueIndex].description
            cell.accessoryType = (rowData.values.count > 1 ? .disclosureIndicator : .none)
            cell.selectionStyle = (rowData.values.count > 1 ? .gray : .none)
        }
    }

    private func sendRequest() {
        guard operationAction != nil else {
            return
        }

        // Show the loading view
        showLoadingView()
        // Call the action block, if we have one
        operationAction?(parameters, { [weak self] (operationResult) in
            switch operationResult {
                case .success(let httpResponse, let data):
                    self?.handleHTTPResponse(response: httpResponse, data: data)
                case .failure(let httpResponse, let data, _):
                    self?.handleHTTPResponse(response: httpResponse, data: data)
            }
            self?.hideLoadingView()
            self?.tableView.reloadData()
        })
    }

    private func handleHTTPResponse(response: HTTPURLResponse?, data: Data?) {
        clearResponse()
        guard let response = response else {
            return
        }
        responseStatusCode = response.statusCode
        for (headerName, headerValue) in response.allHeaderFields {
            responseHeaders.append(ResponseHeader(name: "\(headerName)", value: "\(headerValue)"))
        }

        // Get the mime type of the response
        if let data = data, !data.isEmpty, let dataStr = String(data: data, encoding: .utf8) {
            responseDataString = dataStr
        }
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

    private func clearResponse() {
        responseStatusCode = nil
        responseHeaders.removeAll()
        responseDataString = nil
    }

}

