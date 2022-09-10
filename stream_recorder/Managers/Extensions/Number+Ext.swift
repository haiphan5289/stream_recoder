//
//  Number+Ext.swift
//  ScoreCam
//
//  Created by Rum on 21/03/2022.
//

import UIKit

extension Int {
    func secondsToHoursMinutesSeconds() -> (Int, Int, Int) {
        return (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
    }
    
    func durationTimeToShortString() -> String {
        let (h, m, s) = self.secondsToHoursMinutesSeconds()
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
