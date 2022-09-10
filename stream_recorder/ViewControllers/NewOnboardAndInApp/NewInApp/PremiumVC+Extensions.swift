//
//  PremiumVC+Extensions.swift
//  xrecorder
//
//  Created by Huy on 27/02/2021.
//

import UIKit
import SwiftyStoreKit
import StoreKit
import SwiftOverlays

// MARK: - SwiftyStoreKit
extension PremiumVC {
    func restorePurchase(env: AppleReceiptValidator.VerifyReceiptURLType) {
        SwiftyStoreKit.restorePurchases { [weak self] results in
            if results.restoreFailedPurchases.count > 0 {
                SwiftOverlays.removeAllBlockingOverlays()
                Alert.shared.errorMessage(message: (results.restoreFailedPurchases.first?.0.localizedDescription)!, rootVC: self!)
            } else if results.restoredPurchases.count > 0 {
                var shouldVerifyReceipt = false
                
                for purchase in results.restoredPurchases {
                    if (purchase.productId == InApp.Weekly || purchase.productId == InApp.Monthly || purchase.productId == InApp.Yearly) {
                        shouldVerifyReceipt = true
                        break
                    }
                }
                if (shouldVerifyReceipt) {
                    self?.verifyReceipt(env: .production)
                } else {
                    SwiftOverlays.removeAllBlockingOverlays()
                }
                
            } else {
                Alert.shared.errorMessage(message: "CANNOT_RESTORE_NO_PURCHASE".localized, rootVC: self!)
                SwiftOverlays.removeAllBlockingOverlays()
            }
        }
    }
    
    func verifyReceipt(env: AppleReceiptValidator.VerifyReceiptURLType) {
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: InApp.SercetKey)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { [weak self] result in
            switch result {
            case .success(let receipt):
                //let productId = [App.InAppPremium, App.InAppAnnualPremium]
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(ofType: .autoRenewable, productIds: [InApp.Weekly, InApp.Monthly, InApp.Yearly], inReceipt: receipt)
                    
                switch purchaseResult {
                case .purchased( _, _):
                    Cache.shared.is_premium = true
                    self?.didFinishPurchase()
                    Alert.shared.successMessage(message: "Purchase success".localized, rootVC: self!)
                    SwiftOverlays.removeAllBlockingOverlays()
                case .expired( _, _):
                    if env == .production {
                        self?.verifyReceipt(env: .sandbox)
                    } else {
                        Cache.shared.is_premium = false
                        Alert.shared.errorMessage(message: "Purchase expired".localized, rootVC: self!)
                        SwiftOverlays.removeAllBlockingOverlays()
                    }
                case .notPurchased:
                    Cache.shared.is_premium = false
                    Alert.shared.errorMessage(message: "Can not restore purchase".localized, rootVC: self!)
                    SwiftOverlays.removeAllBlockingOverlays()
                    return
                }
            case .error(let error):
                if env == .production {
                    self?.verifyReceipt(env: .sandbox)
                }
                debugPrint("Receipt verification failed: \(error)")
            }
        }
    }
    
    func monthlySubscription() {
        //self.subsciptionAction(productId: App.InAppPremium)
    }
    
    func annualSubscription() {
        //self.subsciptionAction(productId: App.InAppAnnualPremium)
    }
    
    func subsciptionAction(productId: String) {
        SwiftOverlays.showBlockingWaitOverlayWithText("WAITING".localized)
        SwiftyStoreKit.purchaseProduct(productId, atomically: true) { [weak self] result in
            SwiftOverlays.removeAllBlockingOverlays()
            switch result {
            case .success(_):
                Cache.shared.is_premium = true
                self?.didFinishPurchase()
                Alert.shared.successMessage(message: "Purchase success".localized, rootVC: self!)
               // self?.changeRootVC(to: TabbarViewController.instantiate())
                break
            case .error(let error) :
                Alert.shared.errorMessage(message: error.localizedDescription, rootVC: self!)
                break
            }
        }
    }
}
