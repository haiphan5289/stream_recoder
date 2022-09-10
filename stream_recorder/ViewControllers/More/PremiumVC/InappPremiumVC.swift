//
//  PremiumVC.swift
//  stream_recorder
//
//  Created by Rum on 04/04/2022.
//

import UIKit
import SwiftyStoreKit
import StoreKit

class PremiumPack: NSObject {
    var title: String = ""
    var identifier: String = ""
    var price: String = ""
}

class InappPremiumVC: UIViewController {
    
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var vSubcribe: UIView!
    @IBOutlet weak var tbvContent: UITableView!
    @IBOutlet weak var csHeightContentView: NSLayoutConstraint!
    
    @IBOutlet weak var btnClose: UIButton!
    var listPack: [PremiumPack] = []
    
    var selectedPack = PremiumPack()
    
    var pageMode:Int = 1 // 1: từ intro đi vào, 2: từ app mở màn in-app
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appMode = RemoteConfigManager.sharedInstance.numberValue(forKey: .appModeV19)
        
        if pageMode == 1 && appMode == 2 {
            btnClose.isHidden = true
        }
        
        if SwiftyStoreKit.canMakePayments {
            self.showWaitOverlay()
            SwiftyStoreKit.retrieveProductsInfo([InApp.Weekly, InApp.Monthly, InApp.Yearly]) { [weak self] result in
                debugPrint(result.retrievedProducts)
                guard let strongself = self else {
                    self?.removeAllOverlays()
                    return
                }
                if result.retrievedProducts.count == 0 {
                    strongself.removeAllOverlays()
                    return
                }
                var weeklyId:SKProduct? = nil
                var monthlyId:SKProduct? = nil
                var yearlyId:SKProduct? = nil
                for product  in result.retrievedProducts {
                    if product.productIdentifier == InApp.Weekly {
                        weeklyId = product
                    } else if product.productIdentifier == InApp.Monthly {
                        monthlyId = product
                    } else if product.productIdentifier == InApp.Yearly {
                        yearlyId = product
                    }
                }
                let pack0 = PremiumPack()
                pack0.title = "Weekly"
                pack0.identifier = InApp.Weekly
                pack0.price = weeklyId?.localizedPrice ?? "-"
                
                let pack1 = PremiumPack()
                pack1.title = "Monthly"
                pack1.identifier = InApp.Monthly
                pack1.price = monthlyId?.localizedPrice ?? "-"
                
                let pack2 = PremiumPack()
                pack2.title = "Yearly"
                pack2.identifier = InApp.Yearly
                pack2.price = yearlyId?.localizedPrice ?? "-"
                
                self?.listPack.append(contentsOf: [pack0, pack1, pack2])
                self?.selectedPack = pack2
                
                self?.setupTableView()
                self?.setupUI()
                self?.tbvContent.reloadData()
                self?.removeAllOverlays()
            }
        }
    }
    
    func setupTableView() {
        tbvContent.delegate = self
        tbvContent.dataSource = self
        tbvContent.register(UINib(nibName: PremiumCell.identifierCell, bundle: nil), forCellReuseIdentifier: PremiumCell.identifierCell)
    }
    
    func setupUI() {
        vContent.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        vContent.layer.cornerRadius = 30
        vSubcribe.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        vSubcribe.layer.cornerRadius = 30
    }
    
    @IBAction func onPressClose(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func onPressSubcribe(_ sender: UIButton) {
        self.showWaitOverlay()
        SwiftyStoreKit.purchaseProduct(selectedPack.identifier, atomically: true) { [weak self] result in
            self?.removeAllOverlays()
            switch result {
            case .success(_):
                Cache.shared.is_premium = true
                self?.dismiss(animated: true)
                Alert.shared.successMessage(message: "Purchase success full".localized, rootVC: self!)
                break
            case .error(let error) :
                Alert.shared.errorMessage(message: error.localizedDescription, rootVC: self)
                break
            }
        }
    }
}

extension InappPremiumVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PremiumCell = tableView.dequeueReusableCell(withIdentifier: PremiumCell.identifierCell, for: indexPath) as! PremiumCell
        
        cell.delegate = self
        cell.lblYear.text = listPack[2].title
        cell.lblYearPrice.text = listPack[2].price
        cell.lblMonth.text = listPack[1].title
        cell.lblMonthPrice.text = listPack[1].price
        cell.lblWeek.text = listPack[0].title
        cell.lblWeekPrice.text = listPack[0].price
        cell.stViewIntro.isHidden = (pageMode == 1) ? false : true
        
        if selectedPack == listPack[0] {
            cell.lblMonth.textColor = UIColor.black
            cell.lblMonthPrice.textColor = UIColor.black
            cell.lblYear.textColor = UIColor.black
            cell.lblYearPrice.textColor = UIColor.black
            cell.lblWeek.textColor = .white
            cell.lblWeekPrice.textColor = .white
            cell.vWeek.firstColor = UIColor(hex: "f8a727")
            cell.vWeek.secondColor = UIColor(hex: "ff2100")
            cell.vYear.firstColor = UIColor(hex: "a8a8a8")
            cell.vYear.secondColor = UIColor(hex: "888888")
            cell.vMonth.firstColor = UIColor(hex: "a8a8a8")
            cell.vMonth.secondColor = UIColor(hex: "888888")
        } else if selectedPack == listPack[1] {
            cell.lblMonth.textColor = UIColor.white
            cell.lblMonthPrice.textColor = UIColor.white
            cell.lblYear.textColor = UIColor.black
            cell.lblYearPrice.textColor = UIColor.black
            cell.lblWeek.textColor = .black
            cell.lblWeekPrice.textColor = .black
            cell.vMonth.firstColor = UIColor(hex: "f8a727")
            cell.vMonth.secondColor = UIColor(hex: "ff2100")
            cell.vYear.firstColor = UIColor(hex: "a8a8a8")
            cell.vYear.secondColor = UIColor(hex: "888888")
            cell.vWeek.firstColor = UIColor(hex: "a8a8a8")
            cell.vWeek.secondColor = UIColor(hex: "888888")
        } else {
            cell.lblMonth.textColor = UIColor.black
            cell.lblMonthPrice.textColor = UIColor.black
            cell.lblYear.textColor = UIColor.white
            cell.lblYearPrice.textColor = UIColor.white
            cell.lblWeek.textColor = .black
            cell.lblWeekPrice.textColor = .black
            cell.vYear.firstColor = UIColor(hex: "f8a727")
            cell.vYear.secondColor = UIColor(hex: "ff2100")
            cell.vWeek.firstColor = UIColor(hex: "a8a8a8")
            cell.vWeek.secondColor = UIColor(hex: "888888")
            cell.vMonth.firstColor = UIColor(hex: "a8a8a8")
            cell.vMonth.secondColor = UIColor(hex: "888888")
        }
                
        return cell
    }
}

