//
//  SettingVC.swift
//  stream_recorder
//
//  Created by HHumorous on 03/04/2022.
//

import UIKit

class SettingVC: UIViewController {
    
    enum SettingRow: Int, CaseIterable {
        case premium = 0
        case storage
        case help
    }
    
    @IBOutlet weak var tbvContent: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
    }
    
    func setupTableView() {
        tbvContent.delegate = self
        tbvContent.dataSource = self
        tbvContent.register(UINib(nibName: SettingItemCell.identifierCell, bundle: nil), forCellReuseIdentifier: SettingItemCell.identifierCell)
        tbvContent.register(UINib(nibName: SettingPremiumCell.identifierCell, bundle: nil), forCellReuseIdentifier: SettingPremiumCell.identifierCell)
        tbvContent.register(UINib(nibName: SettingStorageCell.identifierCell, bundle: nil), forCellReuseIdentifier: SettingStorageCell.identifierCell)
        tbvContent.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
    }

}

extension SettingVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingRow.allCases.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = SettingRow(rawValue: indexPath.row) else { return UITableViewCell() }
        
        switch row {
        case .premium:
            let cell: SettingPremiumCell = tableView.dequeueReusableCell(withIdentifier: SettingPremiumCell.identifierCell, for: indexPath) as! SettingPremiumCell
            
            return cell
        case .storage:
            let cell: SettingStorageCell = tableView.dequeueReusableCell(withIdentifier: SettingStorageCell.identifierCell, for: indexPath) as! SettingStorageCell
            
            return cell
        case .help:
            let cell: SettingItemCell = tableView.dequeueReusableCell(withIdentifier: SettingItemCell.identifierCell, for: indexPath) as! SettingItemCell
            
            cell.lblTitle.text = "Help & Support"
            cell.imgIcon.image = UIImage(named: "icSettingHelp")
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = SettingRow(rawValue: indexPath.row) else { return }
        switch row {
        case .premium:
            let vc: InappPremiumVC = .load(SB: .More)
            vc.pageMode = 2
            present(vc, animated: true, completion: nil)
        case .storage:
            break
        case .help:
            let vc: HelpVC = .load(SB: .More)
            present(vc, animated: true, completion: nil)
        }
    }
}
