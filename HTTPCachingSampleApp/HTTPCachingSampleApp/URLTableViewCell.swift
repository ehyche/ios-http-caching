//
//  URLTableViewCell.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/6/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class URLTableViewCell: UITableViewCell {

    static let reuseID = "URLTableViewCell"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        textLabel?.numberOfLines = 0
        accessoryType = .none
        selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
