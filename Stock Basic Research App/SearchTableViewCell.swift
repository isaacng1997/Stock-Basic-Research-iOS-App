//
//  SearchTableViewCell.swift
//  Stock Basic Research App
//
//  Created by Isaac Ng on 5/20/19.
//  Copyright © 2019 Isaac Ng. All rights reserved.
//

import UIKit

class SearchTableViewCell: UITableViewCell {
    
    // Properties
    @IBOutlet weak var symbol: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
