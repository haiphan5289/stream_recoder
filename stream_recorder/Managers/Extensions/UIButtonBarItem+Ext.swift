//
//  UIButtonBarItem+Ext.swift
//  Scanner
//
//  Created by Rum on 20/08/2021.
//  Copyright © 2021 ABLabs - Tam Duc HD, Ltd. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    class func backItem(target: Any, action: Selector) -> UIBarButtonItem {
        let frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        let button = customButton(with: #imageLiteral(resourceName: "icBackGray").withRenderingMode(.alwaysOriginal),
                                  frame: frame,
                                  target: target,
                                  action: action, contentInset: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        
        let item = UIBarButtonItem(customView: button)
        
        return item
    }
    
    class func closeItem(target: Any, action: Selector) -> UIBarButtonItem {
        let frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        let button = customButton(with: #imageLiteral(resourceName: "icCloseGray").withRenderingMode(.alwaysOriginal),
                                  frame: frame,
                                  target: target,
                                  action: action, contentInset: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

        let item = UIBarButtonItem(customView: button)
        
        return item
    }
    
    class func moreItem(target: Any, action: Selector) -> UIBarButtonItem {
        let frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        let button = customButton(with: #imageLiteral(resourceName: "icMore").withRenderingMode(.alwaysOriginal),
                                  frame: frame,
                                  target: target,
                                  action: action, contentInset: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

        let item = UIBarButtonItem(customView: button)
        
        return item
    }
    
    fileprivate class func customButton(with image: UIImage,
                                        highlightedImage: UIImage? = nil,
                                        frame: CGRect,
                                        target: Any,
                                        action: Selector, contentInset: UIEdgeInsets? = .zero) -> UIButton {
        let button = UIButton.init(frame: frame)
        button.contentEdgeInsets = contentInset ?? .zero
        button.setImage(image, for: .normal)
        button.setImage(highlightedImage, for: .highlighted)
        button.backgroundColor = UIColor.color_f6f6f6
        button.addTarget(target, action: action, for: .touchUpInside)
        button.layer.cornerRadius = frame.height / 2
        
        return button
    }
}
