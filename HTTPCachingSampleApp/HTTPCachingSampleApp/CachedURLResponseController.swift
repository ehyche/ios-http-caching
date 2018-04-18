//
//  CachedURLResponseController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/12/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

public enum CacheControlDirectiveName: String {
    case noCache = "no-cache"
    case noStore = "no-store"
    case noTransform = "no-transform"
    case onlyIfCached = "only-if-cached"
    case publicDirective = "public"
    case privateDirective = "private"
    case mustRevalidate = "must-revalidate"
    case proxyRevalidate = "proxy-revalidate"
    case maxAge = "max-age"
    case sMaxAge = "s-maxage"
    case maxStale = "max-stale"
    case minFresh = "min-fresh"
}

struct CacheControlDirective {
    var name: CacheControlDirectiveName
    var value: TimeInterval?

    init?(string: String) {
        let directiveComponents = string.components(separatedBy: "=").map({ $0.trimmingCharacters(in: CharacterSet.whitespaces) })
        guard !directiveComponents.isEmpty else {
            return nil
        }

        guard let directiveName = CacheControlDirectiveName(rawValue: directiveComponents[0]) else {
            return nil
        }

        var deltaSeconds: TimeInterval? = nil
        switch directiveName {
        case .maxAge:
            fallthrough
        case .maxStale:
            fallthrough
        case .minFresh:
            if directiveComponents.count == 2 {
                deltaSeconds = TimeInterval(directiveComponents[1])
            }
        default:
            break
        }

        name = directiveName
        value = deltaSeconds
    }
}

class CachedURLResponseController: UITableViewController {

    // MARK: - Private properties

    private var cachedURLResponse: CachedURLResponse

    private enum TableViewSection: Int {
        case cachedURLResponse
        case cacheStatus
    }
    private static let TableViewSectionCount: Int = 2

    private enum CachedURLResponseRow: Int {
        case response
        case storagePolicy
        case userInfo
        case data
    }
    private static let CachedURLResponseRowCount: Int = 4
    private static let dateFormatter = CachedURLResponseController.dateHeaderFormatter()

    private enum CacheStatusRow: Int {
        case age
        case freshnessLifetime
        case freshnessStatus
    }
    private static let CacheStatusRowCount: Int = 3
    private var timer: Timer?
    private static let timerInterval: TimeInterval = 1.0

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        startTimer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        stopTimer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return CachedURLResponseController.TableViewSectionCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows = 0

        guard let sectionEnum = TableViewSection(rawValue: section) else {
            return numRows
        }

        switch sectionEnum {
        case .cachedURLResponse: numRows = CachedURLResponseController.CachedURLResponseRowCount
        case .cacheStatus: numRows = CachedURLResponseController.CacheStatusRowCount
        }

