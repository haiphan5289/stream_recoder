//
//  TooltipsView.swift
//  SMessenger
//
//  Created by HHumorous on 24/03/2021.
//  Copyright © 2021 SMessenger. All rights reserved.
//

import UIKit

class TooltipsView: UIView {
    @IBOutlet weak var btnLogout: UIButton!
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var btnUser: UIButton!
    
    var removeCallback: (() -> Void)?
    private var timeoutTimer: Timer?
    
    static func newInstance() -> TooltipsView {
        return Bundle(for: self).loadNibNamed("TooltipView", owner: self, options: nil)![0] as! TooltipsView
    }
    
    deinit {
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true
    }
    
    func setupTimeout(_ timeout: TimeInterval) {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] (_) in
            self?.hide(with: false)
        }
    }
    
    func setupUI(user: String) {
        //Setup if no user
//        btnUser.isHidden = true
//        else btnUser.isHidden = false
        
        btnUser.setTitle(user, for: .normal)
    }
    
    // MARK: - Animations
    
    func show() {
        fadeIn()
    }
    
    func hide(with callback: Bool = true) {
        timeoutTimer?.invalidate()
        if callback {
            removeCallback?()
        }
        fadeOut {
            self.removeFromSuperview()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func login(_ sender: Any) {
        hide()
    }
    
    @IBAction func logout(_ sender: UIButton) {
        //
    }
}

extension UIView {
    func showTooltipsFor(user: String,
                     timeout: TimeInterval = 5,
                     direction: TooltipDirection,
                     inView: UIView? = nil,
                     onHide: (() -> Void)? = nil) {
        
        guard let superview = inView ?? superview else { return }
        removeTooltipView(from: superview)

        DispatchQueue.main.async {
            let tooltipView = TooltipsView.fromNib()
            tooltipView.setupUI(user: user)
            tooltipView.removeCallback = onHide
                        
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
            tooltipView.setupTimeout(timeout)
        }
    }
    
    public func removeTooltipView(from parentView: UIView? = nil) {
        if let _superView = parentView {
            DispatchQueue.main.async {
                for subview in _superView.subviews {
                    if let subview = subview as? TooltipsView {
                        subview.removeFromSuperview()
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                for subview in self.subviews {
                    if let subview = subview as? TooltipsView {
                        subview.removeFromSuperview()
                    }
                }
            }
        }
    }
}
