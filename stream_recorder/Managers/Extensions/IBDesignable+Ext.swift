//
//  IBDesignable+Ext.swift
//  OlaChat
//
//  Created by Rum on 17/11/2020.
//  Copyright © 2021 ABLabs - Tam Duc HD, Ltd. All rights reserved.
//

import UIKit

extension UIButton {
    @IBInspectable var localizedKey: String {
        get {
            return ""
        } set {
            self.setTitle(newValue, for: .normal)
        }
    }
}

extension UILabel {
    @IBInspectable var localizedKey: String {
        get {
            return ""
        } set {
            self.text = newValue.localized
        }
    }
}

extension UITextField {
    @IBInspectable var localizePlaceholder: String {
        get {
            return ""
        } set {
            self.placeholder = newValue.localized
        }
    }
    
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            if let color = newValue, let placeholderText = placeholder {
                attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: color])
            }
        }
    }
    
    @IBInspectable var paddingLeftCustom: CGFloat {
            get {
                return leftView?.frame.size.width ?? 14
            }
            set {
                let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: newValue, height: frame.size.height))
                leftView = paddingView
                leftViewMode = .always
            }
        }

    @IBInspectable var paddingRightCustom: CGFloat {
        get {
            return rightView?.frame.size.width ?? 14
        }
        set {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: newValue, height: frame.size.height))
            rightView = paddingView
            rightViewMode = .always
        }
    }
    
    func applyCustomClearButton() {
        clearButtonMode = .whileEditing
        if let clearButton = self.value(forKey: "_clearButton") as? UIButton {
            clearButton.setImage(#imageLiteral(resourceName: "icClear"), for: .normal)
        }
    }

    @objc func clearClicked(sender:UIButton) {
        text = ""
    }
    
    func setInputViewDatePicker(target: Any, selector: Selector, oldDate: Date, showToolbar: Bool) {
        // Create a UIDatePicker object and assign to inputView
        let screenWidth = UIScreen.main.bounds.width
        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 216))//1
        datePicker.datePickerMode = .date //2
        datePicker.date = oldDate
        datePicker.timeZone = .current
        datePicker.maximumDate = Date()
        // iOS 14 and above
        if #available(iOS 14, *) {// Added condition for iOS 14
          datePicker.preferredDatePickerStyle = .wheels
          datePicker.sizeToFit()
        }
        self.inputView = datePicker //3
        datePicker.addTarget(target, action: selector, for: .valueChanged)

        if showToolbar {
            // Create a toolbar and assign it to inputAccessoryView
            let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 44.0)) //4
            let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) //5
            let cancel = UIBarButtonItem(title: "common.btn.cancel".localized, style: .plain, target: nil, action: #selector(tapCancel)) // 6
            let barButton = UIBarButtonItem(title: "common.btn.done".localized, style: .plain, target: target, action: selector) //7
            toolBar.setItems([cancel, flexible, barButton], animated: false) //8
            self.inputAccessoryView = toolBar //9
        }
    }
    
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
