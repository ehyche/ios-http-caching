//
//  DefaultTableViewCell.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/6/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class DefaultTableViewCell: UITableViewCell {

    static let reuseID = "DefaultTableViewCell"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
