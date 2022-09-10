//
//  NewBroadCollectionViewCell.swift
//  xrecorder
//
//  Created by Huy on 27/02/2021.
//

import UIKit

class NewBroadCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var topTitleLbl: UILabel!
    @IBOutlet weak var topSubtitleLbl: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var bottomTitleLbl: UILabel!
    @IBOutlet weak var bottomSubtitleLbl: UILabel!
    
    @IBOutlet weak var contentWidthConstraint: NSLayoutConstraint!
    
    func bind(data: NewOnbroadInfo) {
        imageView.image = UIImage(named: data.image)
        if data.pos == .top {
            topTitleLbl.text = data.title
            topSubtitleLbl.text = data.subtitle
            topTitleLbl.isHidden = false
            topSubtitleLbl.isHidden = false
            bottomTitleLbl.isHidden = true
            bottomSubtitleLbl.isHidden = true
            
//            topTitleLbl.layoutIfNeeded()
//            topSubtitleLbl.layoutIfNeeded()
        } else {
            bottomTitleLbl.text = data.title
            bottomSubtitleLbl.text = data.subtitle
            topTitleLbl.isHidden = true
            topSubtitleLbl.isHidden = true
            bottomTitleLbl.isHidden = false
            bottomSubtitleLbl.isHidden = false
            
//            bottomTitleLbl.layoutIfNeeded()
//            bottomSubtitleLbl.layoutIfNeeded()
        }
    }
    
    func topHeight() -> CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            let topPadding = window?.safeAreaInsets.top
            return (topPadding ?? 0)
        }
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows[0]
            let topPadding = window.safeAreaInsets.top
            return topPadding
        }
        return 20
    }
}
