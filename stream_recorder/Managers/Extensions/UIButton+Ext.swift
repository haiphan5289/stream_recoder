//
//  UIButton+Ext.swift
//  Scanner
//
//  Created by Rum on 23/08/2021.
//  Copyright © 2021 ABLabs - Tam Duc HD, Ltd. All rights reserved.
//

import UIKit

extension UIButton {
    class func createCustomButton(image: UIImage? = nil, title: String? = nil, background: UIColor, cornerRadius: CGFloat = 0) -> UIButton {
        let btn = UIButton()
        btn.setTitle(title, for: .normal)
        btn.setImage(image, for: .normal)
        btn.backgroundColor = background
        btn.layer.cornerRadius = cornerRadius
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        return btn
    }
}
