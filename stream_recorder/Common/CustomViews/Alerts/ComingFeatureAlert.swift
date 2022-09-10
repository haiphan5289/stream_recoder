//
//  ComingFeatureAlert.swift
//  stream_recorder
//
//  Created by HHumorous on 04/04/2022.
//

import UIKit

class ComingFeatureAlert: UIView, Modal {
    var backgroundView: UIView = UIView()
    var dialogView: UIView = UIView()
    
    lazy var lblTitle: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.workSansMedium(size: 17)
        lbl.textColor = UIColor.black
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "This Feature Will Be Available Soon"
        
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
        imv.image = #imageLiteral(resourceName: "icFeatureComingSoon")
        
        return imv
    }()
    
    lazy var btnAction: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setAttributedTitle(NSAttributedString(string: "Okay", attributes: [NSAttributedString.Key.font: UIFont.workSansMedium(size: 17), NSAttributedString.Key.foregroundColor: UIColor.white]), for: .normal)
        btn.backgroundColor = UIColor(hex: "75b9f2")
        btn.addTarget(self, action: #selector(didTapCloseBtn), for: .touchUpInside)
        btn.cornerRadius = 32
        
        return btn
    }()
    
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let view = touches.first?.view, view != dialogView {
            dismiss(animated: true)
        }
    }
    
    func initialize() {

        //Background
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        addSubview(backgroundView)
        
        backgroundView.addSubview(dialogView)
        
        dialogView.cornerRadius = 48
        dialogView.backgroundColor = UIColor(hex: "e6f3ff")
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
        
        NSLayoutConstraint.activate([
            vButton.heightAnchor.constraint(equalToConstant: 96),
            vButton.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor),
            vButton.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor),
            vButton.bottomAnchor.constraint(equalTo: dialogView.bottomAnchor),
            
            btnAction.leadingAnchor.constraint(equalTo: vButton.leadingAnchor, constant: 16),
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
        dismiss(animated: true)
    }
}