extension InappPremiumVC: PremiumCellDelegate {
    func onPressOption(cell: PremiumCell, sender: UIButton) {
        selectedPack = listPack[sender.tag]
        if sender.tag == 0 {
            cell.lblMonth.textColor = UIColor.black
            cell.lblMonthPrice.textColor = UIColor.black
            cell.lblYear.textColor = UIColor.black
            cell.lblYearPrice.textColor = UIColor.black
            cell.lblWeek.textColor = .white
            cell.lblWeekPrice.textColor = .white
            cell.vWeek.firstColor = UIColor(hex: "f8a727")
            cell.vWeek.secondColor = UIColor(hex: "ff2100")
            cell.vYear.firstColor = UIColor(hex: "a8a8a8")
            cell.vYear.secondColor = UIColor(hex: "888888")
            cell.vMonth.firstColor = UIColor(hex: "a8a8a8")
            cell.vMonth.secondColor = UIColor(hex: "888888")
        } else if sender.tag == 1 {
            cell.lblMonth.textColor = UIColor.white
            cell.lblMonthPrice.textColor = UIColor.white
            cell.lblYear.textColor = UIColor.black
            cell.lblYearPrice.textColor = UIColor.black
            cell.lblWeek.textColor = .black
            cell.lblWeekPrice.textColor = .black
            cell.vMonth.firstColor = UIColor(hex: "f8a727")
            cell.vMonth.secondColor = UIColor(hex: "ff2100")
            cell.vYear.firstColor = UIColor(hex: "a8a8a8")
            cell.vYear.secondColor = UIColor(hex: "888888")
            cell.vWeek.firstColor = UIColor(hex: "a8a8a8")
            cell.vWeek.secondColor = UIColor(hex: "888888")
        } else {
            cell.lblMonth.textColor = UIColor.black
            cell.lblMonthPrice.textColor = UIColor.black
            cell.lblYear.textColor = UIColor.white
            cell.lblYearPrice.textColor = UIColor.white
            cell.lblWeek.textColor = .black
            cell.lblWeekPrice.textColor = .black
            cell.vYear.firstColor = UIColor(hex: "f8a727")
            cell.vYear.secondColor = UIColor(hex: "ff2100")
            cell.vWeek.firstColor = UIColor(hex: "a8a8a8")
            cell.vWeek.secondColor = UIColor(hex: "888888")
            cell.vMonth.firstColor = UIColor(hex: "a8a8a8")
            cell.vMonth.secondColor = UIColor(hex: "888888")
        }
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            cell.layoutIfNeeded()
        }
    }
    
    func onPressIntro(cell: PremiumCell, sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func onPressRestore(cell: PremiumCell, sender: UIButton) {
        self.showWaitOverlay()
        restorePurchase(env: .production)
    }
    
    func onPressTerm(cell: PremiumCell, sender: UIButton) {
        self.openUrlWithSafari(url: "https://sites.google.com/view/xrecorderapp/terms-of-use")
    }
    
    func restorePurchase(env: AppleReceiptValidator.VerifyReceiptURLType) {
        self.showWaitOverlay()
        SwiftyStoreKit.restorePurchases { [weak self] results in
            if results.restoreFailedPurchases.count > 0 {
                self?.removeAllOverlays()
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
                    self?.removeAllOverlays()
                }
                
            } else {
                Alert.shared.errorMessage(message: "Can not restore purchase".localized, rootVC: self!)
                self?.removeAllOverlays()
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
                    Alert.shared.successMessage(message: "Purchase success".localized, rootVC: self!)
                    self?.removeAllOverlays()
                case .expired( _, _):
                    if env == .production {
                        self?.verifyReceipt(env: .sandbox)
                    } else {
                        Cache.shared.is_premium = false
                        Alert.shared.errorMessage(message: "Your purchase has expired".localized, rootVC: self!)
                        self?.removeAllOverlays()
                    }
                case .notPurchased:
                    Cache.shared.is_premium = false
                    Alert.shared.errorMessage(message: "Can not restore purchase".localized, rootVC: self!)
                    self?.removeAllOverlays()
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
}
