//
//  HelpCell.swift
//  stream_recorder
//
//  Created by Rum on 04/04/2022.
//

import UIKit

class HelpCell: UITableViewCell {
    
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgArrow: UIImageView!
    
    static let identifierCell = "HelpCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
