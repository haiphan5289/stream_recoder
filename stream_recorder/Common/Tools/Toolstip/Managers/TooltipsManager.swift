//
//  TooltipsManager.swift
//  SMessenger
//
//  Created by Huy on 24/03/2021.
//  Copyright © 2021 SMessenger. All rights reserved.
//

import UIKit

protocol Tooltip {
    var key: String {get}
    var view: UIView {get}
    var didShow: Bool {get}
    var title: String? {get}
    var message: String {get}
    var direction: TooltipDirection {get}
    
    func setShown()
}

extension Tooltip {
    func addSnapshot(to parentView: UIView?) {
        guard direction != .center else { return }
        parentView?.addSnapshot(of: view)
    }
}

protocol ToolTipDelegate: NSObject {
    func toolTipDidComplete()
}

class TooltipManager: NSObject {
    
    private var parentView: UIView?
    private var tooltipsToShow: [Tooltip] = []
    var didSetupTooltips: Bool = false
    
    weak var delegate: ToolTipDelegate?
    
    func setup(tooltips: [Tooltip], darkView: UIView) {
        didSetupTooltips = true
        
        tooltipsToShow = tooltips
        parentView = darkView
        
        guard !tooltipsToShow.allSatisfy({ $0.didShow }) else {
            delegate?.toolTipDidComplete()
            return
        }
        
        parentView?.addDarkView { [weak self] in
            //
        }
    }
}
