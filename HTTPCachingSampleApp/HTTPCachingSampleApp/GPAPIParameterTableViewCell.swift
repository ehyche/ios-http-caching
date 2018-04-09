//
//  GPAPIParameterTableViewCell.swift
//  MobileAPISampleApp
//
//  Created by Eric Hyche on 10/24/17.
//  Copyright © 2017 Groupon, Inc. All rights reserved.
//

import UIKit

class GPAPIParameterTableViewCell: UITableViewCell {
    static let reuseID = "GPAPIParameterTableViewCell"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
