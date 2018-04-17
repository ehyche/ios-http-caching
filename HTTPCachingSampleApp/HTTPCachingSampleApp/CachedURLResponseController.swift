//
//  CachedURLResponseController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/12/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class CachedURLResponseController: UITableViewController {

    // MARK: - Private properties

    private var cachedURLResponse: CachedURLResponse

    private enum CachedURLResponseRow: Int {
        case response
        case storagePolicy
        case userInfo
        case data
        case age
    }
    private static let CachedURLResponseRowCount: Int = 5
    private static let dateFormatter = CachedURLResponseController.dateHeaderFormatter()

    // MARK: - Initializers

    init(cachedURLResponse: CachedURLResponse) {
        self.cachedURLResponse = cachedURLResponse
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    public class func string(forCacheStoragePolicy policy: URLCache.StoragePolicy?) -> String? {
        guard let policy = policy else {
            return nil
        }

        var policyString = ""
        switch policy {
        case .allowed: policyString = "Allowed"
        case .allowedInMemoryOnly: policyString = "Allowed in Memory Only"
        case .notAllowed: policyString = "Not Allowed"
        }
        return policyString
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "CachedURLResponse"
        tableView.register(GPAPIResponseTableViewCell.self, forCellReuseIdentifier: GPAPIResponseTableViewCell.reuseID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CachedURLResponseController.CachedURLResponseRowCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)

        guard let rowEnum = CachedURLResponseRow(rawValue: indexPath.row) else {
            return cell
        }

        switch rowEnum {
        case .response:
            cell.textLabel?.text = "Response"
            var responseString = "Length: \(cachedURLResponse.response.expectedContentLength)"
            if let httpResponse = cachedURLResponse.response as? HTTPURLResponse {
                responseString = "Status: \(httpResponse.statusCode)"
            }
            cell.detailTextLabel?.text = responseString
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case .storagePolicy:
            cell.textLabel?.text = "Storage Policy"
            cell.detailTextLabel?.text = CachedURLResponseController.string(forCacheStoragePolicy: cachedURLResponse.storagePolicy)
            cell.accessoryType = .none
            cell.selectionStyle = .none
        case .userInfo:
            cell.textLabel?.text = "User Info"
            let numEntries = cachedURLResponse.userInfo?.count ?? 0
            cell.detailTextLabel?.text = "\(numEntries) Entries"
            if numEntries > 0 {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            } else {
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        case .data:
            cell.textLabel?.text = "Data"
            cell.detailTextLabel?.text = "\(cachedURLResponse.data.count) Bytes"
            if cachedURLResponse.data.count > 0 {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            } else {
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        case .age:
            cell.textLabel?.text = "Age"
            let age = CachedURLResponseController.age(ofCachedResponse: cachedURLResponse)
            cell.detailTextLabel?.text = String(format: "%.1f seconds", age)
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }

        return cell
    }

    // MARK: - UITableViewDelegate methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let rowEnum = CachedURLResponseRow(rawValue: indexPath.row) else {
            return
        }

        var controller: UIViewController? = nil
        switch rowEnum {
        case .response:
            controller = ResponseViewController(response: cachedURLResponse.response)
        case .storagePolicy:
            break
        case .userInfo:
            if let userInfo = cachedURLResponse.userInfo, !userInfo.isEmpty {
                controller = DictionaryDisplayController(withDictionary: userInfo)
            }
        case .data:
            if cachedURLResponse.data.count > 0 {
                controller = DataDisplayViewController(data: cachedURLResponse.data, mimeType: cachedURLResponse.response.mimeType)
            }
        case .age:
            break
        }
        if let controller = controller {
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    // MARK: - Private methods

    private class func age(ofCachedResponse cachedResponse: CachedURLResponse) -> TimeInterval {
        guard let httpResponse = cachedResponse.response as? HTTPURLResponse,
              let dateHeaderString = httpResponse.allHeaderFields["Date"] as? String,
              let dateFromHeader = CachedURLResponseController.dateFormatter.date(from: dateHeaderString) else {
            return 0.0
        }

        return Date().timeIntervalSince(dateFromHeader)
    }

    private class func dateHeaderFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss O"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }


}
