//
//  EndStreamAlert.swift
//  stream_recorder
//
//  Created by HHumorous on 05/04/2022.
//

import UIKit

class EndStreamAlert: UIView, Modal {
    var backgroundView: UIView = UIView()
    var dialogView: UIView = UIView()
    
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
    
    lazy var vCountdown: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hex: "886ddb")
        view.layer.cornerRadius = 24
        
        return view
    }()
    
    lazy var lblCountdown: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.sfMonoBold(size: 34)
        lbl.textColor = UIColor.white
        lbl.clipsToBounds = true
        lbl.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        lbl.layer.cornerRadius = 12
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.text = "5"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        return lbl
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
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.workSansMedium(size: 17)
        btn.backgroundColor = UIColor(hex: "fd663f")
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
    
    enum EndState: Int {
        case prepare = 0
        case end
        
        var titleButton: String {
            switch self {
            case .prepare:
                return "End Now"
            case .end:
                return "Okay"
            }
        }
        
        var colorButton: UIColor? {
            switch self {
            case .prepare:
                return UIColor(hex: "fd663f")
            case .end:
                return UIColor(hex: "886ddb")
            }
        }
        
        var backgroundColor: UIColor? {
            switch self {
            case .prepare:
                return UIColor(hex: "efedf4")
            case .end:
                return UIColor(hex: "f1f6ed")
            }
        }
    }
    
    var callback: ((Bool) -> Void)?
    var stateEnd: EndState = .prepare
    var timer: CountdownService?
    
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
        dialogView.addSubview(vCountdown)
        vCountdown.addSubview(lblCountdown)
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
            lblTitle.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 72),
            
            vCountdown.centerXAnchor.constraint(equalTo: dialogView.centerXAnchor),
            vCountdown.bottomAnchor.constraint(equalTo: lblTitle.topAnchor, constant: -20),
            vCountdown.widthAnchor.constraint(equalToConstant: 76),
            vCountdown.heightAnchor.constraint(equalToConstant: 76),
            vCountdown.topAnchor.constraint(equalTo: dialogView.topAnchor, constant: 74),
            
            lblCountdown.centerXAnchor.constraint(equalTo: vCountdown.centerXAnchor),
            lblCountdown.centerYAnchor.constraint(equalTo: vCountdown.centerYAnchor),
            lblCountdown.leadingAnchor.constraint(equalTo: vCountdown.leadingAnchor, constant: 12),
            lblCountdown.topAnchor.constraint(equalTo: vCountdown.topAnchor, constant: 12),
            
            imgIcon.leadingAnchor.constraint(equalTo: vCountdown.leadingAnchor),
            imgIcon.trailingAnchor.constraint(equalTo: vCountdown.trailingAnchor),
            imgIcon.topAnchor.constraint(equalTo: vCountdown.topAnchor),
            imgIcon.bottomAnchor.constraint(equalTo: vCountdown.bottomAnchor)
        ])
        
        if stateEnd == .prepare {
            setupTimer()
        }
        
        updateUI()
    }
    
    func setupTimer() {
        if timer == nil {
            timer = CountdownService()
            timer?.start(beginingValue: 5, interval: 1, countDown: true)
            timer?.delegate = self
        }
    }
    
    func updateUI() {
        self.btnLater.isHidden = self.stateEnd == .end
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.layoutSubviews]) {
            self.dialogView.backgroundColor = self.stateEnd.backgroundColor
            self.btnAction.setTitle(self.stateEnd.titleButton, for: .normal)
            self.btnAction.backgroundColor = self.stateEnd.colorButton
            self.lblTitle.text = self.stateEnd == .end ? "Stream Ended\nHappy Streaming!" : "Ending Stream..."
            self.vCountdown.isHidden = self.stateEnd == .end
            self.imgIcon.isHidden = self.stateEnd == .prepare
        }
    }
    
    @objc func didTapCloseBtn() {
        callback?(false)
        dismiss(animated: true)
    }
    
    @objc func didTapActionBtn() {
        if stateEnd == .prepare {
            stateEnd = .end
            updateUI()
        } else {
            callback?(true)
            dismiss(animated: true)
        }
    }
}

extension EndStreamAlert: CountdownServiceDelegate {
    func timerDidUpdateCounterValue(newValue: Int) {
        lblCountdown.text = String(format: "%i", newValue)
    }
    
    func timerDidEnd() {
        stateEnd = .end
        
        updateUI()
    }
}
