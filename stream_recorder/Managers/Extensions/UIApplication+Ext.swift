//
//  UIApplication+Ext.swift
//  OlaChat
//
//  Created by Rum on 17/11/2020.
//  Copyright © 2021 ABLabs - Tam Duc HD, Ltd. All rights reserved.
//

import UIKit

extension UIApplication {
    var keyWindowInConnectedScenes: UIWindow? {
        return windows.first(where: { $0.isKeyWindow })
    }
    
    @available(iOS 13.0, *)
    var currentScene: UIWindowScene? {
        connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
    
    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)

        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)

        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
    
    static var appLanguage:String
    {
        if let appLanguage = Locale.current.languageCode
        {
            return "\(appLanguage)"
        }
        return ""
    }
    
    static var appVersion:String
    {
        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        {
            return "\(appVersion)"
        }
        return ""
    }

    static var buildNumber:String
    {
        if let buildNum = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String)
        {
            return "\(buildNum)"
        }
        return ""
    }

    static var versionString:String
    {
        return "\(appVersion).\(buildNumber)"
    }
}

extension NSObject {
    var theClassName: String {
        return NSStringFromClass(type(of: self))
    }
}
