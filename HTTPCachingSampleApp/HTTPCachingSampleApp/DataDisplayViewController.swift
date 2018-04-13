//
//  DataDisplayViewController.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/12/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class DataDisplayViewController: UIViewController {

    // MARK: - Private properties

    private var data: Data
    private var mimeType: String?
    private var textView: UITextView?

    // MARK: - Initializers

    init(data: Data, mimeType: String?) {
        self.data = data
        self.mimeType = mimeType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    public class func string(forResponseData data: Data?, withMimeType mimeType: String?) -> String? {
        guard let mimeType = mimeType else {
            return nil
        }

        // Only support JSON for now.
        // TODO: support other mime types
        guard mimeType == "application/json" else {
            return nil
        }

        return prettyJSONDataString(fromData: data)
    }

    public class func prettyJSONDataString(fromData data: Data?) -> String? {
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

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Data"

        let tView = UITextView(frame: .zero)
        tView.translatesAutoresizingMaskIntoConstraints = false
        tView.contentInsetAdjustmentBehavior = .never
        view.addSubview(tView)

        tView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        tView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        tView.text = DataDisplayViewController.string(forResponseData: data, withMimeType: mimeType)

        textView = tView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