        return numRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GPAPIResponseTableViewCell.reuseID, for: indexPath)

        guard let section = TableViewSection(rawValue: indexPath.section) else {
            return cell
        }

        switch section {
        case .cachedURLResponse:
            if let cachedURLResponseRow = CachedURLResponseRow(rawValue: indexPath.row) {
                switch cachedURLResponseRow {
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
                }
            }
        case .cacheStatus:
            if let cacheStatusRow = CacheStatusRow(rawValue: indexPath.row) {
                switch cacheStatusRow {
                case .age:
                    cell.textLabel?.text = "Age"
                    let age = CachedURLResponseController.age(ofCachedResponse: cachedURLResponse) ?? 0.0
                    cell.detailTextLabel?.text = "\(Int(age)) seconds"
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                case .freshnessLifetime:
                    cell.textLabel?.text = "Freshness Lifetime"
                    let lifetime = CachedURLResponseController.freshnessLifetime(ofCachedResponse: cachedURLResponse)
                    cell.detailTextLabel?.text = CachedURLResponseController.string(fromFreshnessLifetime: lifetime)
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                case .freshnessStatus:
                    cell.textLabel?.text = "Freshness Status"
                    var detailText = ""
                    if let age = CachedURLResponseController.age(ofCachedResponse: cachedURLResponse),
                       let lifetime = CachedURLResponseController.freshnessLifetime(ofCachedResponse: cachedURLResponse) {
                        if age < lifetime {
                            detailText = "Fresh (\(Int(lifetime - age)) seconds)"
                        } else {
                            detailText = "Stale (\(Int(age - lifetime)) seconds)"
                        }
                    } else {
                        detailText = "Indeterminate (No Cache Headers)"
                    }
                    cell.detailTextLabel?.text = detailText
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                }
            }
        }

        return cell
    }

    // MARK: - UITableViewDelegate methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = TableViewSection(rawValue: indexPath.section) else {
            return
        }

        var controller: UIViewController? = nil
        switch section {
        case .cachedURLResponse:
            if let cachedURLResponseRow = CachedURLResponseRow(rawValue: indexPath.row) {
                switch cachedURLResponseRow {
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
                }
            }
        default:
            break
        }
        if let controller = controller {
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil

        guard let sectionEnum = TableViewSection(rawValue: section) else {
            return title
        }

        switch sectionEnum {
        case .cachedURLResponse: title = "CachedURLResponse"
        case .cacheStatus: title = "Cache Status"
        }

        return title
    }

    // MARK: - Private methods

    private class func age(ofCachedResponse cachedResponse: CachedURLResponse) -> TimeInterval? {
        guard let httpResponse = cachedResponse.response as? HTTPURLResponse else {
            return nil
        }

        // Get an Age header (if we have one)
        var ageValue: TimeInterval = 0.0
        if let ageHeaderStringValue = httpResponse.allHeaderFields["Age"] as? String,
           let ageHeaderValue = TimeInterval(ageHeaderStringValue) {
            ageValue = ageHeaderValue
        }

        // Compute the age via the Date header
        var apparentAge: TimeInterval = 0.0
        if let dateHeaderValueString = httpResponse.allHeaderFields["Date"] as? String,
           let dateHeaderValue = CachedURLResponseController.dateFormatter.date(from: dateHeaderValueString) {
            apparentAge = max(0.0, Date().timeIntervalSince(dateHeaderValue))
        }

        // Compute the corrected_received_age
        let correctedReceivedAge = max(apparentAge, ageValue)

        return correctedReceivedAge
    }

    private class func dateHeaderFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss O"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }

    private class func httpDateHeader(inCachedResponse cachedResponse: CachedURLResponse, withName name: String) -> Date? {
        guard let httpResponse = cachedResponse.response as? HTTPURLResponse,
              let responseHeaders = httpResponse.allHeaderFields as? [String:String],
              let httpDateValue = responseHeaders[name], !httpDateValue.isEmpty else {
            return nil
        }

        return CachedURLResponseController.dateFormatter.date(from: httpDateValue)
    }

    private class func freshnessLifetime(ofCachedResponse cachedResponse: CachedURLResponse) -> TimeInterval? {
        var lifetime: TimeInterval? = nil

        // Get the max-age if we have it.
        // If we don't have it, then check if we have an Expires and Date headers
        if let maxAge = cacheControlDirectiveValue(ofCachedResponse: cachedResponse, forName: .maxAge) {
            lifetime = maxAge
        } else if let dateHeaderValue = httpDateHeader(inCachedResponse: cachedResponse, withName: "Date"),
                  let expiresHeaderValue = httpDateHeader(inCachedResponse: cachedResponse, withName: "Expires") {
            lifetime = expiresHeaderValue.timeIntervalSince(dateHeaderValue)
        }

        return lifetime
    }

    private class func string(fromFreshnessLifetime lifetime: TimeInterval?) -> String {
        guard let lifetime = lifetime else {
            return "No Cache Headers"
        }

        return String(format: "%.1f seconds", lifetime)
    }

    private class func cacheControlDirectiveValue(ofCachedResponse cachedResponse: CachedURLResponse, forName name: CacheControlDirectiveName) -> TimeInterval? {
        return CachedURLResponseController.cacheControlDirectives(fromCachedResponse: cachedResponse)?.first(where: { $0.name == name })?.value
    }

    private class func isCacheControlDirectivePresent(inCachedResponse cachedResponse: CachedURLResponse, withName name: CacheControlDirectiveName) -> Bool {
        return CachedURLResponseController.cacheControlDirectives(fromCachedResponse: cachedResponse)?.contains(where: { $0.name == name }) ?? false
    }

    private class func cacheControlDirectives(fromCachedResponse cachedResponse: CachedURLResponse) -> [CacheControlDirective]? {
        guard let httpResponse = cachedResponse.response as? HTTPURLResponse,
              let responseHeaders = httpResponse.allHeaderFields as? [String:String] else {
            return nil
        }

        // Get the key for Cache-Control, even if it is lowercase
        let cacheControlKeyLowercase = "Cache-Control".lowercased()
        guard let cacheControlKey = responseHeaders.keys.first(where: { $0.lowercased() == cacheControlKeyLowercase }),
              let cacheControlValue = responseHeaders[cacheControlKey],
              !cacheControlValue.isEmpty else {
            return nil
        }

        // Parse the Cache-Control header value
        return cacheControlValue.components(separatedBy: ",").map({ return $0.trimmingCharacters(in: CharacterSet.whitespaces )}).flatMap({ CacheControlDirective(string: $0) })
    }

    private func startTimer() {
        stopTimer()
        let newTimer = Timer(timeInterval: CachedURLResponseController.timerInterval, repeats: true, block: { [weak self] (timer) in
            self?.timerFired()
        })
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .defaultRunLoopMode)
    }

    private func stopTimer() {
        timer?.invalidate()
    }

    private func timerFired() {
        let indexPathsToReload = [
            IndexPath(row: CacheStatusRow.age.rawValue, section: TableViewSection.cacheStatus.rawValue),
            IndexPath(row: CacheStatusRow.freshnessStatus.rawValue, section: TableViewSection.cacheStatus.rawValue)
        ]
        tableView.reloadRows(at: indexPathsToReload, with: .none)
    }

}
