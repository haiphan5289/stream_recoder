//
//  ProgressVideoAlert.swift
//  stream_recorder
//
//  Created by Rum on 16/04/2022.
//

import UIKit
import PixelSDK

class ProgressVideoAlert: UIView, Modal {
    var backgroundView: UIView = UIView()
    var dialogView: UIView = UIView()
    
    lazy var vProgress: KDCircularProgress = {
        let view = KDCircularProgress()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.startAngle = -90
        view.progressThickness = 0.3
        view.trackThickness = 0.5
        view.clockwise = true
        view.roundedCorners = false
        view.glowMode = .forward
        view.glowAmount = 0.9
        view.trackColor = UIColor.black.withAlphaComponent(0.5)
        view.progressColors = [UIColor(hex: "d9ecfc"), UIColor(hex: "a190d4"), UIColor(hex: "ff758e")]

        return view
    }()
    
    lazy var lblTitle: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.workSansMedium(size: 17)
        lbl.textColor = UIColor.black
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
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
        imv.image = #imageLiteral(resourceName: "icStreamFailed")
        
        return imv
    }()
    
    lazy var btnAction: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setAttributedTitle(NSAttributedString(string: "Save", attributes: [NSAttributedString.Key.font: UIFont.workSansMedium(size: 17), NSAttributedString.Key.foregroundColor: UIColor.white]), for: .normal)
        btn.backgroundColor = UIColor(hex: "886ddb")
        btn.addTarget(self, action: #selector(didTapActionBtn), for: .touchUpInside)
        btn.cornerRadius = 30
        
        return btn
    }()
    
    lazy var btnLater: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setAttributedTitle(NSAttributedString(string: "Cancel", attributes: [NSAttributedString.Key.font: UIFont.workSansMedium(size: 17), NSAttributedString.Key.foregroundColor: UIColor.black]), for: .normal)
        btn.backgroundColor = UIColor(hex: "f3f5f6")
        btn.addTarget(self, action: #selector(didTapCloseBtn), for: .touchUpInside)
        btn.cornerRadius = 30
        
        return btn
    }()
    
    lazy var stvButton: UIStackView = {
        let stv = UIStackView()
        stv.translatesAutoresizingMaskIntoConstraints = false
        stv.axis = .horizontal
        stv.alignment = .fill
        stv.distribution = .fill
        stv.spacing = 16
        
        return stv
    }()
    
    var callback: ((Bool, Session?) -> Void)?
    weak var currenSession: Session?
    
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
        dialogView.backgroundColor = UIColor(hex: "efedf4")
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dialogView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 16),
            dialogView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            dialogView.bottomAnchor.constraint(equalTo: backgroundView.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        dialogView.addSubview(lblTitle)
        dialogView.addSubview(imgIcon)
        dialogView.addSubview(vProgress)
        dialogView.addSubview(vButton)
        vButton.addSubview(stvButton)
        stvButton.addArrangedSubview(btnLater)
        stvButton.addArrangedSubview(btnAction)
        
        NSLayoutConstraint.activate([
            vButton.heightAnchor.constraint(equalToConstant: 96),
            vButton.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor),
            vButton.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor),
            vButton.bottomAnchor.constraint(equalTo: dialogView.bottomAnchor),
            
            stvButton.leadingAnchor.constraint(equalTo: vButton.leadingAnchor, constant: 16),
            stvButton.trailingAnchor.constraint(equalTo: vButton.trailingAnchor, constant: -16),
            stvButton.topAnchor.constraint(equalTo: vButton.topAnchor, constant: 16),
            stvButton.bottomAnchor.constraint(equalTo: vButton.bottomAnchor, constant: -16),
            
            btnLater.widthAnchor.constraint(equalTo: btnAction.widthAnchor),
            
            lblTitle.bottomAnchor.constraint(equalTo: vButton.topAnchor, constant: -55),
            lblTitle.centerXAnchor.constraint(equalTo: dialogView.centerXAnchor),
            lblTitle.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 52),
            
            vProgress.centerXAnchor.constraint(equalTo: dialogView.centerXAnchor),
            vProgress.bottomAnchor.constraint(equalTo: lblTitle.topAnchor, constant: -20),
            vProgress.widthAnchor.constraint(equalToConstant: 76),
            vProgress.heightAnchor.constraint(equalToConstant: 76),
            vProgress.topAnchor.constraint(equalTo: dialogView.topAnchor, constant: 74),
                        
            imgIcon.leadingAnchor.constraint(equalTo: vProgress.leadingAnchor),
            imgIcon.trailingAnchor.constraint(equalTo: vProgress.trailingAnchor),
            imgIcon.topAnchor.constraint(equalTo: vProgress.topAnchor),
            imgIcon.bottomAnchor.constraint(equalTo: vProgress.bottomAnchor)
        ])
        
        vProgress.isHidden = false
        btnAction.isHidden = true
        imgIcon.isHidden = true
        lblTitle.text = "Progressing"
    }
    
    func configureWith(sdkSession session: Session) {
        self.currenSession = session
        if let video = session.video {
            VideoExporter.shared.export(video: video, progress: { progress in
                self.vProgress.progress = progress
                self.lblTitle.text = "Progressing"
            }, completion: { error in
                if let _ = error {
                    self.updateUIFailed()
                    return
                }

                self.updateUIDone()
            })
        }
    }
    
    func updateUIDone() {
        imgIcon.image = #imageLiteral(resourceName: "icSavedSuccess")
        btnAction.isHidden = false
        vProgress.isHidden = true
        imgIcon.isHidden = false
        lblTitle.text = "Edit progress success. Let's save!"
    }
    
    func updateUIFailed() {
        imgIcon.image = #imageLiteral(resourceName: "icStreamFailed")
        btnAction.isHidden = false
        vProgress.isHidden = true
        imgIcon.isHidden = false
        lblTitle.text = "Edit progress failed. Please try later"
    }
    
    @objc func didTapCloseBtn() {
        callback?(false, currenSession)
        dismiss(animated: true)
    }
    
    @objc func didTapActionBtn() {
        callback?(true, currenSession)
        dismiss(animated: true)
    }
}
