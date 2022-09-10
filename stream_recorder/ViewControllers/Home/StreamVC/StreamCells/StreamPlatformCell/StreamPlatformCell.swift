//
//  StreamPlatformCell.swift
//  stream_recorder
//
//  Created by HHumorous on 05/04/2022.
//

import UIKit

protocol StreamPlatformCellDelegate: AnyObject {
    func onPressSelectPlatform(cell: StreamPlatformCell, sender: UIButton)
}

class StreamPlatformCell: UITableViewCell {
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var tfUrl: UITextField!
    @IBOutlet weak var tfKey: UITextField!
    
    static let identifierCell = "StreamPlatformCell"
    
    weak var delegate: StreamPlatformCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tfUrl.placeHolderColor = UIColor.black.withAlphaComponent(0.4)
        tfKey.placeHolderColor = UIColor.black.withAlphaComponent(0.4)
        tfKey.textColor = UIColor.black.withAlphaComponent(0.6)
        tfUrl.textColor = UIColor.black.withAlphaComponent(0.6)
        tfUrl.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        tfKey.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func textFieldDidChanged(_ textField: UITextField) {
        if textField == tfUrl {
            Cache.shared.stream_url = textField.text?.trimmingCharacters(in: .whitespaces)
        } else {
            Cache.shared.stream_key = textField.text?.trimmingCharacters(in: .whitespaces)
        }
    }
    
    @IBAction func onPressPaste(_ sender: UIButton) {
        if sender.tag == 0 {
            tfUrl.text = UIPasteboard.general.string
            Cache.shared.stream_url = UIPasteboard.general.string
        } else {
            tfKey.text = UIPasteboard.general.string
            Cache.shared.stream_key = UIPasteboard.general.string
        }
    }
    
    @IBAction func onPressSelect(_ sender: UIButton) {
        delegate?.onPressSelectPlatform(cell: self, sender: sender)
    }
}
