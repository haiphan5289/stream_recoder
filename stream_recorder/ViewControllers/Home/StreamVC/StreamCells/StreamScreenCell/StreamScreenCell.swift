//
//  StreamScreenCell.swift
//  stream_recorder
//
//  Created by HHumorous on 05/04/2022.
//

import UIKit

class StreamScreenCell: UITableViewCell {
    
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    
    static let identifierCell = "StreamScreenCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
