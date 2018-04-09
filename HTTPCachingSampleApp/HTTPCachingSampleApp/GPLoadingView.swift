//
//  GPLoadingView.swift
//  MobileAPISampleApp
//
//  Created by Eric Hyche on 10/24/17.
//  Copyright © 2017 Groupon, Inc. All rights reserved.
//

import UIKit

class GPLoadingView: UIView {

    private let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)

    public var isAnimating: Bool {
        get {
            return activityIndicatorView.isAnimating
        }
        set {
            if newValue {
                activityIndicatorView.startAnimating()
            } else {
                activityIndicatorView.stopAnimating()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor(white: 0.0, alpha: 0.5)

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)

        activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
