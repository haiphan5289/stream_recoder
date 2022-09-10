//
//  TooltipsDirection.swift
//  SMessenger
//
//  Created by Huy on 24/03/2021.
//  Copyright © 2021 SMessenger. All rights reserved.
//

import Foundation

enum TooltipDirection {
    case up
    case down
    case right
    case left
    case center
    
    var isVertical: Bool {
        switch self {
        case .up, .down:
            return true
        default:
            return false
        }
    }
    
    var isHorizontal: Bool {
        switch self {
        case .right, .left:
            return true
        default:
            return false
        }
    }
}
