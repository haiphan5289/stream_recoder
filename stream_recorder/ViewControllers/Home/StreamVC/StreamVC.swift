//
//  StreamVC.swift
//  stream_recorder
//
//  Created by HHumorous on 05/04/2022.
//

import UIKit
import ReplayKit

class StreamVC: UIViewController {
    
    enum StreamRow: Int, CaseIterable {
        case platform = 0
        case screen
    }
    
    enum StreamState: Int {
        case ready
        case streaming
        case stop
        
        var color: UIColor? {
            switch self {
            case .ready:
                return UIColor(hex: "a190d4")
            case .streaming, .stop:
                return UIColor(hex: "f3f5f6")
            }
        }
        
        var titleButton: String {
            switch self {
            case .ready:
                return "Start Streaming"
            case .streaming, .stop:
                return "End Stream"
            }
        }
        
        var colorButton: UIColor? {
            switch self {
            case .ready:
                return .white
            case .streaming, .stop:
                return .black
            }
        }
        
        var titleStatus: String {
            switch self {
            case .ready:
                return "Press To Start Streaming"
            case .streaming, .stop:
                return "Streaming"
            }
        }
        
        var iconRecordShow: Bool {
            switch self {
            case .ready:
                return false
            case .streaming, .stop:
                return true
            }
        }
    }

    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var vStream: UIView!
    @IBOutlet weak var tbvContent: UITableView!
    @IBOutlet weak var vDisplay: UIView!
    @IBOutlet weak var btnStream: UIButton!
    @IBOutlet weak var imgRecord: UIImageView!
    @IBOutlet weak var lblRecordTime: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var vConfig: UIView!
    
    lazy var broadcastView: RPSystemBroadcastPickerView = {
        let view = RPSystemBroadcastPickerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.preferredExtension = "beelab.stream.xrecorder.broadcase-stream-recorder"
        view.backgroundColor = .clear
        
        if let button = view.subviews.first as? UIButton {
            button.fillSuperview()
            button.setImage(nil, for: .normal)
            button.setImage(nil, for: .selected)
        }
        
        return view
    }()
    
    var stateStreaming: StreamState = .ready
    
    var timer: CountdownService?
    
    var observer: NSKeyValueObservation?
    let userDefault = UserDefaults(suiteName: "group.beelab.stream.xrecorder.broadcast")
    
    deinit {
        observer?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
        updateUI()
        setupTableView()
        setupGesture()
        
        observer = userDefault?.observe(\.broadcastState, options: [.initial, .new], changeHandler: { defaults, change in
            if let newValue = change.newValue {
                if newValue == 1 {
                    self.startStreamSetup()
                } else {
                    self.endStreamSetup()
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupBroadcast()
    }
    
    func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tbvContent.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: tbvContent)
        if let indexPath = tbvContent.indexPathForRow(at: location) {
            tableView(tbvContent, didSelectRowAt: indexPath)
        } else {
            view.endEditing(true)
        }
    }
    
    func setupUI() {
        vStream.layer.cornerRadius = 30
        vStream.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        vContent.layer.cornerRadius = 30
        vContent.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    func updateUI() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.layoutSubviews]) {
            self.btnStream.setTitleColor(self.stateStreaming.colorButton, for: .normal)
            self.btnStream.setTitle(self.stateStreaming.titleButton, for: .normal)
            self.btnStream.backgroundColor = self.stateStreaming.color
            self.imgRecord.isHidden = !self.stateStreaming.iconRecordShow
            self.lblStatus.text = self.stateStreaming.titleStatus
            self.vConfig.isHidden = self.stateStreaming != .ready
            self.vDisplay.isHidden = self.stateStreaming == .ready
            self.tbvContent.isHidden = self.stateStreaming != .ready
        }
    }
    
    func setupTableView() {
        tbvContent.delegate = self
        tbvContent.dataSource = self
        tbvContent.register(UINib(nibName: StreamPlatformCell.identifierCell, bundle: nil), forCellReuseIdentifier: StreamPlatformCell.identifierCell)
        tbvContent.register(UINib(nibName: StreamScreenCell.identifierCell, bundle: nil), forCellReuseIdentifier: StreamScreenCell.identifierCell)
        tbvContent.keyboardDismissMode = .onDrag
    }
    
