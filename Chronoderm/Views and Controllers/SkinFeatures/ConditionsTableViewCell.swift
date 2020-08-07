//
//  ConditionsTableViewCell.swift
//  Chronoderm
//
//  Created by Nick Baughan on 26/08/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit

class ConditionsTableViewCell: UITableViewCell {

    
    @IBOutlet var cellImageView: UIImageView!
    @IBOutlet var cellTitleLabel: UILabel!
    @IBOutlet var cellLeftLabel: UILabel!
    @IBOutlet var cellRightLabel: UILabel!
    @IBOutlet var favouriteImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
