//
//  GPOperationTableViewCell.swift
//  MobileAPISampleApp
//
//  Created by Eric Hyche on 10/24/17.
//  Copyright © 2017 Groupon, Inc. All rights reserved.
//

import UIKit

class GPOperationTableViewCell: UITableViewCell {
    static let reuseID = "GPOperationTableViewCell"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