    func setupBroadcast() {
        if !Cache.shared.is_premium && RemoteConfigManager.sharedInstance.boolValue(forKey: .lockStreamScreen) {
            return
        }
        
        if Cache.shared.stream_source == .screen {
            if !view.subviews.contains(where: {$0 is RPSystemBroadcastPickerView}) {
                view.addSubview(broadcastView)
                NSLayoutConstraint.activate([
                    broadcastView.leadingAnchor.constraint(equalTo: btnStream.leadingAnchor),
                    broadcastView.topAnchor.constraint(equalTo: btnStream.topAnchor),
                    broadcastView.trailingAnchor.constraint(equalTo: btnStream.trailingAnchor),
                    broadcastView.bottomAnchor.constraint(equalTo: btnStream.bottomAnchor)
                ])
            }
        } else {
            broadcastView.removeFromSuperview()
        }
    }

    @IBAction func onPressClose(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func onPressHow(_ sender: UIButton) {
        self.openUrlWithSafari(url: "https://sites.google.com/view/xrecorderapp/how-to-use")
    }
    
    @IBAction func onPressConfig(_ sender: UIButton) {
        let vc: StreamConfigVC = .load(SB: .Home)
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func onPressRecord(_ sender: UIButton) {
        
        if Cache.shared.is_premium == false && RemoteConfigManager.sharedInstance.boolValue(forKey: .lockStreamCamera) {
            let vc: InappPremiumVC = .load(SB: .More)
            vc.pageMode = 2
            present(vc, animated: true, completion: nil)
            return
        }
        
        switch Cache.shared.stream_source {
        case .screen:
            if stateStreaming == .streaming {
                if let button = broadcastView.subviews.first as? UIButton {
                    button.sendActions(for: .touchUpInside)
                }
            }
        case .camera:
            let vc: StreamCameraVC = .load(SB: .Home)
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        default:
            break
        }
    }
    
    func startStreamSetup() {
        if self.stateStreaming == .ready {
            if self.timer == nil {
                self.timer = CountdownService()
                self.timer?.start(beginingValue: 0, interval: 1, countDown: false)
                self.timer?.delegate = self
            }
            self.stateStreaming = .streaming
            broadcastView.isHidden = true
            
            updateUI()
        }
    }
    
    func endStreamSetup() {
        if stateStreaming != .ready {
            if timer != nil {
                timer?.pause()
            }
            broadcastView.isHidden = false
            updateUI()
        }
    }
}

extension StreamVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StreamRow.allCases.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = StreamRow(rawValue: indexPath.row) else { return UITableViewCell() }
        
        switch row {
        case .platform:
            let cell: StreamPlatformCell = tableView.dequeueReusableCell(withIdentifier: StreamPlatformCell.identifierCell, for: indexPath) as! StreamPlatformCell
            
            let platform = Cache.shared.stream_platform
            cell.lblTitle.text = String(format: "Stream to %@", platform.title)
            cell.imgIcon.image = platform.image
            cell.tfKey.text = Cache.shared.stream_key
            cell.tfUrl.text = Cache.shared.stream_url
            cell.delegate = self
            
            return cell
        case .screen:
            let cell: StreamScreenCell = tableView.dequeueReusableCell(withIdentifier: StreamScreenCell.identifierCell, for: indexPath) as! StreamScreenCell
            let source = Cache.shared.stream_source
            cell.lblTitle.text = source.title
            cell.imgIcon.image = source.image
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = StreamRow(rawValue: indexPath.row) else { return }
        
        if row == .screen {
            let vc: SourceListVC = .load(SB: .Home)
            vc.callback = {
                self.tbvContent.reloadData()
                self.setupBroadcast()
            }
            present(vc, animated: true, completion: nil)
        }
    }
}

extension StreamVC: StreamPlatformCellDelegate {
    func onPressSelectPlatform(cell: StreamPlatformCell, sender: UIButton) {
        let vc: PlatformListVC = .load(SB: .Home)
        vc.callback = {
            self.tbvContent.reloadData()
        }
        present(vc, animated: true, completion: nil)
    }
}

extension StreamVC: CountdownServiceDelegate {
    func timerDidUpdateCounterValue(newValueString: String) {
        lblRecordTime.text = newValueString
    }
    
    func timerDidPause() {
        if self.timer != nil {
            self.timer?.end()
            self.stateStreaming = .ready
            self.updateUI()
        }
    }
    
    func timerDidEnd() {
        timer = nil
        
    }
    
    func timerDidStart() {
        //
    }
}
