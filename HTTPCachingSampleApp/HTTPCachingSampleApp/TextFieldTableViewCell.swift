//
//  TextFieldTableViewCell.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/5/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell {

    static let reuseID = "TextFieldTableViewCell"

    public var cellText: String? {
        get {
            return textField.text
        }
        set {
            textField.text = newValue
        }
    }

    private var textField = UITextField(frame: .zero)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)

        textField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        textField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        textField.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
