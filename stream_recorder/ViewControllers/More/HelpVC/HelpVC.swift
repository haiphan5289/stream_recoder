//
//  HelpVC.swift
//  stream_recorder
//
//  Created by Rum on 04/04/2022.
//

import UIKit
import StoreKit

class HelpVC: UIViewController {
    
    enum HelpRow: Int, CaseIterable {
        case record = 0
        case live
        case term
        case share
        case rate
        
        var title: String {
            switch self {
            case .record:
                return "How to Record Screen?"
            case .live:
                return "How to Live Stream?"
            case .term:
                return "Term & Privacy"
            case .share:
                return "Share this App"
            case .rate:
                return "Rate Us"
            }
        }
    }
    
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var tbvContent: UITableView!
    @IBOutlet weak var csHeightContentView: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let view = touches.first?.view, view != vContent {
            animateOut()
        }
    }
    
    func setupTableView() {
        tbvContent.delegate = self
        tbvContent.dataSource = self
        tbvContent.register(UINib(nibName: HelpCell.identifierCell, bundle: nil), forCellReuseIdentifier: HelpCell.identifierCell)
    }
    
    fileprivate func animateIn() {
        vContent.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        vContent.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.vContent.alpha = 1
            self.vContent.transform = CGAffineTransform.identity
        }
    }
    
    fileprivate func animateOut(completion: (() -> Void)? = nil)  {
        UIView.animate(withDuration: 0.25, animations: {
            self.vContent.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.vContent.alpha = 0
            
        }) { (true) in
            self.dismiss(animated: true, completion: completion)
        }
    }
}

extension HelpVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return HelpRow.allCases.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = HelpRow(rawValue: indexPath.row) else { return UITableViewCell() }
        let cell: HelpCell = tableView.dequeueReusableCell(withIdentifier: HelpCell.identifierCell, for: indexPath) as! HelpCell
        
        cell.lblTitle.text = item.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = HelpRow(rawValue: indexPath.row) else { return }
        switch item {
        case .record:
            self.openUrlWithSafari(url: "https://sites.google.com/view/xrecorderapp/how-to-use")
        case .live:
            self.openUrlWithSafari(url: "https://sites.google.com/view/xrecorderapp/how-to-use")
        case .term:
            self.openUrlWithSafari(url: "https://sites.google.com/view/xrecorderapp/terms-of-use")
        case .share:
            let activityVC = UIActivityViewController(activityItems:[UIImage(named: "logo")!, "Screen Recorder - Xrecorder", "https://apps.apple.com/app/id1619587129"], applicationActivities: nil)
            
            if let popOver = activityVC.popoverPresentationController {
                let cell = tableView.cellForRow(at: indexPath)
                popOver.sourceView = cell?.contentView
                popOver.sourceRect = (cell?.contentView.frame)!
            }
            
            self.present(activityVC, animated: true, completion: nil)
            break
        case .rate:
            guard let url = URL(string: "itms-apps://itunes.apple.com/app/id1619587129?ls=1&mt=8&action=write-review") else {
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            break
        }
    }
}
