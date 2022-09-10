//
//  BaseTabBarVC.swift
//  stream_recorder
//
//  Created by HHumorous on 03/04/2022.
//

import UIKit
import SwiftyStoreKit
import GoogleMobileAds

protocol BaseTabbarDelegate: AnyObject {
    func didSelectTabbar(_ tabBar: SOTabBarController, at viewController: UIViewController)
}

class BaseTabBarVC: SOTabBarController {
    var csHeightAdsView: NSLayoutConstraint!
    
    weak var delegateTabbar: BaseTabbarDelegate?
    
    override func loadView() {
        super.loadView()
        
        SOTabBarSetting.tabBarCircleSize = CGSize(width: 48, height: 48)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        setupTabbarItem()
    }
    
    func setupTabbarItem() {
        let homeVC: HomeVC = .load(SB: .Home)
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "icHome"), selectedImage: UIImage(named: "icHomeSelected"))
        
        let videoVC: VideoVC = .load(SB: .Video)
        videoVC.tabBarItem = UITabBarItem(title: "Videos", image: UIImage(named: "icVideo"), selectedImage: UIImage(named: "icVideoSelected"))

        let settingVC: SettingVC = .load(SB: .More)
        settingVC.tabBarItem = UITabBarItem(title: "More", image: UIImage(named: "icMore"), selectedImage: UIImage(named: "icMoreSelected"))
        
        viewControllers = [homeVC, videoVC, settingVC]
    }
}

extension BaseTabBarVC: SOTabBarControllerDelegate {
    func tabBarController(_ tabBarController: SOTabBarController, didSelect viewController: UIViewController) {
        delegateTabbar?.didSelectTabbar(tabBarController, at: viewController)
    }
}

