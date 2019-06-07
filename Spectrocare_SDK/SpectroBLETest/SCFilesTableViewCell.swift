//
//  SCFilesTableViewCell.swift
//  SpectroBLETest
//
//  Created by Teja's MacBook on 26/04/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import UIKit

class SCFilesTableViewCell: UITableViewCell {
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
