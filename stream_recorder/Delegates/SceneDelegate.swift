//
//  SceneDelegate.swift
//  stream_recorder
//
//  Created by Huy on 31/03/2022.
//

import UIKit
import SwiftyStoreKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var audioSession: AudioSession?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        let tabbar = BaseRootTabbar()
        window?.rootViewController = tabbar
        window?.makeKeyAndVisible()
        
        audioSession = AudioSession()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        audioSession?.activateAudioSession()
        //if let topVC = UIApplication.getTopViewController() {
            //AppOpenAdManager.shared.showAdIfAvailable(viewController: topVC)
       // }
        
        if Cache.shared.is_premium == false {
            return
        }
        self.verifyReceipt(env: .production)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        audioSession?.deactivateAudioSession()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    func verifyReceipt(env: AppleReceiptValidator.VerifyReceiptURLType) {
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: InApp.SercetKey)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            
            switch result {
            case .success(let receipt):
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(ofType: .autoRenewable, productIds: [InApp.Weekly, InApp.Monthly, InApp.Yearly], inReceipt: receipt)
                    
                switch purchaseResult {
                case .purchased( _, _):
                    Cache.shared.is_premium = true
                case .expired( _, _):
                    if env == .production {
                        self.verifyReceipt(env: .sandbox)
                    } else {
                        Cache.shared.is_premium = false
                    }
                case .notPurchased:
                    Cache.shared.is_premium = false
                    return
                }
            case .error(let error):
                if env == .production {
                    self.verifyReceipt(env: .sandbox)
                }
                print("Receipt verification failed: \(error)")
            }
        }
    }

}

