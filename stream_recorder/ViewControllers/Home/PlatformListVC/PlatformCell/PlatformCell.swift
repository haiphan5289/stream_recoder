//
//  PlatformCell.swift
//  stream_recorder
//
//  Created by HHumorous on 05/04/2022.
//

import UIKit

class PlatformCell: UITableViewCell {
    
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var imgCheck: UIImageView!
    
    static let identifierCell = "PlatformCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
