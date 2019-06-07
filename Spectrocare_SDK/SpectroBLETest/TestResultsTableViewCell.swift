//
//  TestResultsTableViewCell.swift
//  SpectroBLETest
//
//  Created by Teja's MacBook on 20/05/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import UIKit

class TestResultsTableViewCell: UITableViewCell {
    @IBOutlet weak var testName: UILabel!
    @IBOutlet weak var ResultValueAndunits: UILabel!
    
    @IBOutlet weak var sNo: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
