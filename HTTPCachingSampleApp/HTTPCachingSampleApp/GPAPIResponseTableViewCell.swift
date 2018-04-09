//
//  GPAPIResponseTableViewCell.swift
//  MobileAPISampleApp
//
//  Created by Eric Hyche on 10/24/17.
//  Copyright © 2017 Groupon, Inc. All rights reserved.
//

import UIKit

class GPAPIResponseTableViewCell: UITableViewCell {

    static let reuseID = "GPAPIResponseTableViewCell"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        accessoryType = .none
        selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
