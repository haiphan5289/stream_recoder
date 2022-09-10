//
//  PremiumCell.swift
//  stream_recorder
//
//  Created by Rum on 04/04/2022.
//

import UIKit

protocol PremiumCellDelegate: AnyObject {
    func onPressRestore(cell: PremiumCell, sender: UIButton)
    func onPressTerm(cell: PremiumCell, sender: UIButton)
    func onPressOption(cell: PremiumCell, sender: UIButton)
    func onPressIntro(cell: PremiumCell, sender: UIButton)
}

class PremiumCell: UITableViewCell {
    
    @IBOutlet weak var lblMonth: UILabel!
    @IBOutlet weak var lblYear: UILabel!
    @IBOutlet weak var lblMonthPrice: UILabel!
    @IBOutlet weak var lblYearPrice: UILabel!
    @IBOutlet weak var csMonthWidth: NSLayoutConstraint!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubtitle: UILabel!
    @IBOutlet weak var vMonth: CustomView!
    @IBOutlet weak var vYear: CustomView!
    @IBOutlet weak var vWeek: CustomView!
    @IBOutlet weak var lblWeekPrice: UILabel!
    @IBOutlet weak var lblWeek: UILabel!
    @IBOutlet weak var stViewIntro: UIStackView!
    
    
    static let identifierCell = "PremiumCell"
    
    weak var delegate: PremiumCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func onPressRestore(_ sender: UIButton) {
        delegate?.onPressRestore(cell: self, sender: sender)
    }
    
    @IBAction func onPressTerm(_ sender: UIButton) {
        delegate?.onPressTerm(cell: self, sender: sender)
    }
    
    @IBAction func onPressIntro(_ sender: UIButton) {
        delegate?.onPressIntro(cell: self, sender: sender)
    }
    
    @IBAction func onPressOption(_ sender: UIButton) {
        delegate?.onPressOption(cell: self, sender: sender)
    }
}
