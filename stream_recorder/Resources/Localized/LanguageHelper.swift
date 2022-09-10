//
//  LanguageHelper.swift
//  ScoreCam
//
//  Created by Rum on 26/12/2021.
//

import UIKit

enum AppLanguage: String, CaseIterable {
    case Vietnamese = "vi"
    case English = "en"
}

class LanguageHelper {
    
    static let shared = LanguageHelper()
    fileprivate var info: [String: String]?
    
    func getValue(forKey key: String) -> String {
        if let mInfo = info,
            let value = mInfo[key] {
            return value
        }
        return  NSLocalizedString(key,
                                  tableName: nil,
                                  bundle: Bundle.main,
                                  value: "", comment: "")
    }
}

