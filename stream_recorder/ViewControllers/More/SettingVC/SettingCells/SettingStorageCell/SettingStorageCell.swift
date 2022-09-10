//
//  SettingStorageCell.swift
//  stream_recorder
//
//  Created by HHumorous on 04/04/2022.
//

import UIKit

class SettingStorageCell: UITableViewCell {
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var vProgress: UIProgressView!

    static let identifierCell = "SettingStorageCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let totalSize = UIDevice.current.totalDiskSpaceInGB
        let used = UIDevice.current.usedDiskSpaceInGB 
        
        lblTitle.text = String(format: "%@/ %@", used, totalSize)
        vProgress.clipsToBounds = true
        vProgress.cornerRadius = 6
        vProgress.progress = Float(UIDevice.current.usedDiskSpaceInBytes) / Float(UIDevice.current.totalDiskSpaceInBytes)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
