//
//  UITextView+Ext.swift
//  Scanner
//
//  Created by Rum on 11/10/2021.
//  Copyright © 2021 ABLabs - Tam Duc HD, Ltd. All rights reserved.
//

import UIKit

extension UITextView {
    func addDoneToolbar() {
        let screenWidth = UIScreen.main.bounds.width

        let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 44.0)) //4
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) //5
        let barButton = UIBarButtonItem(title: "common.btn.done".localized, style: .plain, target: nil, action: #selector(tapCancel)) //7
        toolBar.setItems([flexible, barButton], animated: false) //8
        self.inputAccessoryView = toolBar //9
    }
    
    @objc func tapCancel() {
        self.resignFirstResponder()
    }
}
