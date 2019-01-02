//
//  CustomFileViewCell.swift
//  CapScape
//
//  Created by David on 12/19/18.
//  Copyright © 2018 David Hartzog. All rights reserved.
//

import UIKit

class CustomFileListCell: UITableViewCell {

    @IBOutlet weak var cellThumbnailImage: UIImageView!
    @IBOutlet weak var cellFilenameLabel: UILabel!
    @IBOutlet weak var cellSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    

}
