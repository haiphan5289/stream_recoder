//
//  PremiumVC.swift
//  xrecorder
//
//  Created by Huy on 27/02/2021.
//

import UIKit
import SafariServices
import StoreKit
import SwiftyStoreKit
import SwiftOverlays

class PremiumVC: UIViewController {
    static func instantiate() -> PremiumVC {
        let sb = UIStoryboard(name: "NewOnboard", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "PremiumVC") as! PremiumVC
        return vc
    }
    
    // MARK: - Properties
    var startAtLevel: Int = 0
    var purchaseOptionIndex = 2
    
    // MARK: - Outlets
    @IBOutlet var mainView: CustomView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var lblMonth: UILabel!
    @IBOutlet weak var lblMonthPrice: UILabel!
    @IBOutlet weak var lblYear: UILabel!
    @IBOutlet weak var lblYearPrice: UILabel!
    @IBOutlet weak var vJoin: CustomView!
    @IBOutlet weak var vJoined: CustomView!
    @IBOutlet weak var openOnboardLbl: UILabel!
    
    @IBOutlet weak var priceStackView: UIStackView!
    @IBOutlet weak var monthView: CustomView!
    @IBOutlet weak var yearView: CustomView!
    @IBOutlet weak var subscriptionShortTerm: UILabel!
    @IBOutlet weak var inappPlanTitle: UILabel!
    
    @IBOutlet weak var month_price_width: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        closeBtn.isHidden = startAtLevel == 2
        vJoined.isHidden = Cache.shared.is_premium
        vJoin.isHidden = Cache.shared.is_premium
        
        if vJoin.isHidden {
           // mainView.firstColor = UIColor(hex: 0xf8a727)
          //  mainView.secondColor = UIColor(hex: 0xff2100)
        }
        // Do any additional setup after loading the view.
        addTapGestrue()
        setupDisplayView()
    }
    
    func setupDisplayView() {
        if SwiftyStoreKit.canMakePayments {
           // SwiftOverlays.showBlockingWaitOverlay()
            SwiftyStoreKit.retrieveProductsInfo([InApp.Weekly, InApp.Monthly, InApp.Yearly]) { [weak self] result in
                debugPrint(result.retrievedProducts)
                guard let strongself = self else {
                   // SwiftOverlays.removeAllBlockingOverlays()
                    return
                }
                if result.retrievedProducts.count == 0 {
                  //  SwiftOverlays.removeAllBlockingOverlays()
                    return
                }
                for product  in result.retrievedProducts {
                    if product.productIdentifier == InApp.Weekly{
                        strongself.updateButtonMonthlyView(product: product)
                    } else if product.productIdentifier == InApp.Monthly {
                        strongself.updateButtonAnnualView(product: product)
                    }
                }
                strongself.didTapPurchaseYearly()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func updateButtonMonthlyView(product: SKProduct) {
        if let priceString = product.localizedPrice {
            self.lblMonthPrice.text = priceString
        }
       // SwiftOverlays.removeAllBlockingOverlays()
    }
    
    func updateButtonAnnualView(product: SKProduct) {
        if let priceString = product.localizedPrice {
            self.lblYearPrice.text = priceString
        }
       // SwiftOverlays.removeAllBlockingOverlays()
    }
    
    // MARK: - Actions
    @IBAction func didTapRestorePurchase(_ sender: Any) {
        if !SwiftyStoreKit.canMakePayments {
            Alert.shared.errorMessage(message: "Can not make payment".localized, rootVC: self)
            return
        }
        
       // SwiftOverlays.showBlockingWaitOverlayWithText("WAITING".localized)
        self.restorePurchase(env: .production)
    }
    
    @IBAction func didTapTermOfUse(_ sender: Any) {
        let url = "https://sites.google.com/view/xrecorderapp/terms-of-use"
        self.openSafari(url: url)
    }
    
    @IBAction func didTapPrivacy(_ sender: Any) {

        let url = "https://sites.google.com/view/xrecorderapp/privacy-policy"
        debugPrint(url)
        self.openSafari(url: url)
    }
    
    @IBAction func onPressContinue(_ sender: UIButton) {
        if purchaseOptionIndex != 0 {
            
            // Make an payment
            switch purchaseOptionIndex {
            case 1:
                self.monthlySubscription()
            case 2:
                self.annualSubscription()
            default:
                self.monthlySubscription()
            }

        } else {
            let alertController = UIAlertController(title: "Alert", message: "Please choose an option!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func onPressDone(_ sender: UIButton) {
        if startAtLevel > 0 {
           // self.changeRootVC(to: TabbarViewController.instantiate())
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func onPressClose(_ sender: UIButton) {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Helpers
    func openSafari(url: String) {
        guard let url = URL(string: url) else { return }
        let safariVC = SFSafariViewController(url: url)
        self.present(safariVC, animated: true, completion: nil)
    }
    
    // Choose purchase option
    @objc func didTapPurchaseMonthly() {
        if purchaseOptionIndex == 2 {
            purchaseOptionIndex = 1
            
            //monthView.firstColor = UIColor(hex: 0xf8a727)
           // monthView.secondColor = UIColor(hex: 0xff2100)
           // yearView.firstColor = UIColor(hex: 0xa8a8a8)
           // yearView.secondColor = UIColor(hex: 0x888888)
            
            DispatchQueue.main.async {
                self.month_price_width.constant = self.priceStackView.width * 0.7
                self.monthView.updateView()
                self.yearView.updateView()
            }
        }
    }
    
    @objc func didTapPurchaseYearly() {
        if purchaseOptionIndex == 1 {
            purchaseOptionIndex = 2
            
//            yearView.firstColor = UIColor(hex: 0xf8a727)
//            yearView.secondColor = UIColor(hex: 0xff2100)
//            monthView.firstColor = UIColor(hex: 0xa8a8a8)
//            monthView.secondColor = UIColor(hex: 0x888888)
            
            DispatchQueue.main.async {
                self.month_price_width.constant = self.priceStackView.width * 0.3
                self.monthView.updateView()
                self.yearView.updateView()
            }
        }
    }
    
    @objc func didTapOpenOnboard() {
       // changeRootVC(to: NewOnboardVC.instantiate())
    }
    
    func addTapGestrue() {
        let tapMonthly = UITapGestureRecognizer(target: self, action: #selector(didTapPurchaseMonthly))
        monthView.addGestureRecognizer(tapMonthly)
        
        let tapYearly = UITapGestureRecognizer(target: self, action: #selector(didTapPurchaseYearly))
        yearView.addGestureRecognizer(tapYearly)
        
        let tapOpenOnboard = UITapGestureRecognizer(target: self, action: #selector(didTapOpenOnboard))
        openOnboardLbl.addGestureRecognizer(tapOpenOnboard)
    }
    
    func didFinishPurchase() {
        let transitionOptions: UIView.AnimationOptions = [.transitionFlipFromLeft, .showHideTransitionViews]

        UIView.transition(with: vJoin, duration: 0.7, options: transitionOptions, animations: {
            self.vJoin.alpha = 0

        }) { (finish) in
            self.vJoin.isHidden = true
        }

        UIView.transition(with: vJoined, duration: 0.7, options: transitionOptions, animations: {
            self.vJoined.alpha = 1
            self.vJoined.isHidden = false
        }) { (finish) in
            // do somethings
        }
    }
}
