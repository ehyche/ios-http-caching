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
        return 4
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Response"
            var responseString = "Length: \(cachedURLResponse.response.expectedContentLength)"
            if let httpResponse = cachedURLResponse.response as? HTTPURLResponse {
                responseString = "Status: \(httpResponse.statusCode)"
            }
            cell.detailTextLabel?.text = responseString
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case 1:
            cell.textLabel?.text = "Storage Policy"
            cell.detailTextLabel?.text = CachedURLResponseController.string(forCacheStoragePolicy: cachedURLResponse.storagePolicy)
            cell.accessoryType = .none
            cell.selectionStyle = .none
        case 2:
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
        case 3:
            cell.textLabel?.text = "Data"
            cell.detailTextLabel?.text = "\(cachedURLResponse.data.count) Bytes"
            if cachedURLResponse.data.count > 0 {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            } else {
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        default:
            break
        }

        return cell
    }

    // MARK: - UITableViewDelegate methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0:
            let controller = ResponseViewController(response: cachedURLResponse.response)
            navigationController?.pushViewController(controller, animated: true)
        case 3:
            if cachedURLResponse.data.count > 0 {
                let controller = DataDisplayViewController(data: cachedURLResponse.data, mimeType: cachedURLResponse.response.mimeType)
                navigationController?.pushViewController(controller, animated: true)
            }
        default:
            break
        }
    }


}
