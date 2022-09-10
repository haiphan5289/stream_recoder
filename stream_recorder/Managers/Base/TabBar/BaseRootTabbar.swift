//
//  BaseRootTabbar.swift
//  stream_recorder
//
//  Created by HHumorous on 03/06/2022.
//

import UIKit
import SwiftyStoreKit
import GoogleMobileAds

class BaseRootTabbar: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    lazy var vAds: GADBannerView = {
        let view = GADBannerView()
        view.isHidden = true
        view.backgroundColor = .red
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    let tabbar = BaseTabBarVC()
    var csHeightAdsView: NSLayoutConstraint!
    var interstitial: GADInterstitialAd?

    deinit {
        DLog("BaseRootTabbar deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupChildrenViewController()
        RemoteConfigManager.sharedInstance.loadingDoneCallback = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                let appMode = RemoteConfigManager.sharedInstance.numberValue(forKey: .appModeV19)
                if ((Cache.shared.app_launch == false && appMode == 3) || (appMode == 2 && Cache.shared.is_premium == false)) {
                    let onboardVC: NewOnboardVC = .load(SB: .Onboard)
                    let nav = UINavigationController(rootViewController: onboardVC)
                    nav.modalPresentationStyle = .fullScreen
                    Cache.shared.app_launch = true
                    self?.parent?.present(nav, animated: true)
                } else {
                    SwiftyStoreKit.shouldAddStorePaymentHandler = { [weak self] payment, product in
                        let vc: InappPremiumVC = .load(SB: .More)
                        vc.pageMode = 2
                        self?.present(vc, animated: true, completion: nil)
                        return false
                    }
                }
            }
         }
        loadInterstitial()

    }
    
    func setupChildrenViewController() {
        view.backgroundColor = UIColor(hex: "212529")
        tabbar.willMove(toParent: self)
        tabbar.delegateTabbar = self
        addChild(tabbar)
        tabbar.view.translatesAutoresizingMaskIntoConstraints = false
        tabbar.didMove(toParent: self)
        view.addSubview(tabbar.view)
        view.addSubview(vAds)
        csHeightAdsView = tabbar.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            tabbar.view.topAnchor.constraint(equalTo: view.topAnchor),
            tabbar.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabbar.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            csHeightAdsView,
            
            vAds.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vAds.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vAds.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            vAds.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func setupAdBanner() {
//        if let tabbarAd = RemoteConfigManager.sharedInstance.stringValue(forKey: .adTabbar) {
//            if tabbarAd != "" {
//                view.layoutIfNeeded()
//                vAds.layer.addBorder(edge: .top, color: .color_F2F2F2, thickness: 1)
//
//                let adManager = AdManager.sharedInstance
//                adManager.setupAdBannerView(adBannerView: vAds, toView: self, adUnitID: tabbarAd)
//                vAds.delegate = self
//            }
//        }
    }
    
    func toogleAdsView(showAds: Bool) {
        DispatchQueue.main.async {
            self.vAds.isHidden = !showAds
            self.csHeightAdsView.constant = showAds ? -50 : 0
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        
    }
    
    fileprivate func loadInterstitial() {
        
        if Cache.shared.is_premium {
            print("User premium")
            return
        }
        
        let request = GADRequest()
        GADInterstitialAd.load(
            withAdUnitID: Ads.Fullscreen, request: request
        ) { (ad, error) in
          if let error = error {
            print("Failed to load interstitial ad with error: \(error.localizedDescription)")
            return
          }
          self.interstitial = ad
          self.interstitial?.fullScreenContentDelegate = self
        }
      }
}

extension BaseRootTabbar: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        toogleAdsView(showAds: true)
    }
}

extension BaseRootTabbar: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        loadInterstitial()
    }
}

extension BaseRootTabbar: BaseTabbarDelegate {
    func didSelectTabbar(_ tabBar: SOTabBarController, at viewController: UIViewController) {
        if let ad = self.interstitial {
          ad.present(fromRootViewController: self)
        } else {
          print("Ad wasn't ready")
        }
    }
}
