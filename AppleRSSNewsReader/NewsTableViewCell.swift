//
//  NewsTableViewCell.swift
//  AppleRSSNewsReader
//
//  Created by Vyacheslav Nagornyak on 6/18/16.
//  Copyright © 2016 Vyacheslav Nagornyak. All rights reserved.
//

import UIKit

class NewsTableViewCell: UITableViewCell {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var contentLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	// MARK: - UITableViewCell
	
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
