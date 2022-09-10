//
//  UserDefault+Ext.swift
//  stream_recorder
//
//  Created by HHumorous on 07/04/2022.
//

import UIKit

extension UserDefaults {
    @objc dynamic var broadcastState: Int {
        return integer(forKey: "broadcastState")
    }
    
    @objc dynamic var streamingState: Int {
        return integer(forKey: "streamingState")
    }
}
