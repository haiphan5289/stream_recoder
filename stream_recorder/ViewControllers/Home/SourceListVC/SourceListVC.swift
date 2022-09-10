//
//  SourceListVC.swift
//  stream_recorder
//
//  Created by HHumorous on 05/04/2022.
//

import UIKit

class SourceListVC: UIViewController {
    
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var tbvContent: UITableView!
    @IBOutlet weak var csHeightContentView: NSLayoutConstraint!
    @IBOutlet weak var lblTitle: UILabel!

    var callback: (() -> Void)?

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
        tbvContent.register(UINib(nibName: SourceCell.identifierCell, bundle: nil), forCellReuseIdentifier: SourceCell.identifierCell)
    }
    
    fileprivate func animateIn() {
        vContent.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        vContent.alpha = 0
        lblTitle.transform = CGAffineTransform.init(scaleX: 1.2, y: 1.2)
        lblTitle.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.vContent.alpha = 1
            self.vContent.transform = CGAffineTransform.identity
            self.lblTitle.alpha = 1
            self.lblTitle.transform = CGAffineTransform.identity
        }
    }
    
    fileprivate func animateOut(completion: (() -> Void)? = nil)  {
        UIView.animate(withDuration: 0.25, animations: {
            self.vContent.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.vContent.alpha = 0
            self.lblTitle.transform = CGAffineTransform.init(scaleX: 1.2, y: 1.2)
            self.lblTitle.alpha = 0
            
        }) { (true) in
            self.dismiss(animated: true, completion: completion)
        }
    }
}

extension SourceListVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StreamSource.allCases.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = StreamSource(rawValue: indexPath.row) else { return UITableViewCell() }
        let cell: SourceCell = tableView.dequeueReusableCell(withIdentifier: SourceCell.identifierCell, for: indexPath) as! SourceCell
        
        cell.lblTitle.text = item.title
        cell.lblSubtitle.text = "Coming Soon"
        cell.lblSubtitle.isHidden = item.is_available
        cell.imgIcon.image = item.image
        cell.imgCheck.isHidden = Cache.shared.stream_source != item
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = StreamSource(rawValue: indexPath.row) else { return }
        if !item.is_available { return }
        Cache.shared.stream_source = item
        tableView.reloadData()
        
        self.callback?()
        self.animateOut()
    }
}
