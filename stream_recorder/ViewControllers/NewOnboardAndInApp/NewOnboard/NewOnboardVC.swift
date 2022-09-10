//
//  NewOnboardVC.swift
//  xrecorder
//
//  Created by Huy on 27/02/2021.
//

import UIKit
import CHIPageControl
import SwiftyStoreKit

enum OnboardTextPosition {
    case top
    case bottom
}

struct NewOnbroadInfo {
    var page: Int
    var pos: OnboardTextPosition
    var image: String
    var title: String
    var subtitle: String
    
    init(page: Int, pos: OnboardTextPosition = .top, image: String = "", title: String = "", subtitle: String = "") {
        self.page = page
        self.pos = pos
        self.image = image
        self.title = title
        self.subtitle = subtitle
    }
}

class NewOnboardVC: UIViewController {
    static func instantiate() -> NewOnboardVC {
        let sb = UIStoryboard(name: "NewOnboard", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "NewOnboardVC") as! NewOnboardVC
        return vc
    }
    
    @IBOutlet weak var broadCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: CHIPageControlJaloro!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    
    private var contentWidth: CGFloat = 0
    
    private var onbroad: [NewOnbroadInfo] = [
        NewOnbroadInfo(page: 0, pos: .bottom, image: "onboard-g1", title: "Xrecorder", subtitle: "Record, stream your games, apps and more"),
        NewOnbroadInfo(page: 1, image: "onboard-g2", title: "Smart Screen Broadcast", subtitle: "Record screen, pause or continue, sharing & stream your screen on your demand"),
        NewOnbroadInfo(page: 2, pos: .bottom, image: "onboard-g3", title: "Dual Face Cam", subtitle: "Play, stream & record together with your friend with our exclusive Dual Face Cam technology"),
        NewOnbroadInfo(page: 3, pos: .bottom, image: "onboard-g4", title: "Stream Anything", subtitle: "Powered streaming tools in your hand, live stream whatever you want"),
        NewOnbroadInfo(page: 4, image: "onboard-g5", title: "Multi-Platforms Streaming", subtitle: "Support 100+ stream platforms. Stream to 30+ platforms at the same time"),
        NewOnbroadInfo(page: 5, pos: .bottom, image: "onboard-g6", title: "Powerful Video Edit", subtitle: "Built-in video edittor with tons of useful tools help you produce faster"),
        NewOnbroadInfo(page: 6, image: "onboard-g7", title: "And Much More Features")
    ]
    
    override var shouldAutorotate: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDisplay()
        bind()
    }
    
    func setUpDisplay() {
        nextBtn.layoutIfNeeded()
        nextBtn.layer.cornerRadius = nextBtn.frame.height / 2
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if view.frame.height < view.frame.width {
                contentWidth = view.frame.width * 0.5
            } else {
                contentWidth = view.frame.width * 0.7
            }
            pageControl.transform = CGAffineTransform(scaleX: 2, y: 2)
        } else {
            contentWidth = view.frame.width
        }
    }
    
    func bind() {
        pageControl.delegate = self
        pageControl.enableTouchEvents = true
        pageControl.numberOfPages = onbroad.count
        pageControl.elementWidth = 16
        pageControl.tintColor = UIColor(hex: "ccc0b6").withAlphaComponent(0.3)
        pageControl.currentPageTintColor = UIColor(hex: "ff6f00")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(
            alongsideTransition: { [weak self] _ in
                guard let strongself = self,
                      let collectionView = strongself.broadCollectionView else {
                    return
                }
                if UIDevice.current.userInterfaceIdiom == .pad {
                    if size.height < size.width {
                        strongself.contentWidth = size.width * 0.5
                    } else {
                        strongself.contentWidth = size.width * 0.7
                    }
                } else {
                    strongself.contentWidth = size.width
                }
                collectionView.collectionViewLayout.invalidateLayout()
            },
            completion: { [weak self] _ in
                guard let strongself = self,
                      let collectionView = strongself.broadCollectionView else {
                    return
                }
                collectionView.reloadData()
                strongself.changePageAndScroll(index: strongself.pageControl.currentPage)
            }
        )
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    @IBAction func didTapbackButton(_ sender: Any) {
        if pageControl.currentPage == 0 {
            return
        }
        let newIndex = pageControl.currentPage - 1
        pageControl.set(progress: newIndex, animated: true)
        changePageAndScroll(index: newIndex)
    }
    
    @IBAction func didTapNextButton(_ sender: Any) {
        let newIndex = pageControl.currentPage + 1
        pageControl.set(progress: newIndex, animated: true)
        if nextBtn.tag == 1 {
            openRootPage()
            return
        }
        changePageAndScroll(index: newIndex)
    }
}

extension NewOnboardVC: CHIBasePageControlDelegate {
    func didTouch(pager: CHIBasePageControl, index: Int) {
        changePageAndScroll(index: index)
    }
}

extension NewOnboardVC: UICollectionViewDelegate {
    
}

extension NewOnboardVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return onbroad.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewBroadCollectionViewCell", for: indexPath) as! NewBroadCollectionViewCell
        cell.contentWidthConstraint.constant = contentWidth
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        changePage(indexPath: indexPath)
        let bcell = cell as! NewBroadCollectionViewCell
        bcell.layoutIfNeeded()
        bcell.bind(data: onbroad[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let visibleIndexPath = collectionView.indexPathsForVisibleItems.first {
            changePage(indexPath: visibleIndexPath)
        }
    }
}

extension NewOnboardVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
}

extension NewOnboardVC {
    func changePage(indexPath: IndexPath) {
        pageControl.set(progress: indexPath.row, animated: true)
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
            self.backBtn.isHidden = indexPath.row == 0
        }
        
        if pageControl.currentPage == onbroad.count - 1 {
            nextBtn.tag = 1
        } else {
            nextBtn.tag = 0
        }
    }
    
    func changePageAndScroll(index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        changePage(indexPath: indexPath)
        broadCollectionView.scrollToItem(at: indexPath, at: .right, animated: true)
    }
    
    func openRootPage() {
       // if RemoteConfigManager.sharedInstance.boolValue(forKey: .lockInApp11) == false {
            
        //} else {
        let vc: InappPremiumVC = .load(SB: .More)
            navigationController?.pushViewController(vc, animated: true)
       // }
    }
}
