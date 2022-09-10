//
//  AppDelegate.swift
//  stream_recorder
//
//  Created by Huy on 31/03/2022.
//

import UIKit
import Firebase
import SwiftyStoreKit
import GoogleMobileAds
import FaceCamFW
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var restrictRotation: UIInterfaceOrientationMask = .portrait
    weak var mainView: ApplicationStateObserver?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.shared.isIdleTimerDisabled = true
        
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "67d2e251d19dd5f5690b3c18b677cb28" ]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        SwiftyStoreKit.completeTransactions(atomically: true) { (purchases) in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    //Unlock content
                    print("productID " + purchase.productId)
                    
                case .failed, .purchasing, .deferred:
                    break
                @unknown default:
                    break
                }
            }
        }
       // AppOpenAdManager.shared.loadAd()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

//    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//        return self.restrictRotation
//    }
}

