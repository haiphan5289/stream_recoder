//
//  OptionsView.swift
//  Live Now
//
//  Created by Huy on 02/04/2021.
//

import UIKit

enum ConfigVideoAudioMode: Int {
    case audio = 0
    case resolution
    case frame
    case format
}

class OptionsView: UIView {
    
    @IBOutlet weak var stvContent: UIStackView!
    
    var optionCallback: (() -> Void)?
    
    var mode: ConfigVideoAudioMode = .audio
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        translatesAutoresizingMaskIntoConstraints = false
        addShadowDecorate(radius: 20, maskCorner: [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner], shadowColor: UIColor.black.withAlphaComponent(0.17), shadowOffset: CGSize(width: 0, height: 1), shadowRadius: 20, shadowOpacity: 40)
        backgroundColor = .white
        isHidden = true
    }
    
    func setupUI(mode: ConfigVideoAudioMode) {
        self.mode = mode
        
        switch mode {
        case .audio:
            let options = Audio_Quality.allCases
            options.forEach { (option) in
                let btn = UIButton()
                btn.backgroundColor = UIColor(hex: "f9f9f9")
                btn.translatesAutoresizingMaskIntoConstraints = false
                btn.tag = option.rawValue
                btn.addTarget(self, action: #selector(onSelectOption(_ :)), for: .touchUpInside)
                btn.contentHorizontalAlignment = .left
                btn.cornerRadius = 14
                
                btn.setAttributedTitle(NSAttributedString(string: option.title, attributes: [NSAttributedString.Key.font: UIFont.workSansRegular(size: 17), NSAttributedString.Key.foregroundColor: UIColor.black]), for: .normal)
                if option == Cache.shared.audio_quality {
                    btn.setImage(#imageLiteral(resourceName: "icCheck"), for: .normal)
                    btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 220, bottom: 0, right: 0)
                    btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
                } else {
                    btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
                }
                
                NSLayoutConstraint.activate([
                    btn.heightAnchor.constraint(equalToConstant: 48),
                    btn.widthAnchor.constraint(equalToConstant: 258)
                ])
                stvContent.addArrangedSubview(btn)
            }
        case .resolution:
            let options = Video_Resolution.allCases
            options.forEach { (option) in
                let btn = UIButton()
                btn.backgroundColor = UIColor(hex: "f9f9f9")
                btn.translatesAutoresizingMaskIntoConstraints = false
                btn.tag = option.rawValue
                btn.addTarget(self, action: #selector(onSelectOption(_ :)), for: .touchUpInside)
                btn.contentHorizontalAlignment = .left
                btn.cornerRadius = 14
                
                btn.setAttributedTitle(NSAttributedString(string: option.title, attributes: [NSAttributedString.Key.font: UIFont.workSansRegular(size: 17), NSAttributedString.Key.foregroundColor: UIColor.black]), for: .normal)
                if option == Cache.shared.video_resolution {
                    btn.setImage(#imageLiteral(resourceName: "icCheck"), for: .normal)
                    btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 220, bottom: 0, right: 0)
                    btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
                } else {
                    btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
                }
                
                NSLayoutConstraint.activate([
                    btn.heightAnchor.constraint(equalToConstant: 48),
                    btn.widthAnchor.constraint(equalToConstant: 258)
                ])
                stvContent.addArrangedSubview(btn)
            }
        case .frame:
            let options = Video_Framerate.allCases
            options.forEach { (option) in
                let btn = UIButton()
                btn.backgroundColor = UIColor(hex: "f9f9f9")
                btn.translatesAutoresizingMaskIntoConstraints = false
                btn.tag = option.rawValue
                btn.addTarget(self, action: #selector(onSelectOption(_ :)), for: .touchUpInside)
                btn.contentHorizontalAlignment = .left
                btn.cornerRadius = 14
                
                btn.setAttributedTitle(NSAttributedString(string: option.title, attributes: [NSAttributedString.Key.font: UIFont.workSansRegular(size: 17), NSAttributedString.Key.foregroundColor: UIColor.black]), for: .normal)
                if option == Cache.shared.video_framerate {
                    btn.setImage(#imageLiteral(resourceName: "icCheck"), for: .normal)
                    btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 220, bottom: 0, right: 0)
                    btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
                } else {
                    btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
                }
                
                NSLayoutConstraint.activate([
                    btn.heightAnchor.constraint(equalToConstant: 48),
                    btn.widthAnchor.constraint(equalToConstant: 258)
                ])
                stvContent.addArrangedSubview(btn)
            }
        default:
            let options = Video_Format.allCases
            options.forEach { (option) in
                let btn = UIButton()
                btn.backgroundColor = UIColor(hex: "f9f9f9")
                btn.translatesAutoresizingMaskIntoConstraints = false
                btn.tag = option.rawValue
                btn.addTarget(self, action: #selector(onSelectOption(_ :)), for: .touchUpInside)
                btn.contentHorizontalAlignment = .left
                btn.cornerRadius = 14
                
                btn.setAttributedTitle(NSAttributedString(string: option.title, attributes: [NSAttributedString.Key.font: UIFont.workSansRegular(size: 17), NSAttributedString.Key.foregroundColor: UIColor.black]), for: .normal)
                if option == Cache.shared.video_format {
                    btn.setImage(#imageLiteral(resourceName: "icCheck"), for: .normal)
                    btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 220, bottom: 0, right: 0)
                    btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
                } else {
                    btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
                }
                
                NSLayoutConstraint.activate([
                    btn.heightAnchor.constraint(equalToConstant: 48),
                    btn.widthAnchor.constraint(equalToConstant: 258)
                ])
                stvContent.addArrangedSubview(btn)
            }
        }
    }
    
    // MARK: - Animations
    
    func show() {
        fadeIn()
    }
    
    func hide() {
        optionCallback?()
        fadeOut {
            self.removeFromSuperview()
        }
    }
    
    @objc func onSelectOption(_ sender: UIButton) {
        switch self.mode {
        case .audio:
            Cache.shared.audio_quality = Audio_Quality(rawValue: sender.tag) ?? .veryhigh
        case .resolution:
            Cache.shared.video_resolution = Video_Resolution(rawValue: sender.tag) ?? ._4k
        case .frame:
            Cache.shared.video_framerate = Video_Framerate(rawValue: sender.tag) ?? ._60fps
        default:
            Cache.shared.video_format = Video_Format(rawValue: sender.tag) ?? ._16_9
        }
        
        hide()
    }
}

extension UIView {
    func showVideoOption(mode: ConfigVideoAudioMode,
                     direction: TooltipDirection,
                     inView: UIView? = nil,
                     onHide: (() -> Void)? = nil) {
        
        guard let superview = inView ?? superview else { return }
        removeVideoOptionView(from: superview)

        DispatchQueue.main.async {
            let tooltipView = OptionsView.fromNib()
            tooltipView.setupUI(mode: mode)
            tooltipView.optionCallback = onHide
                        
            superview.addSubview(tooltipView)
            
            switch direction {
            case .up:
                NSLayoutConstraint.activate([
                    tooltipView.bottomAnchor.constraint(equalTo: self.topAnchor, constant: 0),
                    tooltipView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
                    tooltipView.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: 24)
                ])
            case .down:
                NSLayoutConstraint.activate([
                    tooltipView.topAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
                    tooltipView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
                    tooltipView.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: 24)
                ])
            case .left:
                NSLayoutConstraint.activate([
                    tooltipView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
                    tooltipView.trailingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
                    tooltipView.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: 8)
                ])
            case .right:
                break
            case .center:
                break
            }
            
            tooltipView.show()
        }
    }
    
    public func removeVideoOptionView(from parentView: UIView? = nil) {
        if let _superView = parentView {
            DispatchQueue.main.async {
                for subview in _superView.subviews {
                    if let subview = subview as? OptionsView {
                        subview.removeFromSuperview()
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                for subview in self.subviews {
                    if let subview = subview as? OptionsView {
                        subview.removeFromSuperview()
                    }
                }
            }
        }
    }
}
