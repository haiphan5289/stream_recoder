//
//  RecordConfigVC.swift
//  stream_recorder
//
//  Created by HHumorous on 05/04/2022.
//

import UIKit

class RecordConfigVC: UIViewController {
    
    enum ConfigRow: Int, CaseIterable {
        case resolution = 0
        case frame_rate
        case bit_rate
        
        var title: String {
            switch self {
            case .resolution:
                return "Resolution"
            case .frame_rate:
                return "Frame Rate"
            case .bit_rate:
                return "Bit Rate"
            }
        }
        
        var data: String {
            switch self {
            case .resolution:
                return Cache.shared.video_resolution.title
            case .frame_rate:
                return Cache.shared.video_framerate.title
            case .bit_rate:
                return Cache.shared.video_bitrate ?? ""
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
    
    func setupTableView() {
        tbvContent.delegate = self
        tbvContent.dataSource = self
        tbvContent.register(UINib(nibName: RecordConfigCell.identifierCell, bundle: nil), forCellReuseIdentifier: RecordConfigCell.identifierCell)
    }
    
    @IBAction func onPressDone(_ sender: UIButton) {
        animateOut()
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

extension RecordConfigVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ConfigRow.allCases.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = ConfigRow(rawValue: indexPath.row) else { return UITableViewCell() }
        let cell: RecordConfigCell = tableView.dequeueReusableCell(withIdentifier: RecordConfigCell.identifierCell, for: indexPath) as! RecordConfigCell
        
        cell.lblTitle.text = item.title
        cell.lblSubtitle.text = item.data
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = ConfigRow(rawValue: indexPath.row) else { return }
        
        if self.view.subviews.contains(where: {$0.isKind(of: OptionsView.self)}) {
            UIView().removeVideoOptionView(from: self.view)
        } else {
            if let cell = tableView.cellForRow(at: indexPath) as? RecordConfigCell {
                switch item {
                case .resolution:
                    cell.showVideoOption(mode: .resolution, direction: .up, inView: self.view) {
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                case .frame_rate:
                    cell.showVideoOption(mode: .frame, direction: .up, inView: self.view) {
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                case .bit_rate:
                    cell.showVideoOption(mode: .frame, direction: .up, inView: self.view) {
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        }
    }
}
