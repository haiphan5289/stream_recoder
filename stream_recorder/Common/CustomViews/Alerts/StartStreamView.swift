//
//  StartStreamView.swift
//  stream_recorder
//
//  Created by HHumorous on 08/04/2022.
//

import UIKit

protocol StartStreamViewDelegate: AnyObject {
    func didPrepareLivestreamDone()
    func didRetryConnect()
    func didCancelConnect()
}

class StartStreamView: UIView, Modal {
    var backgroundView: UIView = UIView()
    var dialogView: UIView = UIView()
    
    weak var delegate: StartStreamViewDelegate?
    
    lazy var lblTimer: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.sfMonoBold(size: 78)
        lbl.textColor = UIColor.white
        lbl.backgroundColor = UIColor(hex: "a190d4")
        lbl.clipsToBounds = true
        lbl.cornerRadius = 75
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "3"
        
        return lbl
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
    
    lazy var vLoading: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.hidesWhenStopped = true
        view.style = .large
        view.color = .black
        
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
        btn.setAttributedTitle(NSAttributedString(string: "Okay", attributes: [NSAttributedString.Key.font: UIFont.workSansMedium(size: 17), NSAttributedString.Key.foregroundColor: UIColor.white]), for: .normal)
        btn.backgroundColor = UIColor(hex: "886ddb")
        btn.addTarget(self, action: #selector(didTapActionBtn), for: .touchUpInside)
        btn.cornerRadius = 30
        
        return btn
    }()
    
    lazy var btnLater: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setAttributedTitle(NSAttributedString(string: "Retry", attributes: [NSAttributedString.Key.font: UIFont.workSansMedium(size: 17), NSAttributedString.Key.foregroundColor: UIColor.black]), for: .normal)
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
    
    enum ConnectState: Int {
        case connecting = 0
        case failed
        
        var titleButton: String {
            switch self {
            case .connecting:
                return "Cancel"
            case .failed:
                return "Retry"
            }
        }
        
        var backgroundColor: UIColor? {
            switch self {
            case .connecting:
                return UIColor(hex: "efedf4")
            case .failed:
                return UIColor(hex: "fff3f0")
            }
        }
    }
    
    var callback: ((Bool) -> Void)?
    var stateConnect: ConnectState = .connecting
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
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        addSubview(backgroundView)
        backgroundView.fillSuperview()
        
        backgroundView.addSubview(lblTimer)
        lblTimer.isHidden = true
        NSLayoutConstraint.activate([
            lblTimer.widthAnchor.constraint(equalToConstant: 150),
            lblTimer.heightAnchor.constraint(equalToConstant: 150),
            lblTimer.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            lblTimer.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
        ])
        
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
        dialogView.addSubview(vLoading)
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
            
            vLoading.centerXAnchor.constraint(equalTo: dialogView.centerXAnchor),
            vLoading.bottomAnchor.constraint(equalTo: lblTitle.topAnchor, constant: -20),
            vLoading.widthAnchor.constraint(equalToConstant: 76),
            vLoading.heightAnchor.constraint(equalToConstant: 76),
            vLoading.topAnchor.constraint(equalTo: dialogView.topAnchor, constant: 74),
                        
            imgIcon.leadingAnchor.constraint(equalTo: vLoading.leadingAnchor),
            imgIcon.trailingAnchor.constraint(equalTo: vLoading.trailingAnchor),
            imgIcon.topAnchor.constraint(equalTo: vLoading.topAnchor),
            imgIcon.bottomAnchor.constraint(equalTo: vLoading.bottomAnchor)
        ])
        
        updateUI()
    }
    
    func setupTimer() {
        if timer == nil {
            timer = CountdownService()
            timer?.start(beginingValue: 3, interval: 1, countDown: true)
            timer?.delegate = self
        }
    }
    
    func updateUISuccess() {
        vLoading.stopAnimating()
        self.lblTimer.isHidden = false
        self.lblTimer.alpha = 1
        self.dialogView.isHidden = true

        setupTimer()
    }
    
    func updateUIFalse() {
        stateConnect = .failed
        updateUI()
    }
    
    func updateUI() {
        self.btnAction.isHidden = self.stateConnect == .connecting
        if stateConnect == .connecting {
            vLoading.startAnimating()
            vButton.isHidden = true
        } else {
            vLoading.stopAnimating()
            vButton.isHidden = false
        }
        self.lblTimer.isHidden = true

        UIView.animate(withDuration: 0.25, delay: 0, options: [.layoutSubviews]) {
            self.dialogView.isHidden = false
            self.dialogView.alpha = 1
            self.dialogView.backgroundColor = self.stateConnect.backgroundColor
            self.btnAction.setTitle(self.stateConnect.titleButton, for: .normal)
            self.lblTitle.text = self.stateConnect == .connecting ? "Connecting to server..." : "Unable to connect to Server, please check your Stream Key & RTMP URL then try again"
            self.imgIcon.isHidden = self.stateConnect == .connecting
        } completion: { done in
            self.lblTimer.isHidden = true
        }
    }
    
    @objc func didTapCloseBtn() {
        if stateConnect == .connecting {
            dismiss(animated: true)
        } else {
            stateConnect = .connecting
            updateUI()
            delegate?.didRetryConnect()

        }
    }
    
    @objc func didTapActionBtn() {
//        dismiss(animated: true)
        stateConnect = .connecting
        updateUI()
        delegate?.didCancelConnect()
    }
}


extension StartStreamView: CountdownServiceDelegate {
    func timerDidUpdateCounterValue(newValue: Int) {
        lblTimer.text = String(format: "%i", newValue)
    }
    
    func timerDidEnd() {
        delegate?.didPrepareLivestreamDone()
    }
}
