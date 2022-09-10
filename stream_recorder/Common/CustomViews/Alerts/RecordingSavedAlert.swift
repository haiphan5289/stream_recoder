//
//  RecordingSavedAlert.swift
//  stream_recorder
//
//  Created by HHumorous on 04/04/2022.
//

import UIKit

class RecordingSavedAlert: UIView, Modal {
    var backgroundView: UIView = UIView()
    var dialogView: UIView = UIView()
    
    lazy var lblTitle: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.workSansMedium(size: 17)
        lbl.textColor = UIColor.black
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "Screen recording saved!\nCheck it now?"
        
        return lbl
    }()
    
    lazy var vButton: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 48
        
        return view
    }()
    
    lazy var imgIcon: UIImageView = {
        let imv = UIImageView()
        imv.translatesAutoresizingMaskIntoConstraints = false
        imv.image = #imageLiteral(resourceName: "icSavedSuccess")
        
        return imv
    }()
    
    lazy var btnAction: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setAttributedTitle(NSAttributedString(string: "Open", attributes: [NSAttributedString.Key.font: UIFont.workSansMedium(size: 17), NSAttributedString.Key.foregroundColor: UIColor.white]), for: .normal)
        btn.backgroundColor = UIColor(hex: "75b9f2")
        btn.addTarget(self, action: #selector(didTapActionBtn), for: .touchUpInside)
        btn.cornerRadius = 30
        
        return btn
    }()
    
    lazy var btnLater: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setAttributedTitle(NSAttributedString(string: "Later", attributes: [NSAttributedString.Key.font: UIFont.workSansMedium(size: 17), NSAttributedString.Key.foregroundColor: UIColor.black]), for: .normal)
        btn.backgroundColor = UIColor(hex: "f3f5f6")
        btn.addTarget(self, action: #selector(didTapCloseBtn), for: .touchUpInside)
        btn.cornerRadius = 30
        
        return btn
    }()
    
    var callback: ((Bool) -> Void)?
    
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initialize() {

        //Background
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        addSubview(backgroundView)
        
        backgroundView.addSubview(dialogView)
        
        dialogView.cornerRadius = 48
        dialogView.backgroundColor = UIColor(hex: "f1f6ed")
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dialogView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 16),
            dialogView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            dialogView.bottomAnchor.constraint(equalTo: backgroundView.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        dialogView.addSubview(lblTitle)
        dialogView.addSubview(imgIcon)
        dialogView.addSubview(vButton)
        vButton.addSubview(btnAction)
        vButton.addSubview(btnLater)
        
        NSLayoutConstraint.activate([
            vButton.heightAnchor.constraint(equalToConstant: 96),
            vButton.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor),
            vButton.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor),
            vButton.bottomAnchor.constraint(equalTo: dialogView.bottomAnchor),
            
            btnLater.leadingAnchor.constraint(equalTo: vButton.leadingAnchor, constant: 16),
            btnLater.trailingAnchor.constraint(equalTo: btnAction.leadingAnchor, constant: -16),
            btnLater.bottomAnchor.constraint(equalTo: vButton.bottomAnchor, constant: -16),
            btnLater.topAnchor.constraint(equalTo: vButton.topAnchor, constant: 16),
            
            btnAction.widthAnchor.constraint(equalTo: btnLater.widthAnchor),
            btnAction.trailingAnchor.constraint(equalTo: vButton.trailingAnchor, constant: -16),
            btnAction.bottomAnchor.constraint(equalTo: vButton.bottomAnchor, constant: -16),
            btnAction.topAnchor.constraint(equalTo: vButton.topAnchor, constant: 16),
            
            lblTitle.bottomAnchor.constraint(equalTo: vButton.topAnchor, constant: -44),
            lblTitle.centerXAnchor.constraint(equalTo: dialogView.centerXAnchor),
            lblTitle.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 72),
            
            imgIcon.centerXAnchor.constraint(equalTo: dialogView.centerXAnchor),
            imgIcon.bottomAnchor.constraint(equalTo: lblTitle.topAnchor, constant: -20),
            imgIcon.widthAnchor.constraint(equalToConstant: 76),
            imgIcon.heightAnchor.constraint(equalToConstant: 76),
            imgIcon.topAnchor.constraint(equalTo: dialogView.topAnchor, constant: 64)
        ])
    }
    
    @objc func didTapCloseBtn() {
        callback?(false)
        dismiss(animated: true)
    }
    
    @objc func didTapActionBtn() {
        callback?(true)
        dismiss(animated: true)
    }
}
